import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/platform/picker_keep_alive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('loki/picker_keep_alive');
  late List<String> calls;

  setUp(() {
    calls = [];
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('starts the service before the pick and stops it after', () async {
    final result = await whileKeepingAppAlive(() async {
      expect(calls, ['start']);
      return 'picked';
    });
    expect(result, 'picked');
    expect(calls, ['start', 'stop']);
  });

  test('stops the service when the pick throws', () async {
    await expectLater(
      whileKeepingAppAlive<void>(() async => throw StateError('denied')),
      throwsStateError,
    );
    expect(calls, ['start', 'stop']);
  });

  test('a rejected second pick does not stop the service early', () async {
    final first = whileKeepingAppAlive(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await expectLater(
      whileKeepingAppAlive<void>(() async => throw StateError('already_active')),
      throwsStateError,
    );
    expect(calls, ['start']);
    await first;
    expect(calls, ['start', 'stop']);
  });

  test('a missing native channel does not block the pick', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    expect(await whileKeepingAppAlive(() async => 1), 1);
  });

  test('does nothing native off Android', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await whileKeepingAppAlive(() async {});
    expect(calls, isEmpty);
  });
}
