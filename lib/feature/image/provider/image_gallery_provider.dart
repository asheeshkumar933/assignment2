import 'package:flutter/foundation.dart';
import '../../../core/firebase/firebase_config/firebase_config.dart';
import '../model/image_item_model.dart';
import '../service/image_firebase_service.dart';

class ImageGalleryProvider extends ChangeNotifier {
  final ImageFirebaseService _imageService = ImageFirebaseService();
  final List<ImageItemModel> _uploadedImages = [];
  // StreamSubscription<List<ImageItemModel>>? _imagesSubscription;
  bool _isLoading = false;
  String? _errorMessage;

  List<ImageItemModel> get uploadedImages => List.unmodifiable(_uploadedImages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Real-time Firestore stream implementation (commented out as requested):
  // Stream<List<ImageItemModel>> get imagesStream =>
  //     _imageService.watchImagesFromFirebase();
  //
  // void initRealtimeImages() {
  //   if (!FirebaseConfig.isReady) return;
  //
  //   _isLoading = true;
  //   _errorMessage = null;
  //   notifyListeners();
  //
  //   _imagesSubscription?.cancel();
  //   _imagesSubscription = _imageService.watchImagesFromFirebase().listen(
  //     (remoteImages) {
  //       _uploadedImages
  //         ..clear()
  //         ..addAll(remoteImages);
  //       _isLoading = false;
  //       _errorMessage = null;
  //       notifyListeners();
  //     },
  //     onError: (Object error) {
  //       _errorMessage = 'Real-time sync error: $error';
  //       _isLoading = false;
  //       notifyListeners();
  //     },
  //   );
  // }

  /// Fetches images from Firestore using one-time `get()` when visiting the Image tab.
  Future<void> loadImages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteImages = await _imageService.getImagesFromFirebase();
      if (remoteImages.isNotEmpty || FirebaseConfig.isReady) {
        _uploadedImages
          ..clear()
          ..addAll(remoteImages);
      }
    } catch (e) {
      _errorMessage = 'Failed to load images from Firebase: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addUploadedItem(ImageItemModel item) {
    if (_uploadedImages.any((existing) => existing.id == item.id)) {
      return;
    }
    _uploadedImages.insert(0, item);
    notifyListeners();
  }

  Future<void> removeImageAt(int index) async {
    if (index < 0 || index >= _uploadedImages.length) return;
    final item = _uploadedImages[index];
    _uploadedImages.removeAt(index);
    notifyListeners();

    try {
      await _imageService.deleteImageFromFirebase(item);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to delete image from Firebase: $e');
      }
    }
  }

  // @override
  // void dispose() {
  //   _imagesSubscription?.cancel();
  //   super.dispose();
  // }
}
