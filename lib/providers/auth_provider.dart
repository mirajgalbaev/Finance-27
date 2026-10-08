import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:finance_27/models/user_model.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final UserModel? currentUser;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.currentUser,
    this.error,
  });

  bool get isLoggedIn => currentUser != null;

  AuthState copyWith({
    bool? isLoading,
    UserModel? currentUser,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      currentUser: currentUser ?? this.currentUser,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isLoading: true)) {
    _initAuth();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  void _initAuth() {
    final box = Hive.box('authSession');
    final cachedUid = box.get('uid') as String?;
    
    if (cachedUid != null) {
      final fallbackUser = UserModel(
         id: cachedUid,
         name: box.get('name') as String? ?? 'User',
         email: box.get('email') as String? ?? '',
         password: '',
      );
      state = state.copyWith(currentUser: fallbackUser, isLoading: true);
      _fetchUser(cachedUid);
    }

    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        if (cachedUid == null) {
          state = state.copyWith(currentUser: null, isLoading: false);
        }
      } else {
        box.put('uid', user.uid);
        box.put('name', user.displayName);
        box.put('email', user.email);

        final fallbackUser = UserModel(
           id: user.uid,
           name: user.displayName ?? 'User',
           email: user.email ?? '',
           password: '',
        );
        state = state.copyWith(currentUser: fallbackUser, isLoading: true);
        await _fetchUser(user.uid);
      }
    });
  }

  Future<void> _fetchUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final userModel = UserModel.fromMap(doc.data()!, uid);
        state = state.copyWith(currentUser: userModel, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Kullanıcı verisi alınamadı (Çevrimdışı): $e');
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        final newUser = UserModel(
          id: cred.user!.uid,
          name: name,
          email: email,
          password: password, // You usually wouldn't store password in Firestore, but preserving for compatibility
        );

        await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
        state = state.copyWith(isLoading: false, currentUser: newUser);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _translateAuthError(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Kayıt işlemi başarısız oldu: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // state changes automatically due to authStateChanges listener
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _translateAuthError(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Giriş işlemi başarısız oldu: $e');
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _translateAuthError(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Şifre sıfırlama işlemi başarısız oldu: $e');
      return false;
    }
  }

  Future<bool> updateProfileImage({String? imagePath, XFile? xFile}) async {
    final user = state.currentUser;
    if (user == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      String finalPath = imagePath ?? '';
      
      // Instead of Firebase Storage, we convert the image to Base64 to save in Firestore
      if (xFile != null) {
        final bytes = await xFile.readAsBytes();
        final base64String = base64Encode(bytes);
        finalPath = 'data:image/jpeg;base64,$base64String';
      } else if (imagePath != null && !imagePath.startsWith('http') && !imagePath.startsWith('data:image')) {
        final File file = File(imagePath);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        finalPath = 'data:image/jpeg;base64,$base64String';
      }

      final updatedUser = user.copyWith(profileImagePath: finalPath);
      await _firestore.collection('users').doc(user.id).set(updatedUser.toMap(), SetOptions(merge: true));
      state = state.copyWith(currentUser: updatedUser, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Profil fotoğrafı güncellenemedi: $e', isLoading: false);
      return false;
    }
  }

  Future<bool> updateName(String newName) async {
    final user = state.currentUser;
    if (user == null) return false;

    state = state.copyWith(isLoading: true);
    final updatedUser = user.copyWith(name: newName);
    
    try {
      await _firestore.collection('users').doc(user.id).update(updatedUser.toMap());
      state = state.copyWith(currentUser: updatedUser, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'İsim güncellenemedi: $e', isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await Hive.box('authSession').clear();
    state = AuthState();
  }

  Future<void> reset() async {
    // Delete account logic? Or just reset local hive boxes
    // Usually reset clears data, so maybe just logout in Firebase context
    await logout();
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn(
          clientId: kIsWeb ? '713846843400-7t46n80t2gjvv6bki71bcmbkcididv6c.apps.googleusercontent.com' : null,
        ).signIn();
        if (googleUser == null) {
          state = state.copyWith(isLoading: false);
          return false;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }
      final User? user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          final newUser = UserModel(
            id: user.uid,
            name: user.displayName ?? 'Google User',
            email: user.email ?? '',
            password: '',
          );
          await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
          state = state.copyWith(isLoading: false, currentUser: newUser);
        } else {
          final userModel = UserModel.fromMap(doc.data()!, user.uid);
          state = state.copyWith(isLoading: false, currentUser: userModel);
        }
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google giriş işlemi başarısız oldu: $e');
      return false;
    }
  }
  String _translateAuthError(FirebaseAuthException e) {
    return e.code;
}
}
