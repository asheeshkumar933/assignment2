import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:assignment2/main.dart';
import 'package:assignment2/core/cloudinary/cloudinary_service.dart';
import 'package:assignment2/core/firebase/firebase_config/firebase_options.dart';
import 'package:assignment2/core/firebase/firebase_uploading_service/firebase_uploading_service.dart';
import 'package:assignment2/feature/home/provider/home_provider.dart';
import 'package:assignment2/feature/home/service/home_upload_service.dart';
import 'package:assignment2/feature/image/provider/image_gallery_provider.dart';
import 'package:assignment2/utils/responsive.dart';

/// Valid 1x1 transparent PNG bytes for widget tests.
final Uint8List _kTransparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

class _FakeCloudinaryService extends CloudinaryService {
  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    return 'https://res.cloudinary.com/duoajyqfd/image/upload/v1/$fileName';
  }
}

void main() {
  group('Firebase & Cloudinary Configuration Tests', () {
    test('DefaultFirebaseOptions has valid wows-app-1 configuration', () {
      expect(DefaultFirebaseOptions.android.projectId, 'wows-app-1');
      expect(DefaultFirebaseOptions.ios.projectId, 'wows-app-1');
    });

    test('CloudinaryService.sha1Hex computes standard SHA-1 signature', () {
      expect(
        CloudinaryService.sha1Hex(utf8.encode('abc')),
        'a9993e364706816aba3e25717850c26c9cd0d89d',
      );
    });

    test(
      'HomeUploadService uploads to Cloudinary, gets String URL, and stores via FirebaseUploadingService',
      () async {
        final service = HomeUploadService(
          cloudinaryService: _FakeCloudinaryService(),
          firebaseUploadingService: FirebaseUploadingService(),
        );

        final item = await service.uploadPickedImage(
          bytes: _kTransparentPng,
          fileName: 'sample.png',
          title: 'My Cloudinary Image',
        );

        expect(item.title, 'My Cloudinary Image');
        expect(
          item.imageUrl,
          'https://res.cloudinary.com/duoajyqfd/image/upload/v1/sample.png',
        );
      },
    );
  });

  group('Provider State Management & UI Navigation Tests', () {
    testWidgets(
      'Upload image via HomeProvider and display URL & data in Image tab',
      (WidgetTester tester) async {
        final homeProvider = HomeProvider(
          uploadService: HomeUploadService(
            cloudinaryService: _FakeCloudinaryService(),
            firebaseUploadingService: FirebaseUploadingService(),
          ),
        );
        final galleryProvider = ImageGalleryProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<HomeProvider>.value(value: homeProvider),
              ChangeNotifierProvider<ImageGalleryProvider>.value(
                value: galleryProvider,
              ),
            ],
            child: const MyApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Verify bottom navigation bar tabs exist
        expect(find.text('Upload'), findsOneWidget);
        expect(find.text('Image'), findsOneWidget);

        // Simulate picking an image and uploading via HomeProvider
        homeProvider.setPickedImageBytes(
          _kTransparentPng,
          fileName: 'photo.png',
        );
        await tester.pump();

        final uploadedItem = await homeProvider.uploadSelectedImage(
          title: 'Sunset Photo',
        );
        expect(uploadedItem, isNotNull);
        expect(
          homeProvider.lastUploadedUrl,
          'https://res.cloudinary.com/duoajyqfd/image/upload/v1/photo.png',
        );

        galleryProvider.addUploadedItem(uploadedItem!);
        await tester.pump();

        // Navigate to the Image tab on the bottom navigation bar
        await tester.tap(find.text('Image'));
        await tester.pumpAndSettle();

        // Verify the uploaded image title and Cloudinary URL are displayed in the Image section
        expect(find.text('Sunset Photo'), findsOneWidget);
        expect(
          find.text(
            'https://res.cloudinary.com/duoajyqfd/image/upload/v1/photo.png',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Responsive MediaQuery utility computes breakpoints properly', (
      WidgetTester tester,
    ) async {
      late bool isMobileResult;
      late double widthPercent;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                isMobileResult = Responsive.isMobile(context);
                widthPercent = Responsive.wp(context, 50);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(isMobileResult, isTrue);
      expect(widthPercent, 200.0);
    });
  });
}
