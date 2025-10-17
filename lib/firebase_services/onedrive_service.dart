import 'dart:convert';
import 'dart:io';

import 'package:haus_des_control/core/console.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import '../core/config/onedrive_config.dart';

class OneDriveService {
  static final OneDriveService _instance = OneDriveService._internal();
  factory OneDriveService() => _instance;
  OneDriveService._internal();

  String? _accessToken;
  DateTime? _tokenExpiry;

  // Get app-only access token with expiry tracking
  Future<void> _getAppAccessToken() async {
    console("Getting token");
    final url = Uri.parse(
      'https://login.microsoftonline.com/${OneDriveConfig.tenantId}/oauth2/v2.0/token',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': OneDriveConfig.clientId,
          'scope': 'https://graph.microsoft.com/.default',
          'client_secret': OneDriveConfig.clientSecretValue,
          'grant_type': 'client_credentials',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];

        // Token typically expires in 3600 seconds (1 hour)
        final expiresIn = data['expires_in'] as int? ?? 3600;
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: expiresIn - 300),
        ); // Refresh 5 min early

        print('✅ Access token obtained, expires at: $_tokenExpiry');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          'Failed to get access token: ${error['error_description'] ?? response.body}',
        );
      }
    } catch (e) {
      print('❌ Token request failed: $e');
      rethrow;
    }
  }

  // Check if token is valid and refresh if needed
  Future<void> _ensureToken() async {
    if (_accessToken == null ||
        _tokenExpiry == null ||
        DateTime.now().isAfter(_tokenExpiry!)) {
      print('🔄 Token expired or missing, fetching new token...');
      await _getAppAccessToken();
    }
  }

  // Use service account drive
  String _driveRoot() {
    // Format: users/{user-id-or-email}/drive/root
    // Example: users/inspection-service@contoso.com/drive/root
    return 'users/${OneDriveConfig.myUserId}/drive/root';
  }

  Future<String> createInspectionFolder(
    String branchId,
    String inspectionId,
  ) async {
    await _ensureToken();

    try {
      await _createFolderIfNotExists('RestaurantInspections');
      await _createFolderIfNotExists('RestaurantInspections/$branchId');
      final folderPath = 'RestaurantInspections/$branchId/$inspectionId';
      await _createFolderIfNotExists(folderPath);

      print('✅ Folder structure created: $folderPath');
      return folderPath;
    } catch (e) {
      print('❌ Error creating folder structure: $e');
      rethrow;
    }
  }

  Future<void> _createFolderIfNotExists(String folderPath) async {
    await _ensureToken();

    // Check if folder exists
    final checkUrl = Uri.parse(
      '${OneDriveConfig.graphApiBaseUrl}/${_driveRoot()}:/$folderPath',
    );

    final checkResponse = await http.get(
      checkUrl,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (checkResponse.statusCode == 200) {
      print('ℹ️ Folder already exists: $folderPath');
      return; // Folder exists
    }

    if (checkResponse.statusCode == 404) {
      // Folder doesn't exist, create it
      final parentPath = path.dirname(folderPath);
      final folderName = path.basename(folderPath);

      final createUrl = parentPath == '.'
          ? Uri.parse(
              '${OneDriveConfig.graphApiBaseUrl}/${_driveRoot()}/children',
            )
          : Uri.parse(
              '${OneDriveConfig.graphApiBaseUrl}/${_driveRoot()}:/$parentPath:/children',
            );

      final createResponse = await http.post(
        createUrl,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': folderName,
          'folder': {},
          '@microsoft.graph.conflictBehavior': 'rename',
        }),
      );

      if (createResponse.statusCode == 201 ||
          createResponse.statusCode == 200) {
        print('✅ Folder created: $folderPath');
      } else {
        final error = jsonDecode(createResponse.body);
        throw Exception(
          'Failed to create folder "$folderPath": ${error['error']?['message'] ?? createResponse.body}',
        );
      }
    } else {
      // Unexpected error
      final error = jsonDecode(checkResponse.body);
      throw Exception(
        'Error checking folder "$folderPath": ${error['error']?['message'] ?? checkResponse.body}',
      );
    }
  }

  // Upload file with automatic method selection
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String remotePath,
    Function(double)? onProgress,
  }) async {
    await _ensureToken();

    final fileSize = await file.length();
    final fileName = path.basename(file.path);

    print(
      '📤 Uploading: $fileName (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)',
    );

    if (fileSize < 4 * 1024 * 1024) {
      return await _simpleUpload(file, remotePath, fileName);
    } else {
      return await _resumableUpload(file, remotePath, fileName, onProgress);
    }
  }

  Future<Map<String, dynamic>> _simpleUpload(
    File file,
    String remotePath,
    String fileName,
  ) async {
    final bytes = await file.readAsBytes();
    final fullPath = '$remotePath/$fileName';

    final url = Uri.parse(
      '${OneDriveConfig.graphApiBaseUrl}/${_driveRoot()}:/$fullPath:/content',
    );

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': lookupMimeType(fileName) ?? 'application/octet-stream',
      },
      body: bytes,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('✅ Upload successful: $fileName');

      return {
        'id': data['id'],
        'name': data['name'],
        'webUrl': data['webUrl'],
        'downloadUrl': data['@microsoft.graph.downloadUrl'],
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        'Upload failed for "$fileName": ${error['error']?['message'] ?? response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> _resumableUpload(
    File file,
    String remotePath,
    String fileName,
    Function(double)? onProgress,
  ) async {
    final fileSize = await file.length();
    final fullPath = '$remotePath/$fileName';

    // Create upload session
    final sessionUrl = Uri.parse(
      '${OneDriveConfig.graphApiBaseUrl}/${_driveRoot()}:/$fullPath:/createUploadSession',
    );

    final sessionResponse = await http.post(
      sessionUrl,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'item': {'@microsoft.graph.conflictBehavior': 'rename'},
      }),
    );

    if (sessionResponse.statusCode != 200 &&
        sessionResponse.statusCode != 201) {
      final error = jsonDecode(sessionResponse.body);
      throw Exception(
        'Failed to create upload session: ${error['error']?['message'] ?? sessionResponse.body}',
      );
    }

    final sessionData = jsonDecode(sessionResponse.body);
    final uploadUrl = sessionData['uploadUrl'];

    // Upload in chunks
    final chunkSize =
        320 * 1024 * 10; // 3.2 MB chunks (must be multiple of 320 KB)
    final fileBytes = await file.readAsBytes();
    int uploadedBytes = 0;

    while (uploadedBytes < fileSize) {
      final start = uploadedBytes;
      final end = (uploadedBytes + chunkSize < fileSize)
          ? uploadedBytes + chunkSize
          : fileSize;

      final chunk = fileBytes.sublist(start, end);

      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Length': chunk.length.toString(),
          'Content-Range': 'bytes $start-${end - 1}/$fileSize',
        },
        body: chunk,
      );

      uploadedBytes = end;

      if (onProgress != null) {
        onProgress(uploadedBytes / fileSize);
      }

      print(
        '📊 Upload progress: ${(uploadedBytes / fileSize * 100).toStringAsFixed(1)}%',
      );

      // Upload completed
      if (uploadResponse.statusCode == 200 ||
          uploadResponse.statusCode == 201) {
        final data = jsonDecode(uploadResponse.body);
        print('✅ Resumable upload complete: $fileName');

        return {
          'id': data['id'],
          'name': data['name'],
          'webUrl': data['webUrl'],
          'downloadUrl': data['@microsoft.graph.downloadUrl'],
        };
      } else if (uploadResponse.statusCode != 202) {
        // 202 = Continue, anything else is an error
        final error = jsonDecode(uploadResponse.body);
        throw Exception(
          'Upload chunk failed: ${error['error']?['message'] ?? uploadResponse.body}',
        );
      }
    }

    throw Exception('Upload failed unexpectedly');
  }

  // Upload PDF Report
  Future<Map<String, dynamic>> uploadPDFReport({
    required File pdfFile,
    required String branchId,
    required String inspectionId,
    Function(double)? onProgress,
  }) async {
    final folderPath = await createInspectionFolder(branchId, inspectionId);
    return await uploadFile(
      file: pdfFile,
      remotePath: folderPath,
      onProgress: onProgress,
    );
  }

  // Upload multiple images
  Future<List<Map<String, dynamic>>> uploadImages({
    required List<File> images,
    required String branchId,
    required String inspectionId,
    required String categoryId,
    Function(int current, int total)? onProgress,
  }) async {
    final folderPath = await createInspectionFolder(branchId, inspectionId);
    final categoryFolder = '$folderPath/$categoryId';
    await _createFolderIfNotExists(categoryFolder);

    final List<Map<String, dynamic>> uploadedFiles = [];

    for (int i = 0; i < images.length; i++) {
      try {
        final result = await uploadFile(
          file: images[i],
          remotePath: categoryFolder,
        );
        uploadedFiles.add(result);

        if (onProgress != null) {
          onProgress(i + 1, images.length);
        }
      } catch (e) {
        print('❌ Failed to upload image ${i + 1}: $e');
        // Continue with other images or rethrow based on your needs
        rethrow;
      }
    }

    return uploadedFiles;
  }

  // Test connection method (useful for debugging)
  Future<bool> testConnection() async {
    try {
      await _ensureToken();

      // Try to access the drive root
      final url = Uri.parse(
        '${OneDriveConfig.graphApiBaseUrl}/${_driveRoot()}',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ OneDrive connection successful');
        print('Drive owner: ${data['owner']?['user']?['displayName']}');
        return true;
      } else {
        print('❌ Connection test failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Connection test error: $e');
      return false;
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////

// class OneDriveService {
//   static final OneDriveService _instance = OneDriveService._internal();
//   factory OneDriveService() => _instance;
//   OneDriveService._internal();

//   String? _accessToken;

//   // Get app-only access token
//   Future<void> _getAppAccessToken() async {
//     final url = Uri.parse(
//       'https://login.microsoftonline.com/${OneDriveConfig.tenantId}/oauth2/v2.0/token',
//     );

//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//       body: {
//         'client_id': OneDriveConfig.clientId,
//         'scope': 'https://graph.microsoft.com/.default',
//         'client_secret': OneDriveConfig.clientSecretValue,
//         'grant_type': 'client_credentials',
//       },
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       _accessToken = data['access_token'];
//     } else {
//       throw Exception('Failed to get access token: ${response.body}');
//     }
//   }

//   Future<void> _ensureToken() async {
//     if (_accessToken == null) {
//       await _getAppAccessToken();
//     }
//   }

//   // Create folder structure for inspection
//   Future<String> createInspectionFolder(
//     String branchId,
//     String inspectionId,
//   ) async {
//     await _ensureToken();
//     try {
//       await _createFolderIfNotExists('RestaurantInspections');
//       await _createFolderIfNotExists('RestaurantInspections/$branchId');
//       final folderPath = 'RestaurantInspections/$branchId/$inspectionId';
//       await _createFolderIfNotExists(folderPath);
//       return folderPath;
//     } catch (e) {
//       print('Error creating folder structure: $e');
//       rethrow;
//     }
//   }

//   Future<void> _createFolderIfNotExists(String folderPath) async {
//     final url = Uri.parse(
//       '${OneDriveConfig.graphApiBaseUrl}/me/drive/root:/$folderPath',
//     );
//     final response = await http.get(
//       url,
//       headers: {'Authorization': 'Bearer $_accessToken'},
//     );

//     if (response.statusCode == 404) {
//       final parentPath = path.dirname(folderPath);
//       final folderName = path.basename(folderPath);

//       final createUrl = parentPath == '.'
//           ? Uri.parse(
//               '${OneDriveConfig.graphApiBaseUrl}/me/drive/root/children',
//             )
//           : Uri.parse(
//               '${OneDriveConfig.graphApiBaseUrl}/me/drive/root:/$parentPath:/children',
//             );

//       await http.post(
//         createUrl,
//         headers: {
//           'Authorization': 'Bearer $_accessToken',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'name': folderName,
//           'folder': {},
//           '@microsoft.graph.conflictBehavior': 'rename',
//         }),
//       );
//     }
//   }

//   // Upload file (handles small & large)
//   Future<Map<String, dynamic>> uploadFile({
//     required File file,
//     required String remotePath,
//     Function(double)? onProgress,
//   }) async {
//     await _ensureToken();
//     final fileSize = await file.length();
//     final fileName = path.basename(file.path);

//     if (fileSize < 4 * 1024 * 1024) {
//       return await _simpleUpload(file, remotePath, fileName);
//     } else {
//       return await _resumableUpload(file, remotePath, fileName, onProgress);
//     }
//   }

//   Future<Map<String, dynamic>> _simpleUpload(
//     File file,
//     String remotePath,
//     String fileName,
//   ) async {
//     final bytes = await file.readAsBytes();
//     final fullPath = '$remotePath/$fileName';

//     final url = Uri.parse(
//       '${OneDriveConfig.graphApiBaseUrl}/me/drive/root:/$fullPath:/content',
//     );

//     final response = await http.put(
//       url,
//       headers: {
//         'Authorization': 'Bearer $_accessToken',
//         'Content-Type': lookupMimeType(fileName) ?? 'application/octet-stream',
//       },
//       body: bytes,
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       final data = jsonDecode(response.body);
//       return {
//         'id': data['id'],
//         'name': data['name'],
//         'webUrl': data['webUrl'],
//         'downloadUrl': data['@microsoft.graph.downloadUrl'],
//       };
//     } else {
//       throw Exception('Upload failed: ${response.body}');
//     }
//   }

//   Future<Map<String, dynamic>> _resumableUpload(
//     File file,
//     String remotePath,
//     String fileName,
//     Function(double)? onProgress,
//   ) async {
//     final fileSize = await file.length();
//     final fullPath = '$remotePath/$fileName';

//     final sessionUrl = Uri.parse(
//       '${OneDriveConfig.graphApiBaseUrl}/me/drive/root:/$fullPath:/createUploadSession',
//     );
//     final sessionResponse = await http.post(
//       sessionUrl,
//       headers: {
//         'Authorization': 'Bearer $_accessToken',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({
//         'item': {'@microsoft.graph.conflictBehavior': 'rename'},
//       }),
//     );

//     if (sessionResponse.statusCode != 200) {
//       throw Exception(
//         'Failed to create upload session: ${sessionResponse.body}',
//       );
//     }

//     final sessionData = jsonDecode(sessionResponse.body);
//     final uploadUrl = sessionData['uploadUrl'];
//     final fileStream = file.openRead();
//     int uploadedBytes = 0;

//     await for (var chunk in fileStream) {
//       final chunkLength = chunk.length;
//       final endByte = uploadedBytes + chunkLength - 1;

//       final uploadResponse = await http.put(
//         Uri.parse(uploadUrl),
//         headers: {
//           'Content-Length': chunkLength.toString(),
//           'Content-Range': 'bytes $uploadedBytes-$endByte/$fileSize',
//         },
//         body: chunk,
//       );

//       uploadedBytes += chunkLength;
//       if (onProgress != null) onProgress(uploadedBytes / fileSize);

//       if (uploadResponse.statusCode == 200 ||
//           uploadResponse.statusCode == 201) {
//         final data = jsonDecode(uploadResponse.body);
//         return {
//           'id': data['id'],
//           'name': data['name'],
//           'webUrl': data['webUrl'],
//           'downloadUrl': data['@microsoft.graph.downloadUrl'],
//         };
//       }
//     }

//     throw Exception('Upload failed');
//   }

//   // 🔹 Upload PDF Report
//   Future<Map<String, dynamic>> uploadPDFReport({
//     required File pdfFile,
//     required String branchId,
//     required String inspectionId,
//     Function(double)? onProgress,
//   }) async {
//     final folderPath = await createInspectionFolder(branchId, inspectionId);
//     return await uploadFile(
//       file: pdfFile,
//       remotePath: folderPath,
//       onProgress: onProgress,
//     );
//   }

//   // 🔹 Upload multiple images
//   Future<List<Map<String, dynamic>>> uploadImages({
//     required List<File> images,
//     required String branchId,
//     required String inspectionId,
//     required String categoryId,
//     Function(int current, int total)? onProgress,
//   }) async {
//     final folderPath = await createInspectionFolder(branchId, inspectionId);
//     final categoryFolder = '$folderPath/$categoryId';
//     await _createFolderIfNotExists(categoryFolder);

//     final List<Map<String, dynamic>> uploadedFiles = [];

//     for (int i = 0; i < images.length; i++) {
//       final result = await uploadFile(
//         file: images[i],
//         remotePath: categoryFolder,
//       );
//       uploadedFiles.add(result);

//       if (onProgress != null) onProgress(i + 1, images.length);
//     }

//     return uploadedFiles;
//   }
// }

////////////////////////////////////////////////////////////////////////////////////////////////////////////

// class OneDriveService {
//   static final OneDriveService _instance = OneDriveService._internal();
//   factory OneDriveService() => _instance;
//   OneDriveService._internal();

//   AadOAuth? _oauth;
//   String? _accessToken;

//   // Initialize OAuth
//   Future<void> initialize() async {
//     final config = Config(
//       tenant: OneDriveConfig.tenantId,
//       clientId: OneDriveConfig.clientId,
//       scope: OneDriveConfig.scopes.join(' '),
//       redirectUri: OneDriveConfig.redirectUri,
//       navigatorKey: navigatorKey, // Pass your navigator key if needed
//     );

//     _oauth = AadOAuth(config);
//   }

//   // Login and get access token
//   Future<bool> login() async {
//     try {
//       if (_oauth == null) await initialize();

//       await _oauth!.login();
//       _accessToken = await _oauth!.getAccessToken();

//       return _accessToken != null;
//     } catch (e) {
//       print('OneDrive login error: $e');
//       return false;
//     }
//   }

//   // Logout
//   Future<void> logout() async {
//     try {
//       await _oauth?.logout();
//       _accessToken = null;
//     } catch (e) {
//       print('OneDrive logout error: $e');
//     }
//   }

//   // Check if logged in
//   bool get isLoggedIn => _accessToken != null;

//   // Refresh token if needed
//   Future<void> _ensureToken() async {
//     if (_accessToken == null || await _oauth!.getAccessToken() == null) {
//       await login();
//     } else {
//       _accessToken = await _oauth!.getAccessToken();
//     }
//   }

//   // Create folder structure: RestaurantInspections/{branchId}/{inspectionId}
//   Future<String> createInspectionFolder(
//     String branchId,
//     String inspectionId,
//   ) async {
//     await _ensureToken();

//     try {
//       // Create base folder if not exists
//       await _createFolderIfNotExists('RestaurantInspections');

//       // Create branch folder
//       await _createFolderIfNotExists('RestaurantInspections/$branchId');

//       // Create inspection folder
//       final folderPath = 'RestaurantInspections/$branchId/$inspectionId';
//       await _createFolderIfNotExists(folderPath);

//       return folderPath;
//     } catch (e) {
//       print('Error creating folder structure: $e');
//       rethrow;
//     }
//   }

//   // Helper to create folder if it doesn't exist
//   Future<void> _createFolderIfNotExists(String folderPath) async {
//     final url = Uri.parse(
//       '${OneDriveConfig.graphApiBaseUrl}/me/drive/root:/$folderPath',
//     );

//     final response = await http.get(
//       url,
//       headers: {'Authorization': 'Bearer $_accessToken'},
//     );

//     // If folder doesn't exist (404), create it
//     if (response.statusCode == 404) {
//       final parentPath = path.dirname(folderPath);
//       final folderName = path.basename(folderPath);

//       final createUrl = parentPath == '.'
//           ? Uri.parse(
//               '${OneDriveConfig.graphApiBaseUrl}/me/drive/root/children',
//             )
//           : Uri.parse(
//               '${OneDriveConfig.graphApiBaseUrl}/me/drive/root:/$parentPath:/children',
//             );

//       await http.post(
//         createUrl,
//         headers: {
//           'Authorization': 'Bearer $_accessToken',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'name': folderName,
//           'folder': {},
//           '@microsoft.graph.conflictBehavior': 'rename',
//         }),
//       );
//     }
//   }

//   // Upload file to OneDrive
//   Future<Map<String, dynamic>> uploadFile({
//     required File file,
//     required String remotePath,
//     Function(double)? onProgress,
//   }) async {
//     await _ensureToken();

//     try {
//       final fileSize = await file.length();
//       final fileName = path.basename(file.path);

//       // For small files (< 4MB), use simple upload
//       if (fileSize < 4 * 1024 * 1024) {
//         return await _simpleUpload(file, remotePath, fileName);
//       } else {
//         // For large files, use resumable upload
//         return await _resumableUpload(file, remotePath, fileName, onProgress);
//       }
//     } catch (e) {
//       print('Upload error: $e');
//       rethrow;
//     }
//   }

//   // Simple upload for small files
//   Future<Map<String, dynamic>> _simpleUpload(
//     File file,
//     String remotePath,
//     String fileName,
//   ) async {
//     final bytes = await file.readAsBytes();
//     final fullPath = '$remotePath/$fileName';

//     final url = Uri.parse(
//       '${OneDriveConfig.graphApiBaseUrl}/me/drive/root:/$fullPath:/content',
//     );

//     final response = await http.put(
//       url,
//       headers: {
//         'Authorization': 'Bearer $_accessToken',
//         'Content-Type': lookupMimeType(fileName) ?? 'application/octet-stream',
//       },
//       body: bytes,
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       final data = jsonDecode(response.body);
//       return {
//         'id': data['id'],
//         'name': data['name'],
//         'webUrl': data['webUrl'],
//         'downloadUrl': data['@microsoft.graph.downloadUrl'],
//         'size': data['size'],
//       };
//     } else {
//       throw Exception('Upload failed: ${response.body}');
//     }
//   }

//   // Resumable upload for large files
//   Future<Map<String, dynamic>> _resumableUpload(
//     File file,
//     String remotePath,
//     String fileName,
//     Function(double)? onProgress,
//   ) async {
//     final fileSize = await file.length();
//     final fullPath = '$remotePath/$fileName';

//     // Create upload session
//     final sessionUrl = Uri.parse(
//       '${OneDriveConfig.graphApiBaseUrl}/me/drive/root:/$fullPath:/createUploadSession',
//     );

//     final sessionResponse = await http.post(
//       sessionUrl,
//       headers: {
//         'Authorization': 'Bearer $_accessToken',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({
//         'item': {'@microsoft.graph.conflictBehavior': 'rename'},
//       }),
//     );

//     if (sessionResponse.statusCode != 200) {
//       throw Exception(
//         'Failed to create upload session: ${sessionResponse.body}',
//       );
//     }

//     final sessionData = jsonDecode(sessionResponse.body);
//     final uploadUrl = sessionData['uploadUrl'];

//     // Upload in chunks
//     // const chunkSize = 320 * 1024 * 10; // 3.2 MB chunks
//     final fileStream = file.openRead();
//     int uploadedBytes = 0;

//     await for (var chunk in fileStream) {
//       final chunkLength = chunk.length;
//       final endByte = uploadedBytes + chunkLength - 1;

//       final uploadResponse = await http.put(
//         Uri.parse(uploadUrl),
//         headers: {
//           'Content-Length': chunkLength.toString(),
//           'Content-Range': 'bytes $uploadedBytes-$endByte/$fileSize',
//         },
//         body: chunk,
//       );

//       uploadedBytes += chunkLength;

//       if (onProgress != null) {
//         onProgress(uploadedBytes / fileSize);
//       }

//       // If upload is complete
//       if (uploadResponse.statusCode == 200 ||
//           uploadResponse.statusCode == 201) {
//         final data = jsonDecode(uploadResponse.body);
//         return {
//           'id': data['id'],
//           'name': data['name'],
//           'webUrl': data['webUrl'],
//           'downloadUrl': data['@microsoft.graph.downloadUrl'],
//           'size': data['size'],
//         };
//       }
//     }

//     throw Exception('Upload failed');
//   }

//   // Upload PDF report
//   Future<Map<String, dynamic>> uploadPDFReport({
//     required File pdfFile,
//     required String branchId,
//     required String inspectionId,
//     Function(double)? onProgress,
//   }) async {
//     final folderPath = await createInspectionFolder(branchId, inspectionId);
//     return await uploadFile(
//       file: pdfFile,
//       remotePath: folderPath,
//       onProgress: onProgress,
//     );
//   }

//   // Upload multiple images
//   Future<List<Map<String, dynamic>>> uploadImages({
//     required List<File> images,
//     required String branchId,
//     required String inspectionId,
//     required String categoryId,
//     Function(int current, int total)? onProgress,
//   }) async {
//     final folderPath = await createInspectionFolder(branchId, inspectionId);
//     final categoryFolder = '$folderPath/$categoryId';
//     await _createFolderIfNotExists(categoryFolder);

//     final List<Map<String, dynamic>> uploadedFiles = [];

//     for (int i = 0; i < images.length; i++) {
//       final result = await uploadFile(
//         file: images[i],
//         remotePath: categoryFolder,
//       );
//       uploadedFiles.add(result);

//       if (onProgress != null) {
//         onProgress(i + 1, images.length);
//       }
//     }

//     return uploadedFiles;
//   }

//   // Get sharing link for a file
//   Future<String> getSharingLink(String itemId) async {
//     await _ensureToken();

//     final url = Uri.parse(
//       '${OneDriveConfig.graphApiBaseUrl}/me/drive/items/$itemId/createLink',
//     );

//     final response = await http.post(
//       url,
//       headers: {
//         'Authorization': 'Bearer $_accessToken',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({'type': 'view', 'scope': 'anonymous'}),
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       final data = jsonDecode(response.body);
//       return data['link']['webUrl'];
//     } else {
//       throw Exception('Failed to create sharing link: ${response.body}');
//     }
//   }
// }
