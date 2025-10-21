import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/auth_service.dart';
import 'package:app/drive_service.dart';
import 'package:app/gridveiw.dart'; // Retained for navigation

// The data models are now in models.dart, so we'll remove the local Trip class
// and use the DriveService data structure.

// --- 1. Home Screen (Main App Shell) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapSphere (Drive)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<DriveService>(context, listen: false).fetchSpheres(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: authService.signOut,
          ),
        ],
      ),
      body: const SphereListView(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left:30.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // spacing:,
          children: [
            FloatingActionButton(onPressed: () => _joinShereDialog(context),
            child: const Icon(Icons.group_sharp),),
            FloatingActionButton(
              onPressed: () => _showCreateSphereDialog(context),
              child: const Icon(Icons.add),
            ),
            
          ],
        ),
      ),
      // persistentFooterButtons: [
      //   Text('Logged in as: ${authService.currentUser?.email ?? 'Unknown'}'),
      // ],
      // floatingActionButton: FloatingActionButton(onPressed: () {},
      // child: const Icon(Icon.join),),
    );
  }
  void _joinShereDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const joinShereDialog(),
    );
  }
  void _showCreateSphereDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const CreateSphereDialog(),
    );
  }
}
 final link = TextEditingController();

class joinShereDialog extends StatelessWidget {
  const joinShereDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Join a Sphere"),
      content: TextField(
        controller: link,
        decoration: const InputDecoration(
          labelText: 'Enter Sphere Code',
          
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            
            // final link  = TextEditingController().text;
            Provider.of<DriveService>(context, listen: false).joinSphereFromLink(link.text);
            Navigator.pop(context);
          },
          child: const Text('Join'),
        ),
      ],
    );
  }
}
class CreateLinkDiloge extends StatefulWidget {
  final String? link;
  const CreateLinkDiloge.CreateLinkDialog({super.key,this.link});

  @override
  State<CreateLinkDiloge> createState() => _CreateLinkDilogeState();
}
void _whattodo(BuildContext context,String folderId) {
    showDialog(
      context: context,
      builder: (ctx) => WhatTOdo(folderId: folderId),
    );
  }
void _showlinkShareableLinkDialog(BuildContext context,String? link) {
    showDialog(
      context: context,
      builder: (ctx) => CreateLinkDiloge.CreateLinkDialog(link: link),
    );
  }
class _CreateLinkDilogeState extends State<CreateLinkDiloge> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("shareable Link"),
      content: SelectableText(widget.link.toString() ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Close"))
      ],
    );
  }
}
// --- 2. List View of Spheres (Drive Folders) ---

class SphereListView extends StatelessWidget {
  const SphereListView({super.key});

  @override
  Widget build(BuildContext context) {
    final driveService = Provider.of<DriveService>(context);

    if (driveService.isLoading && driveService.spheres.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (driveService.spheres.isEmpty) {
      return const Center(
        child: Text('No SnapSpheres found. Create one to get started!'),
      );
    }

    return ListView.builder(
      itemCount: driveService.spheres.length,
      itemBuilder: (context, index) {
        final sphere = driveService.spheres[index];
        return GestureDetector(
          onLongPress: () => _whattodo(context,sphere.id), // Delete sphere on long press
          //   if (link != null) {
          //     _showlinkShareableLinkDialog(context,link);
          //   } else {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text('Failed to create shareable link.')),
          //     );
          //   }
          // }
          
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.double_arrow_outlined, color: Colors.indigo, size: 55),
              title: Text(sphere.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Owner: ${sphere.ownerEmail}'),
              // isThreeLine: true,
              onTap: () {
                // Navigate to the photo grid view, passing the Sphere ID (Drive Folder ID)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoGridScreen(sphere: sphere),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class WhatTOdo extends StatelessWidget {
  final String folderId;
  const WhatTOdo({super.key,required this.folderId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("What do you want to do?"),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(onPressed:()async{
            final link = await Provider.of<DriveService>(context, listen: false).createShareableLink(folderId);
            if (link != null) {
              _showlinkShareableLinkDialog(context,link);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to create shareable link.')),
              );
            }

          }, child: Text("link")),
          ElevatedButton(onPressed:(){ Provider.of<DriveService>(context, listen: false).deleteFolder(folderId);
          Navigator.pop(context);} ,child: Text("delete"))
          // fatchspheres(,
          
        ],
      ),
    );
  }
}

// --- 3. Create Sphere Dialog ---

class CreateSphereDialog extends StatefulWidget {
  const CreateSphereDialog({super.key});

  @override
  State<CreateSphereDialog> createState() => _CreateSphereDialogState();
}

class _CreateSphereDialogState extends State<CreateSphereDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _isCreating = false;

  Future<void> _createSphere() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);

    final driveService = Provider.of<DriveService>(context, listen: false);
    final success = await driveService.createSphere(name);

    setState(() => _isCreating = false);

    if (success) {
      Navigator.pop(context); // Close dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New SnapSphere'),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Sphere Name (Drive Folder Name)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createSphere,
          child: _isCreating 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
            : const Text('Create'),
        ),
      ],
    );
  }
}