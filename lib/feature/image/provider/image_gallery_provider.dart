import 'dart:async';
import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/firebase/firebase_config/firebase_config.dart';
import '../model/image_item_model.dart';
import '../service/image_firebase_service.dart';

class ImageGalleryProvider extends ChangeNotifier {
  final ImageFirebaseService _imageService = ImageFirebaseService();
  final List<ImageItemModel> _uploadedImages = [];
  late final UnmodifiableListView<ImageItemModel> _unmodifiableImages =
      UnmodifiableListView(_uploadedImages);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _imagesSubscription;
  bool _isLoading = false;
  String? _errorMessage;

  /// Cached unmodifiable view (zero allocation on read).
  List<ImageItemModel> get uploadedImages => _unmodifiableImages;
  int get itemCount => _uploadedImages.length;
  ImageItemModel itemAt(int index) => _uploadedImages[index];
  int indexOfId(String id) => _uploadedImages.indexWhere((e) => e.id == id);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Subscribes to real-time Firestore `docChanges` so only newly added,
  /// modified, or removed images update the list without rebuilding all items.
  void initRealtimeImages() {
    if (!FirebaseConfig.isReady) return;

    if (_uploadedImages.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    _imagesSubscription?.cancel();
    _imagesSubscription =
        _imageService.watchImageChangesFromFirebase().listen(
      (snapshot) {
        bool hasChanges = false;

        for (final change in snapshot.docChanges) {
          final item = ImageItemModel.fromFirestore(change.doc);
          switch (change.type) {
            case DocumentChangeType.added:
              final existingIdx = indexOfId(item.id);
              if (existingIdx == -1) {
                final insertIndex = change.newIndex
                    .clamp(0, _uploadedImages.length);
                _uploadedImages.insert(insertIndex, item);
                hasChanges = true;
              }
              break;
            case DocumentChangeType.modified:
              final existingIdx = indexOfId(item.id);
              if (existingIdx != -1) {
                _uploadedImages[existingIdx] = item;
                hasChanges = true;
              }
              break;
            case DocumentChangeType.removed:
              final beforeLen = _uploadedImages.length;
              _uploadedImages.removeWhere((e) => e.id == item.id);
              if (_uploadedImages.length != beforeLen) {
                hasChanges = true;
              }
              break;
          }
        }

        if (_isLoading || hasChanges) {
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        }
      },
      onError: (Object error) {
        if (kDebugMode) {
          debugPrint('Real-time sync error: $error');
        }
        _errorMessage = 'Real-time sync error: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Pull-to-refresh handler: fetches from Firestore without clearing existing
  /// items or showing a full-screen loader, merging only new/removed items.
  Future<void> loadImages({bool showFullScreenLoader = false}) async {
    if (showFullScreenLoader && _uploadedImages.isEmpty) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final remoteImages = await _imageService.getImagesFromFirebase();
      if (remoteImages.isNotEmpty || FirebaseConfig.isReady) {
        final existingById = {
          for (final item in _uploadedImages) item.id: item,
        };
        final merged = remoteImages
            .map((remote) => existingById[remote.id] ?? remote)
            .toList();

        _uploadedImages
          ..clear()
          ..addAll(merged);
      }
    } catch (e) {
      _errorMessage = 'Failed to load images from Firebase: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds only the newly uploaded item at the top of the gallery.
  void addUploadedItem(ImageItemModel item) {
    if (indexOfId(item.id) != -1) {
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

  @override
  void dispose() {
    _imagesSubscription?.cancel();
    super.dispose();
  }
}
