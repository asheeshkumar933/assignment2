import 'package:flutter/foundation.dart';
import '../../../core/cloudinary/cloudinary_service.dart';
import '../../../core/firebase/firebase_uploading_service/firebase_uploading_service.dart';
import '../../image/model/image_item_model.dart';

class HomeUploadService {
  final CloudinaryService _cloudinaryService;
  final FirebaseUploadingService _firebaseUploadingService;

  HomeUploadService({
    CloudinaryService? cloudinaryService,
    FirebaseUploadingService? firebaseUploadingService,
  })  : _cloudinaryService = cloudinaryService ?? CloudinaryService(),
        _firebaseUploadingService =
            firebaseUploadingService ?? FirebaseUploadingService();

  /// 1. Uploads image bytes to Cloudinary and gets the String URL.
  /// 2. Stores the returned String URL in Firebase Cloud Firestore.
  Future<ImageItemModel> uploadPickedImage({
    required Uint8List bytes,
    required String fileName,
    required String title,
  }) async {
    final String cloudinaryUrl = await _cloudinaryService.uploadImage(
      bytes: bytes,
      fileName: fileName,
    );

    if (kDebugMode) {
      debugPrint('Cloudinary uploaded URL: $cloudinaryUrl');
    }

    return _firebaseUploadingService.uploadImageUrlToFirestore(
      imageUrl: cloudinaryUrl,
      fileName: fileName,
      title: title,
      bytes: bytes,
    );
  }
}
