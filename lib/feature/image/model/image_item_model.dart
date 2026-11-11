import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageItemModel {
  final String id;
  final String title;
  final String? imageUrl;
  final String? storagePath;
  final Uint8List? bytes;
  final DateTime createdAt;

  const ImageItemModel({
    required this.id,
    required this.title,
    this.imageUrl,
    this.storagePath,
    this.bytes,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ImageItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    final timestamp = data['createdAt'];
    DateTime created = DateTime.now();
    if (timestamp is Timestamp) {
      created = timestamp.toDate();
    }

    return ImageItemModel(
      id: doc.id,
      title: (data['title'] as String?) ?? 'Untitled Image',
      imageUrl: data['imageUrl'] as String?,
      storagePath: data['storagePath'] as String?,
      createdAt: created,
    );
  }
}
