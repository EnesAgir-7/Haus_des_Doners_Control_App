import 'dart:convert';
import 'dart:io';

import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import '../core/config/onedrive_config.dart';
import '../main.dart';

class OneDriveService {
  static final OneDriveService _instance = OneDriveService._internal();
  factory OneDriveService() => _instance;
  OneDriveService._internal();

  AadOAuth? _oauth;
  String? _accessToken;

  // Initialize OAuth
  Future<void> initialize() async {
    final config = Config(
      tenant: OneDriveConfig.tenantId,
      clientId: OneDriveConfig.clientId,
      scope: OneDriveConfig.scopes.join(' '),
      redirectUri: OneDriveConfig.redirectUri,
      navigatorKey: navigatorKey, // Pass your navigator key if needed
    );

    _oauth = AadOAuth(config);
  }

  // Login and get access token
  Future<bool> login() async {
    try {
      if (_oauth == null) await initialize();

      await _oauth!.login();
      _accessToken = await _oauth!.getAccessToken();

      return _accessToken != null;
    } catch (e) {
      print('OneDrive login error: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _oauth?.logout();
      _accessToken = null;
    } catch (e) {
      print('OneDrive logout error: $e');
    }
  }

  // Check if logged in
  bool get isLoggedIn => _accessToken != null;

  // Refresh token if needed
  Future<void> _ensureToken() async {
    if (_accessToken == null || await _oauth!.getAccessToken() == null) {
      await login();
    } else {
      _accessToken = await _oauth!.getAccessToken();
    }
  }

  // Create folder structure: RestaurantInspections/{branchId}/{inspectionId}
  Future<String> createInspectionFolder(
    String branchId,
    String inspectionId,
  ) async {
    await _ensureToken();

    try {
      // Create base folder if not exists
      await _createFolderIfNotExists('RestaurantInspections');

      // Create branch folder
      await _createFolderIfNotExists('RestaurantInspections/$branchId');

      // Create inspection folder
      final folderPath = 'RestaurantInspections/$branchId/$inspectionId';
      await _createFolderIfNotExists(folderPath);

      return folderPath;
    } catch (e) {
      print('Error creating folder structure: $e');
      rethrow;
    }
  }

  // Helper to create folder if it doesn't exist
  Future<void> _createFolderIfNotExists(String folderPath) async {
    final url = Uri.parse(
      '${OneDriveConfig.graphApiBaseUrl}/me/drive/root:/$folderPath',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    // If folder doesn't exist (404), create it
    if (response.statusCode == 404) {
      final parentPath = path.dirname(folderPath);
      final folderName = path.basename(folderPath);

      final createUrl = parentPath == '.'
          ? Uri.parse(
              '${OneDriveConfig.graphApiBaseUrl}/me/drive/root/children',
            )
          : Uri.parse(
              '${OneDriveConfig.graphApiBaseUrl}/me/drive/root:/$parentPath:/children',
            );

      await http.post(
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
    }
  }

  // Upload file to OneDrive
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String remotePath,
    Function(double)? onProgress,
  }) async {
    await _ensureToken();

    try {
      final fileSize = await file.length();
      final fileName = path.basename(file.path);

      // For small files (< 4MB), use simple upload
      if (fileSize < 4 * 1024 * 1024) {
        return await _simpleUpload(file, remotePath, fileName);
      } else {
        // For large files, use resumable upload
        return await _resumableUpload(file, remotePath, fileName, onProgress);
      }
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  // Simple upload for small files
  Future<Map<String, dynamic>> _simpleUpload(
    File file,
    String remotePath,
    String fileName,
  ) async {
    final bytes = await file.readAsBytes();
    final fullPath = '$remotePath/$fileName';

    final url = Uri.parse(
      '${OneDriveConfig.graphApiBaseUrl}/me/drive/root:/$fullPath:/content',
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
      return {
        'id': data['id'],
        'name': data['name'],
        'webUrl': data['webUrl'],
        'downloadUrl': data['@microsoft.graph.downloadUrl'],
        'size': data['size'],
      };
    } else {
      throw Exception('Upload failed: ${response.body}');
    }
  }

  // Resumable upload for large files
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
      '${OneDriveConfig.graphApiBaseUrl}/me/drive/root:/$fullPath:/createUploadSession',
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

    if (sessionResponse.statusCode != 200) {
      throw Exception(
        'Failed to create upload session: ${sessionResponse.body}',
      );
    }

    final sessionData = jsonDecode(sessionResponse.body);
    final uploadUrl = sessionData['uploadUrl'];

    // Upload in chunks
    // const chunkSize = 320 * 1024 * 10; // 3.2 MB chunks
    final fileStream = file.openRead();
    int uploadedBytes = 0;

    await for (var chunk in fileStream) {
      final chunkLength = chunk.length;
      final endByte = uploadedBytes + chunkLength - 1;

      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Length': chunkLength.toString(),
          'Content-Range': 'bytes $uploadedBytes-$endByte/$fileSize',
        },
        body: chunk,
      );

      uploadedBytes += chunkLength;

      if (onProgress != null) {
        onProgress(uploadedBytes / fileSize);
      }

      // If upload is complete
      if (uploadResponse.statusCode == 200 ||
          uploadResponse.statusCode == 201) {
        final data = jsonDecode(uploadResponse.body);
        return {
          'id': data['id'],
          'name': data['name'],
          'webUrl': data['webUrl'],
          'downloadUrl': data['@microsoft.graph.downloadUrl'],
          'size': data['size'],
        };
      }
    }

    throw Exception('Upload failed');
  }

  // Upload PDF report
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
      final result = await uploadFile(
        file: images[i],
        remotePath: categoryFolder,
      );
      uploadedFiles.add(result);

      if (onProgress != null) {
        onProgress(i + 1, images.length);
      }
    }

    return uploadedFiles;
  }

  // Get sharing link for a file
  Future<String> getSharingLink(String itemId) async {
    await _ensureToken();

    final url = Uri.parse(
      '${OneDriveConfig.graphApiBaseUrl}/me/drive/items/$itemId/createLink',
    );

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'type': 'view', 'scope': 'anonymous'}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['link']['webUrl'];
    } else {
      throw Exception('Failed to create sharing link: ${response.body}');
    }
  }
}
