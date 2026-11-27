import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

const _channel = MethodChannel('loki/picker_keep_alive');

/// Picks in flight. A double-tap can start a second pick that file_picker
/// rejects at once; the service must stay up until the last pick ends.
int _activePicks = 0;

/// Runs [pick] (a system file picker) while an Android foreground service
/// keeps the app alive.
///
/// A loaded model holds gigabytes of native memory. With the picker in
/// front, Android's low-memory killer kills the app first, so the app
/// restarted from scratch and the picked file was lost. See
/// `PickerKeepAliveService.kt`. Anywhere else this just runs [pick].
Future<T> whileKeepingAppAlive<T>(Future<T> Function() pick) async {
  if (defaultTargetPlatform != TargetPlatform.android) return pick();
  if (_activePicks++ == 0) await _invoke('start');
  try {
    return await pick();
  } finally {
    if (--_activePicks == 0) await _invoke('stop');
  }
}

/// A failed call never blocks the pick: without the service the picker
/// still works, the app is just killable again.
Future<void> _invoke(String method) async {
  try {
    await _channel.invokeMethod<void>(method);
  } on Exception catch (e) {
    AppLogger.instance.warn('PickerKeepAlive', '$method failed: $e');
  }
}
