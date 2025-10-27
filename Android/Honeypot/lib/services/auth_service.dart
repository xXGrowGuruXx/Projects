import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'mongodb_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final MongoDBService _mongoService = MongoDBService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  
  AuthService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _updateUserFromFirebase(firebaseUser);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }
  
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Check if user is already signed in
      final user = _auth.currentUser;
      if (user != null) {
        await _updateUserFromFirebase(user);
      } else {
        // Try silent sign-in
        await _silentSignIn();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Auth init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _silentSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
    }
  }
  
  Future<bool> signInWithGoogle() async {
    debugPrint('=== Google Sign-In started ===');
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Trigger the authentication flow
      debugPrint('Requesting Google account selection...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        debugPrint('User canceled sign-in');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      debugPrint('Google account selected: ${googleUser.email}');
      
      // Obtain the auth details from the request
      debugPrint('Getting authentication tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('Tokens received');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      debugPrint('Firebase credential created');

      // Sign in to Firebase with the Google credential
      debugPrint('Signing in to Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('Firebase sign-in successful: ${userCredential.user?.email}');
      
      _isLoading = false;
      notifyListeners();
      debugPrint('=== Google Sign-In completed successfully ===');
      return true;
    } catch (e, stackTrace) {
      _error = 'Login fehlgeschlagen: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('=== Google Sign-In ERROR ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }
  
  Future<void> _updateUserFromFirebase(User firebaseUser) async {
    try {
      final now = DateTime.now();
      UserModel? existingUser;
      
      // Try to load user from MongoDB (optional, may fail)
      try {
        existingUser = await _mongoService.getUser(firebaseUser.uid);
        debugPrint('MongoDB: User loaded successfully');
      } catch (mongoError) {
        debugPrint('MongoDB error (non-critical): $mongoError');
      }
      
      if (existingUser != null) {
        // User exists in MongoDB, update last login
        _currentUser = existingUser.copyWith(lastLogin: now);
        try {
          await _mongoService.updateLastLogin(firebaseUser.uid);
        } catch (e) {
          debugPrint('MongoDB update failed (non-critical): $e');
        }
      } else {
        // New user or MongoDB unavailable, create profile from Firebase
        _currentUser = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'Imker',
          photoUrl: firebaseUser.photoURL,
          role: await _getUserRole(firebaseUser.email),
          cloudBackupEnabled: false,
          createdAt: firebaseUser.metadata.creationTime ?? now,
          lastLogin: now,
        );
        
        // Try to save new user to MongoDB
        try {
          await _mongoService.saveUser(_currentUser!);
          debugPrint('MongoDB: New user saved');
        } catch (e) {
          debugPrint('MongoDB save failed (non-critical): $e');
        }
      }
      
      debugPrint('User authenticated: ${_currentUser!.email} (${_currentUser!.role})');
      notifyListeners();
    } catch (e) {
      debugPrint('CRITICAL ERROR updating user from Firebase: $e');
      // Auch bei Fehler: Setze User auf null, damit UI reagiert
      _currentUser = null;
      notifyListeners();
    }
  }
  
  Future<String> _getUserRole(String? email) async {
    // Admin check
    if (email == 'akeine99@gmail.com') {
      return 'admin';
    }
    
    // TODO: Load role from MongoDB
    return 'standard';
  }
  
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _currentUser = null;
    } catch (e) {
      _error = 'Logout fehlgeschlagen: $e';
      debugPrint('Sign-out error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from MongoDB
        await _mongoService.deleteUser(user.uid);
        await user.delete();
        _currentUser = null;
      }
    } catch (e) {
      _error = 'Konto löschen fehlgeschlagen: $e';
      debugPrint('Delete account error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Admin feature: Switch role view
  Future<void> switchRole(String newRole) async {
    if (_currentUser == null || _currentUser!.role != 'admin') {
      debugPrint('Only admins can switch roles');
      return;
    }
    
    try {
      _currentUser = _currentUser!.copyWith(role: newRole);
      notifyListeners();
      debugPrint('Admin switched to role: $newRole');
    } catch (e) {
      debugPrint('Error switching role: $e');
    }
  }
  
  // Update cloud backup setting
  Future<void> updateCloudBackup(bool enabled) async {
    if (_currentUser == null) return;
    
    try {
      await _mongoService.updateCloudBackup(_currentUser!.id, enabled);
      _currentUser = _currentUser!.copyWith(cloudBackupEnabled: enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating cloud backup: $e');
    }
  }
}
