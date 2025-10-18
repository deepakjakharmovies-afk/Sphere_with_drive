import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:app/firebase_options.dart';
import 'package:app/auth_service.dart';
import 'package:app/drive_service.dart';
import 'package:app/loginpage.dart';
import 'package:app/mainscreen.dart';

// --- 1. Main Function and Firebase Init ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for configuration/client ID retrieval only.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, 
  );
  
  runApp(const SnapSphereApp());
}

// --- 2. Auth Wrapper for Navigation ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // If we have an authenticated GoogleHttpClient (Drive access)
        if (authService.isAuthenticated) {
          return const HomeScreen();
        } 
        
        // Otherwise, show the login screen
        return const LoginScreen();
      },
    );
  }
}

// --- 3. App Setup ---
class SnapSphereApp extends StatelessWidget {
  const SnapSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider( // Use MultiProvider to manage multiple services
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        // DriveService depends on AuthService, so we use ProxyProvider
        ChangeNotifierProxyProvider<AuthService, DriveService>(
          // We provide the AuthService instance to the DriveService constructor
          create: (context) => DriveService(context.read<AuthService>()),
          // The update function ensures DriveService is recreated/updated if AuthService changes
          update: (context, auth, drive) => DriveService(auth),
        ),
      ],
      child: MaterialApp(
        title: 'SnapSphere (Drive)',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Inter',
          // Applying a cleaner input theme globally
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.indigo, width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.grey, width: 1)),
          )
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
