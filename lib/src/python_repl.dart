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
    // Determine site-packages directory based on Python path structure
    String sitePackagesDir;
    final pythonDir = Directory(path.dirname(pythonPath));
    
    // Check if this is a virtual environment (has pyvenv.cfg)
    final parentDir = pythonDir.parent;
    final pyvenvCfg = File(path.join(parentDir.path, 'pyvenv.cfg'));
    
    if (await pyvenvCfg.exists()) {
      // This is a virtual environment
      if (Platform.isWindows) {
        sitePackagesDir = path.join(parentDir.path, 'Lib', 'site-packages');
      } else {
        // Unix-like: look for python version directory in lib
        final libDir = Directory(path.join(parentDir.path, 'lib'));
        if (await libDir.exists()) {
          final pythonDirs = await libDir.list()
              .where((entity) => entity is Directory && path.basename(entity.path).startsWith('python'))
              .toList();
          if (pythonDirs.isNotEmpty) {
            sitePackagesDir = path.join(pythonDirs.first.path, 'site-packages');
          } else {
            sitePackagesDir = path.join(parentDir.path, 'lib', 'python3.11', 'site-packages');
          }
        } else {
          sitePackagesDir = path.join(parentDir.path, 'lib', 'python3.11', 'site-packages');
        }
      }
    } else {
      // This is base Python installation
      sitePackagesDir = path.join(pythonDir.path, 'Lib', 'site-packages');
    }
    
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