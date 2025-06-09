import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  // Getters
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthService() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _fetchUserData();
      } else {
        _userData = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserData() async {
    if (_user == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      _userData = doc.data();
      notifyListeners();
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  // Email & Password Authentication
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _fetchUserData();
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String university,
    required String college,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      final userData = {
        'fullName': fullName,
        'email': email,
        'university': university,
        'college': college,
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
        'profilePicture': null,
      };

      await _firestore.collection('users').doc(result.user!.uid).set(userData);
      
      // Send email verification
      await result.user!.sendEmailVerification();
      
      await _fetchUserData();
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      
      // Check if user document exists
      final userDoc = await _firestore.collection('users').doc(result.user!.uid).get();
      
      if (!userDoc.exists) {
        // Create new user document
        final userData = {
          'fullName': result.user!.displayName,
          'email': result.user!.email,
          'profilePicture': result.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': result.user!.emailVerified,
        };

        await _firestore.collection('users').doc(result.user!.uid).set(userData);
      }
      
      await _fetchUserData();
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _auth.sendPasswordResetEmail(email: email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Email Verification
  Future<void> sendEmailVerification() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _user?.sendEmailVerification();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Profile
  Future<void> updateProfile({
    String? fullName,
    String? university,
    String? college,
    String? profilePicture,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updates = <String, dynamic>{};
      if (fullName != null) updates['fullName'] = fullName;
      if (university != null) updates['university'] = university;
      if (college != null) updates['college'] = college;
      if (profilePicture != null) updates['profilePicture'] = profilePicture;

      await _firestore.collection('users').doc(_user!.uid).update(updates);
      await _fetchUserData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      
      _userData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 