#include "include/py_engine_desktop/py_engine_desktop_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "py_engine_desktop_plugin.h"

void PyEngineDesktopPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  py_engine_desktop::PyEngineDesktopPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
