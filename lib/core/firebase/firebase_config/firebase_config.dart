import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

class FirebaseConfig {
  static bool _isInitialized = false;

  static bool get isReady => _isInitialized;

  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static FirebaseStorage get storage => FirebaseStorage.instance;

  static CollectionReference<Map<String, dynamic>> get imagesCollection =>
      firestore.collection('images');

  /// Initializes Firebase with [DefaultFirebaseOptions.currentPlatform].
  static Future<void> init() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        return;
      }
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase initialization error: $e');
      }
      _isInitialized = false;
    }
  }
}
