/// Configuration for Cloudinary image uploads.
class CloudinaryConfig {
  static const String cloudName = 'duoajyqfd';
  static const String apiKey = '519164432865784';
  static const String apiSecret = 'BEwamwi_AWHUaTWk3OdSoAGyAiA';

  /// Unsigned upload preset name (only used if [apiSecret] is empty).
  static const String uploadPreset = 'ml_default';

  static const String folder = 'assignment2_uploads';

  static bool get isConfigured =>
      cloudName.isNotEmpty && apiKey.isNotEmpty && apiSecret.isNotEmpty;

  static Uri get uploadUri => Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
}
