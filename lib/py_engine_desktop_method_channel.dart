import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'py_engine_desktop_platform_interface.dart';

/// An implementation of [PyEngineDesktopPlatform] that uses method channels.
class MethodChannelPyEngineDesktop extends PyEngineDesktopPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('py_engine_desktop');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
