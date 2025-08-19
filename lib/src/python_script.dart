import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as path;

class PythonScript {
  final Process _process;
  final StreamController<String> _stdoutController = StreamController<String>();
  final StreamController<String> _stderrController = StreamController<String>();
  
  PythonScript._(this._process) {
    _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _stdoutController.add(line);
    });
    
    _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _stderrController.add(line);
    });
  }
  
  static Future<PythonScript> start(String pythonPath, String scriptPath) async {
    // Add site-packages to sys.path so installed packages are available in scripts
    final pythonDir = Directory(path.dirname(pythonPath));
    final sitePackagesDir = path.join(pythonDir.path, 'Lib', 'site-packages');
    
    final process = await Process.start(pythonPath, [
      '-c', 
      'import sys; sys.path.insert(0, r"$sitePackagesDir"); exec(open(r"$scriptPath").read())'
    ]);
    return PythonScript._(process);
  }
  
  Stream<String> get stdout => _stdoutController.stream;
  Stream<String> get stderr => _stderrController.stream;
  
  Process get process => _process;
  
  Future<int> get exitCode => _process.exitCode;
  
  void stop() {
    _process.kill();
    _stdoutController.close();
    _stderrController.close();
  }
}