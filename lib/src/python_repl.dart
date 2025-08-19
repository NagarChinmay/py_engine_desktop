import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as path;

class PythonRepl {
  final Process _process;
  final StreamController<String> _outputController = StreamController<String>();
  
  PythonRepl._(this._process) {
    _process.stdout
        .transform(utf8.decoder)
        .listen((data) {
      _outputController.add(data);
    });
    
    _process.stderr
        .transform(utf8.decoder)
        .listen((data) {
      _outputController.add(data);
    });
  }
  
  static Future<PythonRepl> start(String pythonPath) async {
    // Add site-packages to sys.path so installed packages are available
    final pythonDir = Directory(path.dirname(pythonPath));
    final sitePackagesDir = path.join(pythonDir.path, 'Lib', 'site-packages');
    
    final process = await Process.start(pythonPath, [
      '-c', 
      'import sys; sys.path.insert(0, r"$sitePackagesDir"); import code; code.interact()'
    ]);
    return PythonRepl._(process);
  }
  
  Stream<String> get output => _outputController.stream;
  
  Process get process => _process;
  
  void send(String code) {
    _process.stdin.writeln(code);
  }
  
  Future<int> get exitCode => _process.exitCode;
  
  void stop() {
    _process.kill();
    _outputController.close();
  }
}