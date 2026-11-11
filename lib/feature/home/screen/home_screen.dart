import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/firebase/firebase_config/firebase_config.dart';
import '../../../utils/responsive.dart';
import '../../image/provider/image_gallery_provider.dart';
import '../provider/home_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleUpload(BuildContext context) async {
    final homeProvider = context.read<HomeProvider>();
    final galleryProvider = context.read<ImageGalleryProvider>();

    final uploadedItem = await homeProvider.uploadSelectedImage(
      title: _titleController.text,
    );

    if (!context.mounted) return;

    if (uploadedItem != null) {
      galleryProvider.addUploadedItem(uploadedItem);
      _titleController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FirebaseConfig.isReady
                ? 'Image uploaded to Firebase! Check the Image tab.'
                : 'Image saved! (Configure firebase_options.dart for cloud sync)',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(homeProvider.errorMessage ?? 'Upload failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final cardWidth = Responsive.value<double>(
      context,
      mobile: Responsive.wp(context, 92),
      tablet: Responsive.wp(context, 65),
      desktop: Responsive.wp(context, 45),
    );
    final previewHeight = Responsive.value<double>(
      context,
      mobile: Responsive.hp(context, 28),
      tablet: Responsive.hp(context, 34),
      desktop: Responsive.hp(context, 38),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Image'),
      ),
      body: SingleChildScrollView(
        padding: Responsive.screenPadding(context),
        child: Center(
          child: SizedBox(
            width: cardWidth,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.wp(context, 5),
                  vertical: Responsive.hp(context, 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: previewHeight,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: homeProvider.pickedBytes != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(
                                  homeProvider.pickedBytes!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                    child: Icon(Icons.image_outlined, size: 48),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton.filledTonal(
                                    onPressed: homeProvider.isUploading
                                        ? null
                                        : homeProvider.clearSelectedImage,
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Remove selected image',
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: Responsive.value<double>(
                                    context,
                                    mobile: 56,
                                    tablet: 72,
                                    desktop: 84,
                                  ),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Pick an image from Gallery or Camera',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    if (homeProvider.errorMessage != null) ...[
                      Text(
                        homeProvider.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: homeProvider.isUploading
                                ? null
                                : () => homeProvider.pickImage(
                                      ImageSource.gallery,
                                    ),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: homeProvider.isUploading
                                ? null
                                : () => homeProvider.pickImage(
                                      ImageSource.camera,
                                    ),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Camera'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      enabled: !homeProvider.isUploading,
                      decoration: InputDecoration(
                        labelText: 'Image Caption / Title (optional)',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: (homeProvider.pickedBytes == null ||
                              homeProvider.isUploading)
                          ? null
                          : () => _handleUpload(context),
                      icon: homeProvider.isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(
                        homeProvider.isUploading
                            ? 'Uploading...'
                            : 'Upload Image',
                      ),
                    ),
                    if (homeProvider.lastUploadedUrl != null &&
                        homeProvider.lastUploadedUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last Uploaded Cloudinary URL:',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              homeProvider.lastUploadedUrl!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

