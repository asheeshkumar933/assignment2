import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/responsive.dart';
import '../model/image_item_model.dart';
import '../provider/image_gallery_provider.dart';

class ImageScreen extends StatelessWidget {
  const ImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = Responsive.value<int>(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );

    final isLoading = context.select<ImageGalleryProvider, bool>(
      (p) => p.isLoading,
    );
    final itemCount = context.select<ImageGalleryProvider, int>(
      (p) => p.uploadedImages.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Images'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ImageGalleryProvider>().loadImages(),
        child: isLoading && itemCount == 0
            ? const Center(child: CircularProgressIndicator())
            : itemCount == 0
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: Padding(
                              padding: Responsive.screenPadding(context),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.photo_library_outlined,
                                    size: Responsive.value<double>(
                                      context,
                                      mobile: 64,
                                      tablet: 80,
                                      desktop: 96,
                                    ),
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No images uploaded yet',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pull down to refresh or go to Upload tab to add an image.',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: Responsive.screenPadding(context),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: itemCount,
                    findChildIndexCallback: (Key key) {
                      if (key is ValueKey<String>) {
                        final images = context
                            .read<ImageGalleryProvider>()
                            .uploadedImages;
                        final index =
                            images.indexWhere((item) => item.id == key.value);
                        return index != -1 ? index : null;
                      }
                      return null;
                    },
                    itemBuilder: (context, index) {
                      final item = context
                          .read<ImageGalleryProvider>()
                          .uploadedImages[index];
                      return _ImageGridCard(
                        key: ValueKey<String>(item.id),
                        item: item,
                        onDelete: () {
                          final currentImages = context
                              .read<ImageGalleryProvider>()
                              .uploadedImages;
                          final currentIdx = currentImages
                              .indexWhere((e) => e.id == item.id);
                          if (currentIdx != -1) {
                            context
                                .read<ImageGalleryProvider>()
                                .removeImageAt(currentIdx);
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _ImageGridCard extends StatefulWidget {
  final ImageItemModel item;
  final VoidCallback onDelete;

  const _ImageGridCard({
    super.key,
    required this.item,
    required this.onDelete,
  });

  @override
  State<_ImageGridCard> createState() => _ImageGridCardState();
}

class _ImageGridCardState extends State<_ImageGridCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _showFullScreenPreview(BuildContext context, ImageItemModel item) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.wp(context, 90),
              maxHeight: Responsive.hp(context, 80),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppBar(
                  title: Text(item.title),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                Flexible(
                  child: InteractiveViewer(
                    child: _buildImageWidget(context, item, BoxFit.contain),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        SelectableText(
                          item.imageUrl!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Uploaded: ${item.createdAt.toLocal()}',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(
    BuildContext context,
    ImageItemModel item,
    BoxFit fit,
  ) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return Image.network(
        item.imageUrl!,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          if (item.bytes != null) {
            return Image.memory(
              item.bytes!,
              fit: fit,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  _brokenImage(context),
            );
          }
          return _brokenImage(context);
        },
      );
    }
    if (item.bytes != null) {
      return Image.memory(
        item.bytes!,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _brokenImage(context),
      );
    }
    return _brokenImage(context);
  }

  Widget _brokenImage(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 36),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final item = widget.item;

    return RepaintBoundary(
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _showFullScreenPreview(context, item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImageWidget(context, item, BoxFit.cover),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IconButton.filledTonal(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                        ),
                        onPressed: widget.onDelete,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      Text(
                        item.imageUrl!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
