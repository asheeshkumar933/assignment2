import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/firebase/firebase_config/firebase_config.dart';
import '../model/image_item_model.dart';

class ImageFirebaseService {
  /// Real-time stream of Firestore query snapshots for incremental updates
  /// (so only newly added/removed documents are processed).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchImageChangesFromFirebase() {
    if (!FirebaseConfig.isReady) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return FirebaseConfig.imagesCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Gets all uploaded images from Firebase Cloud Firestore ordered by `createdAt`.
  Future<List<ImageItemModel>> getImagesFromFirebase() async {
    if (!FirebaseConfig.isReady) return [];

    final querySnapshot = await FirebaseConfig.imagesCollection
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => ImageItemModel.fromFirestore(doc))
        .toList();
  }

  /// Deletes an image from Firebase Storage and Cloud Firestore.
  Future<void> deleteImageFromFirebase(ImageItemModel item) async {
    if (!FirebaseConfig.isReady) return;

    if (item.storagePath != null && item.storagePath!.isNotEmpty) {
      try {
        await FirebaseConfig.storage.ref().child(item.storagePath!).delete();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Storage delete error: $e');
        }
      }
    }
    await FirebaseConfig.imagesCollection.doc(item.id).delete();
  }
}
