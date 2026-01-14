import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import '../../../app_env.dart';
import '../../../core/config/onedrive_config.dart';
import '../../../translations/locale_keys.g.dart';

class InspectorOneDriveService {
  static final InspectorOneDriveService _instance =
      InspectorOneDriveService._internal();
  factory InspectorOneDriveService() => _instance;
  InspectorOneDriveService._internal();

  String? _accessToken;
  DateTime? _tokenExpiry;

  // Get app-only access token with expiry tracking

  // ✅ ADD THIS: Get root folder based on environment
  String get _rootFolder {
    return AppEnvironment.isProd
        ? 'RestaurantInspections' // Production folder
        : 'RestaurantInspections_DEV'; // Development folder
  }

  Future<void> _getAppAccessToken() async {
    console("Getting token");
    final url = Uri.parse(
      'https://login.microsoftonline.com/${OneDriveConfig.tenantId}/oauth2/v2.0/token',
    );
    final body = {
      'client_id': OneDriveConfig.clientId,
      'scope': 'https://graph.microsoft.com/.default',
      'client_secret': OneDriveConfig.clientSecretValue,
      'grant_type': 'client_credentials',
    };
    console(body);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];

        final expiresIn = data['expires_in'] as int? ?? 3600;
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: expiresIn - 300),
        ); // Refresh 5 min early

        print('✅ Access token obtained, expires at: $_tokenExpiry');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          '${LocaleKeys.failedToGetAccessToken.tr()}: ${error['error_description'] ?? response.body}',
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

  String _driveRoot() {
    return 'users/${OneDriveConfig.myUserId}/drive/root';
  }

  // Helper to get month folder name
  String _getMonthFolder(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  // Create folder structure: RestaurantInspections/{branchName}/{month}/Images
  // Future<String> createImagesFolder(
  //   String branchName,
  //   DateTime timestamp,
  // ) async {
  //   await _ensureToken();

  //   try {
  //     final monthFolder = _getMonthFolder(timestamp);

  //     await _createFolderIfNotExists('RestaurantInspections');
  //     await _createFolderIfNotExists('RestaurantInspections/$branchName');
  //     await _createFolderIfNotExists(
  //       'RestaurantInspections/$branchName/$monthFolder',
  //     );
  //     final folderPath =
  //         'RestaurantInspections/$branchName/$monthFolder/Images';
  //     await _createFolderIfNotExists(folderPath);

  //     print('✅ Images folder structure created: $folderPath');
  //     return folderPath;
  //   } catch (e) {
  //     print('❌ Error creating images folder structure: $e');
  //     rethrow;
  //   }
  // }
  Future<String> createImagesFolder(
    String branchName,
    DateTime timestamp,
  ) async {
    await _ensureToken();

    try {
      final monthFolder = _getMonthFolder(timestamp); 

      final dateFolder =
          '${timestamp.day.toString().padLeft(2, '0')}-'
          '${timestamp.month.toString().padLeft(2, '0')}-'
          '${timestamp.year}';

      await _createFolderIfNotExists(_rootFolder);
      await _createFolderIfNotExists('$_rootFolder/$branchName');
      await _createFolderIfNotExists('$_rootFolder/$branchName/$monthFolder');

      final imagesRoot = '$_rootFolder/$branchName/$monthFolder/Images';
      await _createFolderIfNotExists(imagesRoot);

      final finalPath = '$imagesRoot/$dateFolder';
      await _createFolderIfNotExists(finalPath);

      print('✅ Images date folder created: $finalPath');
      return finalPath;
    } catch (e) {
      print('❌ Error creating Images/date folder: $e');
      rethrow;
    }
  }

  // Create folder structure: RestaurantInspections/{branchName}/{month}/PDFs
  // Future<String> createPDFFolder(String branchName, DateTime timestamp) async {
  //   await _ensureToken();

  //   try {
  //     final monthFolder = _getMonthFolder(timestamp);

  //     await _createFolderIfNotExists('RestaurantInspections');
  //     await _createFolderIfNotExists('RestaurantInspections/$branchName');
  //     await _createFolderIfNotExists(
  //       'RestaurantInspections/$branchName/$monthFolder',
  //     );
  //     final folderPath = 'RestaurantInspections/$branchName/$monthFolder/PDFs';
  //     await _createFolderIfNotExists(folderPath);

  //     print('✅ PDF folder structure created: $folderPath');
  //     return folderPath;
  //   } catch (e) {
  //     print('❌ Error creating PDF folder structure: $e');
  //     rethrow;
  //   }
  // }

  Future<String> createPDFFolder(String branchName, DateTime timestamp) async {
    await _ensureToken();

    try {
      final monthFolder = _getMonthFolder(timestamp);

      await _createFolderIfNotExists(_rootFolder); // ← Changed
      await _createFolderIfNotExists('$_rootFolder/$branchName'); // ← Changed
      await _createFolderIfNotExists(
        '$_rootFolder/$branchName/$monthFolder', // ← Changed
      );
      final folderPath =
          '$_rootFolder/$branchName/$monthFolder/PDFs'; // ← Changed
      await _createFolderIfNotExists(folderPath);

      print('✅ PDF folder structure created: $folderPath');
      return folderPath;
    } catch (e) {
      print('❌ Error creating PDF folder structure: $e');
      rethrow;
    }
  }

  Future<void> _createFolderIfNotExists(String folderPath) async {
    await _ensureToken();

    final checkUrl = Uri.parse(
      '${OneDriveConfig.graphApiBaseUrl}/${_driveRoot()}:/$folderPath',
    );

    final checkResponse = await http.get(
      checkUrl,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (checkResponse.statusCode == 200) {
      print('ℹ️ Folder already exists: $folderPath');
      return;
    }

    if (checkResponse.statusCode == 404) {
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
          '@microsoft.graph.conflictBehavior': 'replace',
        }),
      );

      if (createResponse.statusCode == 201 ||
          createResponse.statusCode == 200) {
        print('✅ Folder created: $folderPath');
      } else {
        final error = jsonDecode(createResponse.body);
        final errorMessage = error['error']?['message'] ?? createResponse.body;

        // If error is "name already exists", it means folder was created by another request, ignore it
        if (errorMessage.toString().toLowerCase().contains(
          'name already exists',
        )) {
          print('ℹ️ Folder already exists (created concurrently): $folderPath');
          return;
        }

        throw Exception(
          '${LocaleKeys.failedToCreateFolder.tr()} "$folderPath": $errorMessage',
        );
      }
    } else {
      final error = jsonDecode(checkResponse.body);
      throw Exception(
        '${LocaleKeys.errorCheckingFolder.tr()} "$folderPath": ${error['error']?['message'] ?? checkResponse.body}',
      );
    }
  }

  // Upload file - no return value needed
  Future<void> _uploadFile({
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
      await _simpleUpload(file, remotePath, fileName);
    } else {
      await _resumableUpload(file, remotePath, fileName, onProgress);
    }
  }

  Future<void> _simpleUpload(
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
      print('✅ Upload successful: $fileName');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        '${LocaleKeys.uploadFailed.tr()} "$fileName": ${error['error']?['message'] ?? response.body}',
      );
    }
  }

  Future<void> _resumableUpload(
    File file,
    String remotePath,
    String fileName,
    Function(double)? onProgress,
  ) async {
    final fileSize = await file.length();
    final fullPath = '$remotePath/$fileName';

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
        '${LocaleKeys.failedToCreateUploadSession.tr()}: ${error['error']?['message'] ?? sessionResponse.body}',
      );
    }

    final sessionData = jsonDecode(sessionResponse.body);
    final uploadUrl = sessionData['uploadUrl'];

    final chunkSize = 320 * 1024 * 10; // 3.2 MB chunks
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

      if (uploadResponse.statusCode == 200 ||
          uploadResponse.statusCode == 201) {
        print('✅ Resumable upload complete: $fileName');
        return;
      } else if (uploadResponse.statusCode != 202) {
        final error = jsonDecode(uploadResponse.body);
        throw Exception(
          '${LocaleKeys.uploadChunkFailed.tr()}: ${error['error']?['message'] ?? uploadResponse.body}',
        );
      }
    }

    throw Exception(LocaleKeys.uploadFailedUnexpectedly.tr());
  }

  // Upload PDF Report - no return value
  Future<void> uploadPDFReport({
    required File pdfFile,
    required String branchName,
    required String inspectionId,
    required DateTime timestamp,
    Function(double)? onProgress,
  }) async {
    final folderPath = await createPDFFolder(branchName, timestamp);
    await _uploadFile(
      file: pdfFile,
      remotePath: folderPath,
      onProgress: onProgress,
    );
  }

  // Upload multiple images - all in one Images folder
  Future<void> uploadImages({
    required List<File> images,
    required String branchName,
    required String inspectionId,
    required DateTime timestamp,
    Function(int current, int total)? onProgress,
  }) async {
    final folderPath = await createImagesFolder(branchName, timestamp);

    for (int i = 0; i < images.length; i++) {
      try {
        await _uploadFile(file: images[i], remotePath: folderPath);

        if (onProgress != null) {
          onProgress(i + 1, images.length);
        }
      } catch (e) {
        print('❌ Failed to upload image ${i + 1}: $e');
        rethrow;
      }
    }
  }

  // Test connection method
  Future<bool> testConnection() async {
    try {
      await _ensureToken();

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
        print(
          '🔥 Environment: ${AppEnvironment.current.toUpperCase()}',
        ); // ← Add this
        print('📁 Root folder: $_rootFolder'); // ← Add this
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
