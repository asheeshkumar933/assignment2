import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../image/model/image_item_model.dart';
import '../service/home_upload_service.dart';

class HomeProvider extends ChangeNotifier {
  final ImagePicker _picker;
  final HomeUploadService _uploadService;

  HomeProvider({
    ImagePicker? picker,
    HomeUploadService? uploadService,
  })  : _picker = picker ?? ImagePicker(),
        _uploadService = uploadService ?? HomeUploadService();

  int _currentIndex = 0;
  XFile? _pickedFile;
  Uint8List? _pickedBytes;
  String? _pickedFileName;
  bool _isUploading = false;
  String? _lastUploadedUrl;
  String? _errorMessage;

  int get currentIndex => _currentIndex;
  XFile? get pickedFile => _pickedFile;
  Uint8List? get pickedBytes => _pickedBytes;
  String? get pickedFileName => _pickedFileName;
  bool get isUploading => _isUploading;
  String? get lastUploadedUrl => _lastUploadedUrl;
  String? get errorMessage => _errorMessage;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Allows setting picked image bytes directly (useful for testing and custom pickers).
  void setPickedImageBytes(Uint8List bytes, {String fileName = 'picked.jpg'}) {
    _pickedBytes = bytes;
    _pickedFileName = fileName;
    _pickedFile = XFile.fromData(bytes, name: fileName, path: fileName);
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    _errorMessage = null;
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (file != null) {
        _pickedFile = file;
        _pickedFileName = file.name.isNotEmpty ? file.name : 'image.jpg';
        _pickedBytes = await file.readAsBytes();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  void clearSelectedImage() {
    _pickedFile = null;
    _pickedBytes = null;
    _pickedFileName = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<ImageItemModel?> uploadSelectedImage({required String title}) async {
    if (_pickedBytes == null) return null;

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fileName = (_pickedFileName != null && _pickedFileName!.isNotEmpty)
          ? _pickedFileName!
          : (_pickedFile?.name.isNotEmpty == true
              ? _pickedFile!.name
              : 'upload.jpg');
      final uploadedItem = await _uploadService.uploadPickedImage(
        bytes: _pickedBytes!,
        fileName: fileName,
        title: title,
      );
      _lastUploadedUrl = uploadedItem.imageUrl;
      clearSelectedImage();
      return uploadedItem;
    } catch (e) {
      _errorMessage = 'Upload failed: $e';
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}
