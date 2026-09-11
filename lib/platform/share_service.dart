import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Result sharing. Uses the native Android share sheet (share_plus), the Web
/// Share API on web, and the clipboard as a last-resort fallback.
class ShareService {
  ShareService._();

  static Future<bool> shareResult(String message) async {
    try {
      await Share.share(message, subject: 'QUEENS');
      return true;
    } catch (_) {
      // Sharing unavailable — copy to clipboard instead.
      try {
        await Clipboard.setData(ClipboardData(text: message));
      } catch (_) {}
      return false;
    }
  }

  /// Builds the compact share text for a completed game.
  static String buildResultText({
    required String modeLabel,
    required int size,
    required String difficultyLabel,
    required String time,
    required int mistakes,
    required int hints,
  }) {
    final buffer = StringBuffer()
      ..writeln('QUEENS')
      ..writeln(modeLabel)
      ..writeln('$size×$size • $difficultyLabel')
      ..writeln(time)
      ..writeln('$mistakes mistake${mistakes == 1 ? '' : 's'}')
      ..write('$hints hint${hints == 1 ? '' : 's'}');
    return buffer.toString();
  }
}