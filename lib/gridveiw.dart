import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:app/drive_service.dart';
import 'package:app/models.dart';

// Rename the class to be more descriptive of its new role
class PhotoGridScreen extends StatefulWidget {
  final Sphere sphere;
  const PhotoGridScreen({super.key, required this.sphere});

  @override
  State<PhotoGridScreen> createState() => _PhotoGridScreenState();
}

class _PhotoGridScreenState extends State<PhotoGridScreen> {
  final ImagePicker _picker = ImagePicker();
  List<DriveFile> _photos = [];
  bool _isLoadingPhotos = true;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    setState(() {
      _isLoadingPhotos = true;
    });
    final driveService = Provider.of<DriveService>(context, listen: false);
    _photos = await driveService.fetchPhotos(widget.sphere.id);
    setState(() {
      _isLoadingPhotos = false;
    });
  }

  Future<void> _uploadPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final driveService = Provider.of<DriveService>(context, listen: false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploading ${image.name}...')),
      );

      final success = await driveService.uploadPhoto(
        widget.sphere.id,
        File(image.path),
      );

      if (success) {
        // Refresh the grid to show the new photo
        await _fetchPhotos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload successful!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sphere.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPhotos,
          ),
        ],
      ),
      body: _isLoadingPhotos
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? const Center(child: Text('This Sphere is empty. Upload a photo!'))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return InkWell(
                      onTap: () => _viewPhoto(context, photo),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: photo.thumbnailUrl != null
                              ? Image.network(
                                  photo.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                    const Center(child: Icon(Icons.broken_image)),
                                )
                              : const Center(child: Icon(Icons.image)),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadPhoto,
        child: const Icon(Icons.file_upload),
      ),
    );
  }

  void _viewPhoto(BuildContext context, DriveFile photo) {
    final driveService = Provider.of<DriveService>(context, listen: false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(photo.name),
            centerTitle: true,
          ),
          body: Container(
            color: Colors.black,
            child: photo.webContentLink != null
                ? PhotoView(
                    // Drive requires the authenticated client, so we must load the image manually
                    imageProvider: NetworkImage(
                      'https://www.googleapis.com/drive/v3/files/${photo.id}?alt=media',
                      // FIX: Use the new public getter `authService`
                      headers: driveService.authService.authHeaders ?? {}, 
                    ),
                  )
                : const Center(child: Text('Cannot load image.', style: TextStyle(color: Colors.white))),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading file...')),
              );
              final success = await driveService.downloadAndSavePhoto(photo);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? 'Download complete!' : 'Download failed.')),
              );
            },
            child: const Icon(Icons.download),
          ),
        ),
      ),
    );
  }
}