//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <py_engine_desktop/py_engine_desktop_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) py_engine_desktop_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "PyEngineDesktopPlugin");
  py_engine_desktop_plugin_register_with_registrar(py_engine_desktop_registrar);
}
