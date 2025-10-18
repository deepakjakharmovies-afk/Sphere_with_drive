import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/auth_service.dart';
import 'package:app/models.dart';
import 'package:http/http.dart' as http;

class DriveService with ChangeNotifier {
  final AuthService _authService;
  final String _sphereRootFolderName = "SnapSphere Photos";
  String? _snapSphereRootId;
  AuthService get authService => _authService;

  List<Sphere> _spheres = [];
  bool _isLoading = false;

  List<Sphere> get spheres => _spheres;
  bool get isLoading => _isLoading;

  DriveService(this._authService) {
    // Listen to authentication changes to trigger data refresh
    _authService.addListener(_onAuthChange);
    if (_authService.isAuthenticated) {
      _initialize();
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() {
    if (_authService.isAuthenticated) {
      _initialize();
    } else {
      _spheres = [];
      _snapSphereRootId = null;
      notifyListeners();
    }
  }

  drive.DriveApi? get _driveApi => _authService.driveApi;

  // --- Core Initialization ---

  Future<void> _initialize() async {
    if (_driveApi == null) return;
    await _ensureRootFolderExists();
    await fetchSpheres();
  }

  /// Ensures the main "SnapSphere Photos" folder exists in the user's Drive.
  Future<void> _ensureRootFolderExists() async {
    if (_driveApi == null || _snapSphereRootId != null) return;

    try {
      // Search for the root folder
      final fileList = await _driveApi!.files.list(
        q: "mimeType='application/vnd.google-apps.folder' and name='$_sphereRootFolderName' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Found the existing folder
        _snapSphereRootId = fileList.files!.first.id;
      } else {
        // Create the root folder if it doesn't exist
        final drive.File folder = drive.File();
        folder.name = _sphereRootFolderName;
        folder.mimeType = 'application/vnd.google-apps.folder';

        final createdFile = await _driveApi!.files.create(folder);
        _snapSphereRootId = createdFile.id;
        print('SnapSphere Root Folder created with ID: $_snapSphereRootId');
      }
    } catch (e) {
      print('Error ensuring root folder: $e');
      _authService.setError('Failed to access Google Drive root folder.');
    }
  }

  // --- Sphere (Folder) Management ---

  Future<void> fetchSpheres() async {
    if (_driveApi == null || _snapSphereRootId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      // Query for all folders (Spheres) inside the root folder
      final fileList = await _driveApi!.files.list(
        q: "mimeType='application/vnd.google-apps.folder' and '${_snapSphereRootId}' in parents and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name, createdTime, owners)',
      );

      _spheres = fileList.files
              ?.map((file) => Sphere(
                    id: file.id!,
                    name: file.name!,
                    ownerEmail: file.owners?.first.emailAddress ?? 'Unknown',
                    createdAt: file.createdTime?.toLocal() ?? DateTime.now(),
                  ))
              .toList() ??
          [];

      _spheres.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error fetching spheres: $e');
      _authService.setError('Failed to fetch photo albums from Drive.');
      _spheres = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSphere(String name) async {
    if (_driveApi == null || _snapSphereRootId == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final folder = drive.File();
      folder.name = name;
      folder.mimeType = 'application/vnd.google-apps.folder';
      folder.parents = [_snapSphereRootId!]; // Put inside the root folder

      final createdFolder = await _driveApi!.files.create(folder);
      
      // Refresh the list
      await fetchSpheres();
      return true;
    } catch (e) {
      print('Error creating sphere: $e');
      _authService.setError('Failed to create new photo album.');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // --- Photo (File) Management ---

  Future<List<DriveFile>> fetchPhotos(String sphereId) async {
    if (_driveApi == null) return [];

    try {
      final fileList = await _driveApi!.files.list(
        q: "mimeType contains 'image/' and '${sphereId}' in parents and trashed=false",
        spaces: 'drive',
        $fields:
            'files(id, name, mimeType, webContentLink, imageMediaMetadata, thumbnailLink)',
      );

      return fileList.files
              ?.map((file) => DriveFile.fromGoogleApi(
                    file.id!,
                    file.name!,
                    file.mimeType!,
                    file.webContentLink,
                    file.thumbnailLink,
                  ))
              .toList() ??
          [];
    } catch (e) {
      print('Error fetching photos: $e');
      return [];
    }
  }

  Future<bool> uploadPhoto(String sphereId, File imageFile) async {
    if (_driveApi == null) return false;
    
    try {
      final file = drive.File();
      file.name = imageFile.path.split('/').last; // Use the file name as the Drive name
      file.parents = [sphereId]; // Put inside the specific sphere folder

      final result = await _driveApi!.files.create(
            file,
            uploadMedia: drive.Media(
              imageFile.openRead(),
              imageFile.lengthSync(),
            ),
          );
      
      return result.id != null;
    } catch (e) {
      print('Error uploading file: $e');
      _authService.setError('Failed to upload photo to Drive.');
      return false;
    }
  }

  Future<bool> downloadAndSavePhoto(DriveFile file) async {
    if (_driveApi == null || _authService.httpClient == null) return false;

    // 1. Get permission
    if (await Permission.storage.request().isDenied) {
      _authService.setError('Storage permission denied.');
      return false;
    }

    try {
      // 2. Download the file using the authenticated HTTP client
      final response = await _authService.httpClient!.get(
        Uri.parse(
          'https://www.googleapis.com/drive/v3/files/${file.id}?alt=media',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Download failed with status: ${response.statusCode} ${response.body}');
      }
      
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        _authService.setError('Cannot access external storage.');
        return false;
      }
      
      // 3. Save to a temporary location
      final filePath = '${directory.path}/${file.name}';
      final saveFile = File(filePath);
      await saveFile.writeAsBytes(response.bodyBytes);

      // In a real Flutter app, you'd use a package like image_gallery_saver
      // to save it directly to the native photo gallery. Since we removed
      // that dependency due to build errors, we'll just log success.
      print('File downloaded successfully to: $filePath');
      
      return true;

    } catch (e) {
      print('Error downloading photo: $e');
      _authService.setError('Failed to download photo from Drive.');
      return false;
    }
  }
}