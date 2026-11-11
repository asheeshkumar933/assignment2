# Assignment 2 — Flutter Image Upload & Gallery App (Cloudinary + Firebase)

A responsive Flutter application built with **GoRouter**, **Provider**, **Image Picker**, **Cloudinary**, and **Firebase Cloud Firestore**. Users can pick images from the device **Gallery** or **Camera**, upload them to **Cloudinary** (returning a secure `String` URL), store the image URL and metadata in **Firebase Cloud Firestore**, and view or manage all uploaded images in a responsive gallery.

---

## Features

- **Two-Tab Bottom Navigation Bar (`GoRouter`)**:
  - **Upload Tab (`/upload`)**: Pick an image from Gallery or Camera, preview the selected image, add an optional caption/title, upload to Cloudinary + Firestore, and view the returned Cloudinary URL.
  - **Image Tab (`/image`)**: Automatically fetches uploaded images from Cloud Firestore using `.get()` when visiting the tab (with real-time `Stream` code also included in comments for future use), displays them in a responsive grid, supports full-screen interactive zoom preview, and allows deleting images.
- **Cloudinary Signed Upload Service**:
  - Uploads image bytes via `MultipartRequest` with SHA-1 request signing (`api_key`, `timestamp`, `folder`, `signature`) and returns the uploaded `secure_url` as a `String`.
- **Firebase Cloud Firestore Integration**:
  - Stores image metadata (`title`, `imageUrl`, `createdAt`) in the `images` collection on Firebase (`wows-app-1`).
- **State Management with `Provider`**:
  - `HomeProvider` manages image picking, preview bytes, upload progress, and the last uploaded URL.
  - `ImageGalleryProvider` manages fetching, adding, and deleting gallery items with `Consumer<ImageGalleryProvider>`.
- **Responsive Design (`MediaQuery`)**:
  - Custom `Responsive` utility in `lib/utils/responsive.dart` adapts layout widths, heights, grid columns (`2` on mobile, `3` on tablet, `4` on desktop), and screen padding across devices.

---

## Tech Stack & Packages

| Package | Purpose |
| :--- | :--- |
| [`go_router`](https://pub.dev/packages/go_router) | Declarative routing with `StatefulShellRoute.indexedStack` for bottom navigation |
| [`provider`](https://pub.dev/packages/provider) | State management (`HomeProvider`, `ImageGalleryProvider`) |
| [`image_picker`](https://pub.dev/packages/image_picker) | Picking images from Gallery or Camera |
| [`http`](https://pub.dev/packages/http) | Uploading multipart image files to the Cloudinary REST API |
| [`firebase_core`](https://pub.dev/packages/firebase_core) | Firebase initialization (`DefaultFirebaseOptions`) |
| [`cloud_firestore`](https://pub.dev/packages/cloud_firestore) | Storing and retrieving uploaded image URLs and metadata |
| [`firebase_storage`](https://pub.dev/packages/firebase_storage) | Firebase Storage integration support |

---

## Folder Structure

```text
lib/
├── core/
│   ├── cloudinary/
│   │   ├── cloudinary_config.dart              # Cloudinary credentials & endpoint config
│   │   └── cloudinary_service.dart             # Signed image upload to Cloudinary -> returns String URL
│   ├── firebase/
│   │   ├── firebase_config/
│   │   │   ├── firebase_config.dart            # Firebase initialization & Firestore collection reference
│   │   │   └── firebase_options.dart           # FlutterFire DefaultFirebaseOptions
│   │   └── firebase_uploading_service/
│   │       └── firebase_uploading_service.dart # Saves Cloudinary String URL & metadata in Firestore
│   ├── router/
│   │   └── app_router.dart                     # GoRouter configuration for /upload and /image tabs
│   └── theme/
│       └── app_theme.dart                      # Material 3 application theme
├── utils/
│   └── responsive.dart                         # MediaQuery responsive helper (mobile, tablet, desktop)
├── feature/
│   ├── home/
│   │   ├── provider/
│   │   │   └── home_provider.dart              # State management for picking & uploading images
│   │   ├── screen/
│   │   │   ├── home_screen.dart                # Upload tab UI
│   │   │   └── main_shell_screen.dart          # Bottom NavigationBar shell (Upload & Image tabs)
│   │   └── service/
│   │       └── home_upload_service.dart        # Coordinates Cloudinary upload + Firestore storage
│   └── image/
│       ├── model/
│       │   └── image_item_model.dart           # Data model & Firestore serialization
│       ├── provider/
│       │   └── image_gallery_provider.dart     # State management for the image gallery list
│       ├── screen/
│       │   └── image_screen.dart               # Image gallery grid & full-screen preview dialog
│       └── service/
│           └── image_firebase_service.dart     # Fetches (.get) and deletes images from Firestore
└── main.dart                                   # App entry point, Firebase init, and MultiProvider setup
```

---

## Architecture & Upload Flow

1. **Pick Image**: User selects **Gallery** or **Camera** on `HomeScreen` -> `HomeProvider.pickImage()` reads the image bytes for preview.
2. **Upload to Cloudinary**: Tapping **Upload Image** calls `HomeProvider.uploadSelectedImage()` -> `HomeUploadService.uploadPickedImage()` -> `CloudinaryService.uploadImage()`, which uploads the image to Cloudinary and returns the `String` `secure_url`.
3. **Store in Cloud Firestore**: `FirebaseUploadingService.uploadImageUrlToFirestore()` writes `{ title, imageUrl, createdAt }` to the `images` collection in Cloud Firestore.
4. **Display in Image Section**: Switching to the **Image** tab triggers `ImageGalleryProvider.loadImages()` -> `ImageFirebaseService.getImagesFromFirebase()`, rendering the images and URLs inside `ImageScreen` via `Consumer<ImageGalleryProvider>`.

---

## Getting Started

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configuration
- **Cloudinary**: Configured in `lib/core/cloudinary/cloudinary_config.dart` (`cloudName`, `apiKey`, `apiSecret`, `folder`).
- **Firebase**: Configured in `lib/core/firebase/firebase_config/firebase_options.dart` and initialized in `lib/core/firebase/firebase_config/firebase_config.dart`.

### 3. Run the Application
```bash
flutter run
```

### 4. Run Static Analysis & Tests
```bash
flutter analyze
flutter test
```
