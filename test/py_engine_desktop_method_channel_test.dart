import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:py_engine_desktop/py_engine_desktop_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelPyEngineDesktop platform = MethodChannelPyEngineDesktop();
  const MethodChannel channel = MethodChannel('py_engine_desktop');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
