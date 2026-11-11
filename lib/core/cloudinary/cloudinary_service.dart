import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'cloudinary_config.dart';

class CloudinaryService {
  final http.Client _client;

  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  /// Uploads image [bytes] to Cloudinary (`duoajyqfd`) using signed upload
  /// (`api_key`, `timestamp`, `folder`, and SHA-1 `signature`) and returns
  /// the uploaded image's `secure_url` as a [String].
  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception('Cloudinary is not configured in CloudinaryConfig.');
    }

    final request = http.MultipartRequest('POST', CloudinaryConfig.uploadUri)
      ..fields['folder'] = CloudinaryConfig.folder;

    if (CloudinaryConfig.apiSecret.isNotEmpty) {
      final timestamp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      // Cloudinary signature parameters must be sorted alphabetically: folder, timestamp
      final stringToSign =
          'folder=${CloudinaryConfig.folder}&timestamp=$timestamp${CloudinaryConfig.apiSecret}';
      final signature = sha1Hex(utf8.encode(stringToSign));

      request.fields['api_key'] = CloudinaryConfig.apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
    } else {
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = data['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('Cloudinary response did not contain a secure_url.');
      }
      if (kDebugMode) {
        debugPrint('Cloudinary upload success: $secureUrl');
      }
      return secureUrl;
    } else {
      if (kDebugMode) {
        debugPrint(
          'Cloudinary upload error (${response.statusCode}): ${response.body}',
        );
      }
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  static int _rotl32(int val, int shift) {
    final v = val & 0xffffffff;
    return (((v << shift) & 0xffffffff) | (v >> (32 - shift))) & 0xffffffff;
  }

  /// Pure Dart SHA-1 implementation for generating Cloudinary request signatures.
  static String sha1Hex(List<int> message) {
    final msgLen = message.length;
    final bitLen = msgLen * 8;
    final padded = List<int>.from(message)..add(0x80);
    while ((padded.length % 64) != 56) {
      padded.add(0x00);
    }
    for (var i = 7; i >= 0; i--) {
      padded.add((bitLen >> (i * 8)) & 0xff);
    }

    var h0 = 0x67452301;
    var h1 = 0xEFCDAB89;
    var h2 = 0x98BADCFE;
    var h3 = 0x10325476;
    var h4 = 0xC3D2E1F0;

    final w = List<int>.filled(80, 0);

    for (var chunkStart = 0; chunkStart < padded.length; chunkStart += 64) {
      for (var i = 0; i < 16; i++) {
        final j = chunkStart + i * 4;
        w[i] = ((padded[j] & 0xff) << 24) |
            ((padded[j + 1] & 0xff) << 16) |
            ((padded[j + 2] & 0xff) << 8) |
            (padded[j + 3] & 0xff);
      }
      for (var i = 16; i < 80; i++) {
        final n = w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16];
        w[i] = _rotl32(n, 1);
      }

      var a = h0;
      var b = h1;
      var c = h2;
      var d = h3;
      var e = h4;

      for (var i = 0; i < 80; i++) {
        int f;
        int k;
        if (i < 20) {
          f = (b & c) | ((~b & 0xffffffff) & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }

        final temp = (_rotl32(a, 5) + f + e + k + w[i]) & 0xffffffff;
        e = d;
        d = c;
        c = _rotl32(b, 30);
        b = a;
        a = temp;
      }

      h0 = (h0 + a) & 0xffffffff;
      h1 = (h1 + b) & 0xffffffff;
      h2 = (h2 + c) & 0xffffffff;
      h3 = (h3 + d) & 0xffffffff;
      h4 = (h4 + e) & 0xffffffff;
    }

    String hex32(int v) => v.toRadixString(16).padLeft(8, '0');
    return '${hex32(h0)}${hex32(h1)}${hex32(h2)}${hex32(h3)}${hex32(h4)}';
  }
}
