import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

// --- 1. Custom HTTP Client for Google API Calls ---
class GoogleAuthClient extends http.BaseClient {
  // Make the headers public so AuthService can access them.
  final Map<String, String> headers; 
  final http.Client _client = http.Client();

  GoogleAuthClient(this.headers); // Use the public field

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(headers));
  }
}
// --- 2. Auth Service for Google Sign-In and Drive Access ---

class AuthService with ChangeNotifier {
  
  // Using the iosClientId from firebase_options.dart to resolve Android SHA-1 conflict
  // static const String _webClientId = '903175298103-po6nun2jjkcp99jl64vrncom692r8c42.apps.googleusercontent.com'; 
  Map<String, String>? get authHeaders => _httpClient?.headers;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // clientId: _webClientId, 
    scopes: [
      'email',
      drive.DriveApi.driveFileScope, // Required scope for file access
    ],
  );

  GoogleAuthClient? _httpClient;
  User? _firebaseUser;
  drive.DriveApi? _driveApi;

  GoogleAuthClient? get httpClient => _httpClient;
  User? get currentUser => _firebaseUser;
  drive.DriveApi? get driveApi => _driveApi;
  bool get isAuthenticated => _httpClient != null;
  String? get currentUserId => _firebaseUser?.uid;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthService() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (account != null) {
        _handleSignIn(account);
      } else {
        _handleSignOut();
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        return false;
      }
      return await _handleSignIn(account);
    } catch (e) {
      _setError('Google sign-in failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _handleSignIn(GoogleSignInAccount account) async {
    final GoogleSignInAuthentication googleAuth = await account.authentication;

    _httpClient = GoogleAuthClient({
      'Authorization': 'Bearer ${googleAuth.accessToken}',
    });
    
    _driveApi = drive.DriveApi(_httpClient!);

    try {
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        _firebaseUser = userCredential.user;
    } catch (e) {
        print("Firebase sign-in failed (continuing with Drive access): $e");
    }

    notifyListeners();
    return true;
  }
  
  Future<void> signOut() async {
    _setLoading(true);
    _setError(null);
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut(); 
      _handleSignOut();
    } catch (e) {
      _setError('Sign out failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  void setError(String? message) {
    _setError(message);
  }

  void _handleSignOut() {
    _httpClient = null;
    _driveApi = null;
    _firebaseUser = null;
    notifyListeners();
  }
  
  void _setLoading(bool status) {
    _isLoading = status;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
     _setError('Email/Password is not supported for Google Drive integration. Please use "Sign In with Google".');
  }
}