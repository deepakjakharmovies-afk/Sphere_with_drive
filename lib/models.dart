class DriveFile {
  final String id;
  final String name;
  final String mimeType;
  final String? webContentLink; // URL to download the file
  final String? thumbnailUrl; // For images

  DriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
    this.webContentLink,
    this.thumbnailUrl,
  });

  // Factory constructor to convert a googleapis Drive File object into our local model
  factory DriveFile.fromGoogleApi(
      String id, String name, String mimeType, String? link, String? thumbnail) {
    return DriveFile(
      id: id,
      name: name,
      mimeType: mimeType,
      webContentLink: link,
      thumbnailUrl: thumbnail,
    );
  }
}

// Our core data model, representing a shared photo album (a Drive folder)
class Sphere {
  final String id;
  final String name;
  final String ownerEmail;
  final DateTime createdAt;

  Sphere({
    required this.id,
    required this.name,
    required this.ownerEmail,
    required this.createdAt,
  });
}