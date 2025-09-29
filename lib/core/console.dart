import 'package:flutter/foundation.dart';

enum DebugType { error, info, url, response, statusCode, alert }

console(dynamic value, {String tag = '', DebugType type = DebugType.info}) {
  if (kReleaseMode) return;
  switch (type) {
    case DebugType.statusCode:
      debugPrint('\x1B[33m${"💎 STATUS CODE $tag: $value"}\x1B[0m');
      break;

    case DebugType.alert:
      debugPrint('\x1B[95m${"💁‍♂️ Alert $tag: $value"}\x1B[0m');
      break;

    case DebugType.info:
      debugPrint('\x1B[32m${"⚡ INFO $tag: $value"}\x1B[0m');
      break;

    case DebugType.error:
      debugPrint('\x1B[31m${"🚨 ERROR $tag: $value"}\x1B[0m');
      break;

    case DebugType.response:
      debugPrint('\x1B[36m${"💡 RESPONSE $tag: $value"}\x1B[0m');
      break;

    case DebugType.url:
      debugPrint('\x1B[34m${"📌 URL $tag: $value"}\x1B[0m');
      break;
  }
}
