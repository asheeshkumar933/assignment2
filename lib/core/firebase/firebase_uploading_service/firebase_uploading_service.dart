import 'package:flutter/foundation.dart';
import '../../../feature/image/model/image_item_model.dart';
import '../firebase_config/firebase_config.dart';

class FirebaseUploadingService {
  /// Stores the Cloudinary [imageUrl] string and image metadata in
  /// Firebase Cloud Firestore (`images` collection).
  Future<ImageItemModel> uploadImageUrlToFirestore({
    required String? imageUrl,
    required String fileName,
    required String title,
    Uint8List? bytes,
  }) async {
    final now = DateTime.now();
    final safeTitle = title.trim().isEmpty ? fileName : title.trim();

    if (!FirebaseConfig.isReady) {
      return ImageItemModel(
        id: now.millisecondsSinceEpoch.toString(),
        title: safeTitle,
        imageUrl: imageUrl,
        bytes: bytes,
        createdAt: now,
      );
    }

    final tempModel = ImageItemModel(
      id: '',
      title: safeTitle,
      imageUrl: imageUrl,
      bytes: bytes,
      createdAt: now,
    );

    final docRef = await FirebaseConfig.imagesCollection.add(
      tempModel.toFirestore(),
    );

    if (kDebugMode) {
      debugPrint(
        'Stored image in Firestore (docId: ${docRef.id}, url: $imageUrl)',
      );
    }

    return ImageItemModel(
      id: docRef.id,
      title: safeTitle,
      imageUrl: imageUrl,
      bytes: bytes,
      createdAt: now,
    );
  }
}
