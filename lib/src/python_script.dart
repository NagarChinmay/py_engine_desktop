import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as path;

class PythonScript {
  final Process _process;
  final StreamController<String> _stdoutController = StreamController<String>();
  final StreamController<String> _stderrController = StreamController<String>();
  
  PythonScript._(this._process) {
    print('🔧 Setting up Python process streams...');
    
    _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      print('🔧 Raw stdout line: $line');
      _stdoutController.add(line);
    }, onDone: () {
      print('🔧 Stdout stream closed');
    }, onError: (error) {
      print('🔧 Stdout stream error: $error');
    });
    
    _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      print('🔧 Raw stderr line: $line');
      _stderrController.add(line);
    }, onDone: () {
      print('🔧 Stderr stream closed');
    }, onError: (error) {
      print('🔧 Stderr stream error: $error');
    });
    
    print('🔧 Stream listeners set up complete');
  }
  
  static Future<PythonScript> start(String pythonPath, String scriptPath) async {
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
    
    // Debug: Check if Python executable exists and is executable
    final pythonFile = File(pythonPath);
    print('🔧 Python executable path: $pythonPath');
    print('🔧 Python executable exists: ${await pythonFile.exists()}');
    if (await pythonFile.exists()) {
      final stat = await pythonFile.stat();
      print('🔧 Python executable size: ${stat.size} bytes');
      print('🔧 Python executable mode: ${stat.mode.toRadixString(8)}');
    }
    
    // Try direct script execution first, fallback to -c method if needed
    Process process;
    // Use shell execution for macOS/Linux, direct execution for Windows  
    if (Platform.isMacOS || Platform.isLinux) {
      // Execute script via shell with site-packages path
      final command = 'PYTHONPATH="$sitePackagesDir" "$pythonPath" -c \'exec(open("$scriptPath").read())\'';
      process = await Process.start('/bin/sh', ['-c', command]);
    } else {
      // Windows: use original -c method
      process = await Process.start(pythonPath, [
        '-c', 
        'import sys; sys.path.insert(0, r"$sitePackagesDir"); exec(open(r"$scriptPath").read())'
      ]);
    }
    
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