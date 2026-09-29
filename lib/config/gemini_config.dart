import 'gemini_config_local.dart' as local;

/// Gemini API key configuration.
///
/// THIS IS NOT SUITABLE FOR A PUBLIC PRODUCTION APPLICATION.
/// API keys in a compiled client can be extracted.
///
/// Values are resolved in this order:
/// 1. --dart-define=GEMINI_API_KEY (preferred)
/// 2. lib/config/gemini_config_local.dart (gitignored local fallback)
///
/// Do not put the key in UI files or commit it to Git.
class GeminiConfig {
  GeminiConfig._();

  static const String _apiKeyEnv = String.fromEnvironment('GEMINI_API_KEY');

  static String get apiKey =>
      _apiKeyEnv.isNotEmpty ? _apiKeyEnv : local.GeminiConfigLocal.apiKey;

  static bool get isConfigured {
    final key = apiKey.trim();
    return key.isNotEmpty && key != 'YOUR_GEMINI_API_KEY';
  }
}
