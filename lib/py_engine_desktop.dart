

export 'src/python_script.dart';
export 'src/python_repl.dart';
export 'src/python_engine.dart';

import 'src/python_engine.dart';
import 'src/python_script.dart';
import 'src/python_repl.dart';

class PyEngineDesktop {
  static final PythonEngine _engine = PythonEngine.instance;
  
  static Future<void> init() => _engine.init();
  
  static Future<PythonScript> startScript(String path) => _engine.startScript(path);
  
  static Future<void> stopScript(PythonScript script) => _engine.stopScript(script);
  
  static Future<PythonRepl> startRepl() => _engine.startRepl();
  
  static Future<void> stopRepl(PythonRepl repl) => _engine.stopRepl(repl);
  
  static Future<void> pipInstall(String package) => _engine.pipInstall(package);
  
  static Future<void> pipUninstall(String package) => _engine.pipUninstall(package);
  
  static String get pythonPath => _engine.pythonPath;
}
