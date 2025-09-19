import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'virtual_environment.dart';
import 'requirements_manager.dart';

/// Manages Python virtual environments creation, activation, and management
class PythonVenv {
  /// The base Python executable path used to create virtual environments
  final String basePythonPath;
  
  /// Currently active virtual environment
  VirtualEnvironment? _activeVenv;
  
  PythonVenv(this.basePythonPath);

  /// Gets the currently active virtual environment
  VirtualEnvironment? get activeVenv => _activeVenv;

  /// Creates a new virtual environment at the specified path
  Future<VirtualEnvironment> createVenv(String venvPath, {String? name}) async {
    final venvDir = Directory(venvPath);
    
    // Check if directory already exists
    if (await venvDir.exists()) {
      final isEmpty = await venvDir.list().isEmpty;
      if (!isEmpty) {
        throw Exception('Directory already exists and is not empty: $venvPath');
      }
    }

    // Ensure parent directory exists
    await venvDir.parent.create(recursive: true);

    print('🐍 Creating virtual environment at: $venvPath');
    print('🐍 Using base Python: $basePythonPath');

    // Create virtual environment using base Python's venv module
    final result = await Process.run(
      basePythonPath,
      ['-m', 'venv', venvPath],
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to create virtual environment: ${result.stderr}');
    }

    print('✅ Virtual environment created successfully');
    print('📋 Output: ${result.stdout}');

    // Verify the virtual environment was created correctly
    final venv = await VirtualEnvironment.fromPath(venvPath);
    if (venv == null || !await venv.isValid()) {
      throw Exception('Virtual environment creation failed - invalid environment');
    }

    // Set executable permissions on Unix systems
    if (!Platform.isWindows) {
      final pythonExe = File(venv.pythonExecutablePath);
      if (await pythonExe.exists()) {
        await Process.run('chmod', ['+x', pythonExe.path]);
      }
    }

    return venv;
  }

  /// Activates a virtual environment
  Future<void> activateVenv(String venvPath) async {
    final venv = await VirtualEnvironment.fromPath(venvPath);
    if (venv == null) {
      throw Exception('Virtual environment not found: $venvPath');
    }

    if (!await venv.isValid()) {
      throw Exception('Invalid virtual environment: $venvPath');
    }

    _activeVenv = venv.copyWith(isActive: true);
    print('✅ Activated virtual environment: ${_activeVenv!.name}');
  }

  /// Deactivates the current virtual environment
  void deactivateVenv() {
    if (_activeVenv != null) {
      print('🔄 Deactivated virtual environment: ${_activeVenv!.name}');
      _activeVenv = null;
    }
  }

  /// Lists all virtual environments in a directory
  Future<List<VirtualEnvironment>> listVirtualEnvironments(String searchPath) async {
    final searchDir = Directory(searchPath);
    if (!await searchDir.exists()) {
      return [];
    }

    final venvs = <VirtualEnvironment>[];
    
    await for (final entity in searchDir.list()) {
      if (entity is Directory) {
        final venv = await VirtualEnvironment.fromPath(
          entity.path,
          isActive: _activeVenv?.path == entity.path,
        );
        if (venv != null && await venv.isValid()) {
          venvs.add(venv);
        }
      }
    }

    return venvs;
  }

  /// Deletes a virtual environment
  Future<void> deleteVenv(String venvPath) async {
    final venvDir = Directory(venvPath);
    if (!await venvDir.exists()) {
      throw Exception('Virtual environment not found: $venvPath');
    }

    // Deactivate if this is the active environment
    if (_activeVenv?.path == venvPath) {
      deactivateVenv();
    }

    print('🗑️ Deleting virtual environment: $venvPath');
    await venvDir.delete(recursive: true);
    print('✅ Virtual environment deleted successfully');
  }

  /// Installs packages from requirements specification in the active environment
  Future<void> installRequirements(RequirementsSpec requirements) async {
    if (_activeVenv == null) {
      throw StateError('No virtual environment is active');
    }

    final pipPath = _activeVenv!.pipExecutablePath;
    
    // Ensure pip exists
    if (!await File(pipPath).exists()) {
      throw Exception('pip not found in virtual environment: ${_activeVenv!.path}');
    }

    print('📦 Installing ${requirements.requirements.length} packages...');

    // Install packages one by one for better error handling
    for (final req in requirements.requirements) {
      print('📦 Installing: ${req.package}${req.version != '*' ? req.version : ''}');
      
      final args = ['install'];
      
      // Add pip options if specified
      if (requirements.pipOptions != null) {
        args.addAll(requirements.pipOptions!);
      }
      
      args.add(req.toPipFormat());

      final result = await Process.run(pipPath, args, runInShell: true);

      if (result.exitCode != 0) {
        print('❌ Failed to install ${req.package}: ${result.stderr}');
        throw Exception('Failed to install package ${req.package}: ${result.stderr}');
      } else {
        print('✅ Successfully installed: ${req.package}');
      }
    }

    print('🎉 All packages installed successfully!');
  }

  /// Installs packages from a requirements file
  Future<void> installRequirementsFromFile(String filePath) async {
    final requirements = await RequirementsManager.loadFromFile(filePath);
    
    // Validate requirements
    final errors = RequirementsManager.validate(requirements);
    if (errors.isNotEmpty) {
      throw Exception('Invalid requirements file:\n${errors.join('\n')}');
    }

    await installRequirements(requirements);
  }

  /// Exports current environment's installed packages as requirements
  Future<RequirementsSpec> exportRequirements({String? name, String? description}) async {
    if (_activeVenv == null) {
      throw StateError('No virtual environment is active');
    }

    final pipPath = _activeVenv!.pipExecutablePath;
    
    // Get list of installed packages using pip freeze
    final result = await Process.run(pipPath, ['freeze'], runInShell: true);
    
    if (result.exitCode != 0) {
      throw Exception('Failed to get installed packages: ${result.stderr}');
    }

    final requirements = <PackageRequirement>[];
    final lines = result.stdout.toString().split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
        final parts = trimmed.split('==');
        if (parts.length == 2) {
          requirements.add(PackageRequirement(
            package: parts[0],
            version: '==${parts[1]}',
          ));
        }
      }
    }

    return RequirementsSpec(
      requirements: requirements,
      pythonVersion: _activeVenv!.pythonVersion,
      name: name ?? _activeVenv!.name,
      description: description ?? 'Exported from ${_activeVenv!.name}',
    );
  }

  /// Gets the current Python executable path (active venv or base Python)
  String getCurrentPythonPath() {
    return _activeVenv?.pythonExecutablePath ?? basePythonPath;
  }

  /// Gets the current site-packages path
  String? getCurrentSitePackagesPath() {
    if (_activeVenv != null) {
      return _activeVenv!.sitePackagesPath;
    }
    
    // Return base Python site-packages
    final pythonDir = Directory(path.dirname(basePythonPath));
    return path.join(pythonDir.path, 'Lib', 'site-packages');
  }

  /// Checks if a virtual environment exists and is valid
  Future<bool> isValidVenv(String venvPath) async {
    final venv = await VirtualEnvironment.fromPath(venvPath);
    return venv != null && await venv.isValid();
  }

  /// Gets detailed information about the current environment
  Map<String, dynamic> getCurrentEnvironmentInfo() {
    if (_activeVenv == null) {
      return {
        'type': 'base',
        'pythonPath': basePythonPath,
        'sitePackagesPath': getCurrentSitePackagesPath(),
        'isActive': false,
      };
    }

    return {
      'type': 'virtual',
      'environment': _activeVenv!.toMap(),
      'pythonPath': _activeVenv!.pythonExecutablePath,
      'sitePackagesPath': _activeVenv!.sitePackagesPath,
      'isActive': true,
    };
  }

  /// Upgrades pip in the active virtual environment
  Future<void> upgradePip() async {
    if (_activeVenv == null) {
      throw StateError('No virtual environment is active');
    }

    final pipPath = _activeVenv!.pipExecutablePath;
    
    print('⬆️ Upgrading pip in virtual environment...');
    final result = await Process.run(
      pipPath, 
      ['install', '--upgrade', 'pip'],
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to upgrade pip: ${result.stderr}');
    }

    print('✅ pip upgraded successfully');
  }

  /// Clears the pip cache for the active environment
  Future<void> clearPipCache() async {
    if (_activeVenv == null) {
      throw StateError('No virtual environment is active');
    }

    final pipPath = _activeVenv!.pipExecutablePath;
    
    print('🧹 Clearing pip cache...');
    final result = await Process.run(
      pipPath, 
      ['cache', 'purge'],
      runInShell: true,
    );

    if (result.exitCode != 0) {
      print('⚠️ Failed to clear pip cache: ${result.stderr}');
    } else {
      print('✅ pip cache cleared successfully');
    }
  }
}