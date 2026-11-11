import 'package:flutter/foundation.dart';
import '../../../core/firebase/firebase_config/firebase_config.dart';
import '../model/image_item_model.dart';

class ImageFirebaseService {
  // Real-time stream of uploaded images from Cloud Firestore (commented out for now, using get below):
  // Stream<List<ImageItemModel>> watchImagesFromFirebase() {
  //   if (!FirebaseConfig.isReady) {
  //     return const Stream<List<ImageItemModel>>.empty();
  //   }
  //
  //   return FirebaseConfig.imagesCollection
  //       .orderBy('createdAt', descending: true)
  //       .snapshots()
  //       .map(
  //         (snapshot) => snapshot.docs
  //             .map((doc) => ImageItemModel.fromFirestore(doc))
  //             .toList(),
  //       );
  // }

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
