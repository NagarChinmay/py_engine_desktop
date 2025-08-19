#ifndef FLUTTER_PLUGIN_PY_ENGINE_DESKTOP_PLUGIN_H_
#define FLUTTER_PLUGIN_PY_ENGINE_DESKTOP_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace py_engine_desktop {

class PyEngineDesktopPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  PyEngineDesktopPlugin();

  virtual ~PyEngineDesktopPlugin();

  // Disallow copy and assign.
  PyEngineDesktopPlugin(const PyEngineDesktopPlugin&) = delete;
  PyEngineDesktopPlugin& operator=(const PyEngineDesktopPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace py_engine_desktop

#endif  // FLUTTER_PLUGIN_PY_ENGINE_DESKTOP_PLUGIN_H_
