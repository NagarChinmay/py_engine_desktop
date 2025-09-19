import 'dart:io';
import 'dart:async';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'python_script.dart';
import 'python_repl.dart';
import 'python_venv.dart';
import 'virtual_environment.dart';
import 'requirements_manager.dart';

class PythonEngine {
  static PythonEngine? _instance;
  static PythonEngine get instance => _instance ??= PythonEngine._();
  
  PythonEngine._();
  
  String? _pythonPath;
  bool _initialized = false;
  PythonVenv? _venvManager;
  
  Future<void> init() async {
    if (_initialized) return;
    
    if (Platform.isAndroid || Platform.isIOS) {
      throw UnsupportedError('Python engine is only supported on desktop platforms');
    }
    
    final String assetName;
    final String pythonExecutable;
    
    if (Platform.isWindows) {
      assetName = 'python-windows.zip';
      pythonExecutable = 'python.exe';
    } else if (Platform.isMacOS) {
      assetName = 'python-macos.zip';
      pythonExecutable = 'bin/python3.11';  // Use the actual executable, not the symlink
    } else if (Platform.isLinux) {
      assetName = 'python-linux.zip';
      pythonExecutable = 'bin/python3.11';  // Use the actual executable, not the symlink
    } else {
      throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
    }
    
    final appSupportDir = await getApplicationSupportDirectory();
    final pythonDir = Directory(path.join(appSupportDir.path, 'py_engine_desktop', 'python'));
    final pythonExecutablePath = path.join(pythonDir.path, pythonExecutable);
    
    // Check if we need to re-extract for code signing
    final execFile = File(pythonExecutablePath);
    final shouldExtract = !await execFile.exists() || 
                         (await execFile.exists() && (await execFile.stat()).size == 0);
    
    // Also re-extract if Python executable exists but is not signed
    bool needsSigning = false;
    if (Platform.isMacOS && await execFile.exists()) {
      try {
        final codesignResult = await Process.run('codesign', ['-dv', execFile.path]);
        needsSigning = codesignResult.stderr.toString().contains('not signed at all');
      } catch (e) {
        needsSigning = true; // Assume needs signing if we can't check
      }
    }
    
    if (shouldExtract || needsSigning) {
      print('Extracting Python runtime${needsSigning ? ' (applying code signing)' : ''}...');
      if (await pythonDir.exists()) {
        await pythonDir.delete(recursive: true);
      }
      await _extractPythonRuntime(assetName, pythonDir);
    }
    
    _pythonPath = pythonExecutablePath;
    _venvManager = PythonVenv(_pythonPath!);
    _initialized = true;
  }
  
  Future<void> _extractPythonRuntime(String assetName, Directory pythonDir) async {
    final byteData = await rootBundle.load('packages/py_engine_desktop/assets/$assetName');
    final bytes = byteData.buffer.asUint8List();
    
    Archive archive;
    // Detect file format by checking magic bytes instead of filename
    if (bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04) {
      // ZIP magic signature: PK\x03\x04
      archive = ZipDecoder().decodeBytes(bytes);
    } else if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
      // GZIP magic signature: \x1F\x8B
      archive = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes));
    } else {
      throw Exception('Unsupported archive format for $assetName');
    }
    
    await pythonDir.create(recursive: true);
    
    for (final file in archive) {
      final filename = file.name;
      // Strip leading "python/" from paths to avoid double nesting
      final relativePath = filename.startsWith('python/') ? filename.substring(7) : filename;
      
      if (file.isFile) {
        final data = file.content as List<int>?;
        final outputFile = File(path.join(pythonDir.path, relativePath));
        
        if (relativePath.contains('python') && relativePath.contains('bin/')) {
          print('Extracting Python executable: $relativePath, data length: ${data?.length ?? 0}');
        }
        
        await outputFile.create(recursive: true);
        
        if (data != null && data.isNotEmpty) {
          await outputFile.writeAsBytes(data);
        } else {
          print('WARNING: Empty file content for $relativePath');
        }
        
        if (relativePath.contains('python') && (relativePath.contains('bin/') || relativePath.endsWith('.exe'))) {
          if (!Platform.isWindows) {
            // Make executable
            await Process.run('chmod', ['+x', outputFile.path]);
            
            // Remove macOS quarantine attribute and sign the binary
            if (Platform.isMacOS) {
              try {
                await Process.run('xattr', ['-d', 'com.apple.quarantine', outputFile.path]);
                print('Removed quarantine attribute from ${relativePath}');
              } catch (e) {
                print('Could not remove quarantine (may not exist): $e');
              }
              
              // Ad-hoc code signing to satisfy macOS security requirements
              try {
                await Process.run('codesign', ['-s', '-', '--force', '--deep', outputFile.path]);
                print('Ad-hoc signed ${relativePath}');
              } catch (e) {
                print('Could not sign binary (may not have codesign): $e');
              }
            }
          }
        }
      } else {
        final dir = Directory(path.join(pythonDir.path, relativePath));
        await dir.create(recursive: true);
      }
    }
  }
  
  String get pythonPath {
    if (!_initialized || _pythonPath == null) {
      throw StateError('Python engine not initialized. Call init() first.');
    }
    return _pythonPath!;
  }
  
  Future<PythonScript> startScript(String scriptPath) async {
    if (!_initialized) {
      throw StateError('Python engine not initialized. Call init() first.');
    }
    
    if (!await File(scriptPath).exists()) {
      throw ArgumentError('Script file does not exist: $scriptPath');
    }
    
    // Use current Python path (venv or base)
    final currentPythonPath = _venvManager?.getCurrentPythonPath() ?? _pythonPath!;
    return PythonScript.start(currentPythonPath, scriptPath);
  }
  
  Future<void> stopScript(PythonScript script) async {
    script.stop();
  }
  
  Future<PythonRepl> startRepl() async {
    if (!_initialized) {
      throw StateError('Python engine not initialized. Call init() first.');
    }
    
    // Use current Python path (venv or base)
    final currentPythonPath = _venvManager?.getCurrentPythonPath() ?? _pythonPath!;
    return PythonRepl.start(currentPythonPath);
  }
  
  Future<void> stopRepl(PythonRepl repl) async {
    repl.stop();
  }
  
  Future<void> pipInstall(String packageName) async {
    if (!_initialized) {
      throw StateError('Python engine not initialized. Call init() first.');
    }
    
    // First try to ensure pip is available
    await _ensurePip();
    
    // Use Python directly and modify sys.path only within the process
    final pythonDir = Directory(path.dirname(_pythonPath!));
    final sitePackagesDir = path.join(pythonDir.path, 'Lib', 'site-packages');
    
    final result = await Process.run(
      _pythonPath!, 
      ['-c', 'import sys; sys.path.insert(0, r"$sitePackagesDir"); import pip._internal.cli.main; pip._internal.cli.main.main(["install", "$packageName"])'],
      runInShell: true
    );
    
    if (result.exitCode != 0) {
      throw Exception('Failed to install package $packageName: ${result.stderr}');
    }
  }
  
  Future<void> pipUninstall(String packageName) async {
    if (!_initialized) {
      throw StateError('Python engine not initialized. Call init() first.');
    }
    
    // First try to ensure pip is available
    await _ensurePip();
    
    // Use Python directly and modify sys.path only within the process
    final pythonDir = Directory(path.dirname(_pythonPath!));
    final sitePackagesDir = path.join(pythonDir.path, 'Lib', 'site-packages');
    
    final result = await Process.run(
      _pythonPath!, 
      ['-c', 'import sys; sys.path.insert(0, r"$sitePackagesDir"); import pip._internal.cli.main; pip._internal.cli.main.main(["uninstall", "$packageName", "-y"])'],
      runInShell: true
    );
    
    if (result.exitCode != 0) {
      throw Exception('Failed to uninstall package $packageName: ${result.stderr}');
    }
  }
  
  Future<void> _ensurePip() async {
    // Check if pip.exe already exists
    final pythonDir = Directory(path.dirname(_pythonPath!));
    final pipExe = File(path.join(pythonDir.path, 'Scripts', 'pip.exe'));
    
    if (await pipExe.exists()) {
      return; // pip is already available
    }
    
    // Download and install pip manually since ensurepip is not available
    await _downloadAndInstallPip();
  }
  
  Future<void> _downloadAndInstallPip() async {
    final pythonDir = Directory(path.dirname(_pythonPath!));
    final getpipPath = path.join(pythonDir.path, 'get-pip.py');
    
    // Download get-pip.py
    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse('https://bootstrap.pypa.io/get-pip.py'));
      final response = await request.close();
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download get-pip.py: HTTP ${response.statusCode}');
      }
      
      final getpipFile = File(getpipPath);
      final sink = getpipFile.openWrite();
      await response.pipe(sink);
      await sink.close();
      
      // Run get-pip.py to install pip directly into the embedded Python
      final installResult = await Process.run(
        _pythonPath!, 
        [getpipPath, '--force-reinstall'],
        runInShell: true
      );
      
      print('get-pip.py stdout: ${installResult.stdout}');
      print('get-pip.py stderr: ${installResult.stderr}');
      print('get-pip.py exit code: ${installResult.exitCode}');
      
      if (installResult.exitCode != 0) {
        throw Exception('Failed to install pip: ${installResult.stderr}');
      }
      
      // Clean up
      if (await getpipFile.exists()) {
        await getpipFile.delete();
      }
      
      // Check Python's sys.path and site-packages
      final sysPathResult = await Process.run(_pythonPath!, ['-c', 'import sys; print("\\n".join(sys.path))']);
      print('Python sys.path: ${sysPathResult.stdout}');
      
      // Check if site-packages exists and what's in it
      final pythonDir = Directory(path.dirname(_pythonPath!));
      final sitePackagesDir = Directory(path.join(pythonDir.path, 'Lib', 'site-packages'));
      print('Site-packages path: ${sitePackagesDir.path}');
      print('Site-packages exists: ${await sitePackagesDir.exists()}');
      
      if (await sitePackagesDir.exists()) {
        final contents = await sitePackagesDir.list().toList();
        print('Site-packages contents: ${contents.map((e) => path.basename(e.path)).join(", ")}');
      }
      
      // Try alternative verification using the Scripts directory
      final scriptsDir = Directory(path.join(pythonDir.path, 'Scripts'));
      final pipExe = File(path.join(scriptsDir.path, 'pip.exe'));
      print('pip.exe exists: ${await pipExe.exists()}');
      
      // Try running pip directly from Scripts
      if (await pipExe.exists()) {
        final directPipResult = await Process.run(pipExe.path, ['--version']);
        print('Direct pip stdout: ${directPipResult.stdout}');
        print('Direct pip stderr: ${directPipResult.stderr}');
        print('Direct pip exit code: ${directPipResult.exitCode}');
      }
      
      // Verify pip installation
      final verifyResult = await Process.run(_pythonPath!, ['-m', 'pip', '--version']);
      print('pip verification stdout: ${verifyResult.stdout}');
      print('pip verification stderr: ${verifyResult.stderr}');
      print('pip verification exit code: ${verifyResult.exitCode}');
      
    } finally {
      httpClient.close();
    }
  }

  // Virtual Environment Management Methods

  /// Creates a new virtual environment at the specified path
  Future<VirtualEnvironment> createVirtualEnvironment(String venvPath, {String? name}) async {
    if (!_initialized || _venvManager == null) {
      throw StateError('Python engine not initialized. Call init() first.');
    }
    return await _venvManager!.createVenv(venvPath, name: name);
  }

  /// Activates a virtual environment
  Future<void> activateVirtualEnvironment(String venvPath) async {
    if (!_initialized || _venvManager == null) {
      throw StateError('Python engine not initialized. Call init() first.');
    }
    await _venvManager!.activateVenv(venvPath);
  }

  /// Deactivates the current virtual environment
  void deactivateVirtualEnvironment() {
    if (_venvManager != null) {
      _venvManager!.deactivateVenv();
    }
  }

  /// Lists all virtual environments in a directory
  Future<List<VirtualEnvironment>> listVirtualEnvironments(String searchPath) async {
    if (!_initialized || _venvManager == null) {
      throw StateError('Python engine not initialized. Call init() first.');
    }
    return await _venvManager!.listVirtualEnvironments(searchPath);
  }

  /// Deletes a virtual environment
  Future<void> deleteVirtualEnvironment(String venvPath) async {
    if (!_initialized || _venvManager == null) {
      throw StateError('Python engine not initialized. Call init() first.');
    }
    await _venvManager!.deleteVenv(venvPath);
  }

  /// Gets the currently active virtual environment
  VirtualEnvironment? get activeVirtualEnvironment => _venvManager?.activeVenv;

  /// Installs packages from requirements specification
  Future<void> installRequirements(RequirementsSpec requirements) async {
    if (!_initialized || _venvManager == null) {
      throw StateError('Python engine not initialized. Call init() first.');
    }
    await _venvManager!.installRequirements(requirements);
  }

  /// Installs packages from requirements JSON string
  Future<void> installRequirementsFromJson(String requirementsJson) async {
    final requirements = RequirementsManager.parseJson(requirementsJson);
    await installRequirements(requirements);
  }

  /// Installs packages from a requirements file
  Future<void> installRequirementsFromFile(String filePath) async {
    if (!_initialized || _venvManager == null) {
      throw StateError('Python engine not initialized. Call init() first.');
    }
    await _venvManager!.installRequirementsFromFile(filePath);
  }

  /// Exports current environment's installed packages as requirements
  Future<RequirementsSpec> exportRequirements({String? name, String? description}) async {
    if (!_initialized || _venvManager == null) {
      throw StateError('Python engine not initialized. Call init() first.');
    }
    return await _venvManager!.exportRequirements(name: name, description: description);
  }

  /// Gets detailed information about the current environment
  Map<String, dynamic> getCurrentEnvironmentInfo() {
    if (!_initialized || _venvManager == null) {
      return {
        'type': 'uninitialized',
        'isActive': false,
      };
    }
    return _venvManager!.getCurrentEnvironmentInfo();
  }

  /// Checks if a virtual environment exists and is valid
  Future<bool> isValidVirtualEnvironment(String venvPath) async {
    if (!_initialized || _venvManager == null) {
      return false;
    }
    return await _venvManager!.isValidVenv(venvPath);
  }

  /// Upgrades pip in the active virtual environment
  Future<void> upgradePip() async {
    if (!_initialized || _venvManager == null) {
      throw StateError('Python engine not initialized. Call init() first.');
    }
    await _venvManager!.upgradePip();
  }

  /// Clears the pip cache for the active environment
  Future<void> clearPipCache() async {
    if (!_initialized || _venvManager == null) {
      throw StateError('Python engine not initialized. Call init() first.');
    }
    await _venvManager!.clearPipCache();
  }
}