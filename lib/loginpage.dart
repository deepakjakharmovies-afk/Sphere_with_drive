import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/auth_service.dart';

// --- THE UI: Login Screen ---

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 400 ? 360.0 : screenWidth * 0.9;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            width: contentWidth,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.drive_eta,
                  size: 80,
                  color: Colors.indigo.shade400,
                ),
                const SizedBox(height: 20),

                const Text(
                  'SnapSphere requires Google Drive access to securely store and share photos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                
                // --- Error Message Display ---
                if (authService.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      authService.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                
                const SizedBox(height: 16),

                // --- Google Button ---
                SizedBox(
                  width: double.infinity, 
                  child: ElevatedButton.icon(
                    onPressed: authService.isLoading ? null : authService.signInWithGoogle,
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 20,
                      width: 20,
                    ),
                    label: authService.isLoading
                      ? const SizedBox(
                          width: 20, height: 20, 
                          child: CircularProgressIndicator(color: Colors.black54, strokeWidth: 2)
                        )
                      : const Text(
                          'Sign In & Connect Google Drive',
                          style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
                        ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, 
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      elevation: 4, 
                      shadowColor: Colors.grey.shade200,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Authenticated Email:',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authService.currentUser?.email ?? 'Not signed in',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}