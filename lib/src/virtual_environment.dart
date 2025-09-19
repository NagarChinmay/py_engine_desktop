import 'dart:io';
import 'package:path/path.dart' as pathLib;

/// Represents a Python virtual environment with its metadata and configuration
class VirtualEnvironment {
  /// The absolute path to the virtual environment directory
  final String path;
  
  /// The name of the virtual environment (derived from directory name if not provided)
  final String name;
  
  /// Optional description of the virtual environment
  final String? description;
  
  /// Python version used in this virtual environment
  final String? pythonVersion;
  
  /// Whether this virtual environment is currently active
  final bool isActive;
  
  /// When this virtual environment was created
  final DateTime? createdAt;
  
  /// When this virtual environment was last modified
  final DateTime? lastModified;

  const VirtualEnvironment({
    required this.path,
    required this.name,
    this.description,
    this.pythonVersion,
    this.isActive = false,
    this.createdAt,
    this.lastModified,
  });

  /// Creates a VirtualEnvironment from a directory path
  static Future<VirtualEnvironment?> fromPath(String venvPath, {bool isActive = false}) async {
    try {
      final venvDir = Directory(venvPath);
      if (!await venvDir.exists()) return null;

      final name = pathLib.basename(venvPath);
      final stat = await venvDir.stat();
      
      // Try to detect Python version from pyvenv.cfg if it exists
      String? pythonVersion;
      final pyvenvCfg = File(pathLib.join(venvPath, 'pyvenv.cfg'));
      if (await pyvenvCfg.exists()) {
        try {
          final content = await pyvenvCfg.readAsString();
          final versionMatch = RegExp(r'version\s*=\s*([0-9]+\.[0-9]+\.[0-9]+)').firstMatch(content);
          pythonVersion = versionMatch?.group(1);
        } catch (e) {
          // Ignore errors reading pyvenv.cfg
        }
      }

      return VirtualEnvironment(
        path: venvPath,
        name: name,
        pythonVersion: pythonVersion,
        isActive: isActive,
        createdAt: stat.changed,
        lastModified: stat.modified,
      );
    } catch (e) {
      return null;
    }
  }

  /// Returns the path to the Python executable in this virtual environment
  String get pythonExecutablePath {
    if (Platform.isWindows) {
      return pathLib.join(this.path, 'Scripts', 'python.exe');
    } else {
      return pathLib.join(this.path, 'bin', 'python');
    }
  }

  /// Returns the path to the pip executable in this virtual environment
  String get pipExecutablePath {
    if (Platform.isWindows) {
      return pathLib.join(this.path, 'Scripts', 'pip.exe');
    } else {
      return pathLib.join(this.path, 'bin', 'pip');
    }
  }

  /// Returns the path to the site-packages directory
  String get sitePackagesPath {
    if (Platform.isWindows) {
      return pathLib.join(this.path, 'Lib', 'site-packages');
    } else {
      // For Unix-like systems, need to find the correct python version directory
      final libDir = Directory(pathLib.join(this.path, 'lib'));
      if (libDir.existsSync()) {
        final pythonDirs = libDir.listSync()
            .whereType<Directory>()
            .where((dir) => pathLib.basename(dir.path).startsWith('python'))
            .toList();
        if (pythonDirs.isNotEmpty) {
          return pathLib.join(pythonDirs.first.path, 'site-packages');
        }
      }
      // Fallback
      return pathLib.join(this.path, 'lib', 'python3.11', 'site-packages');
    }
  }

  /// Checks if this virtual environment is valid (has required files)
  Future<bool> isValid() async {
    try {
      final pythonExe = File(pythonExecutablePath);
      final pyvenvCfg = File(pathLib.join(this.path, 'pyvenv.cfg'));
      
      return await pythonExe.exists() && await pyvenvCfg.exists();
    } catch (e) {
      return false;
    }
  }

  /// Returns environment information as a map
  Map<String, dynamic> toMap() {
    return {
      'path': this.path,
      'name': name,
      'description': description,
      'pythonVersion': pythonVersion,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'pythonExecutablePath': pythonExecutablePath,
      'sitePackagesPath': sitePackagesPath,
    };
  }

  /// Creates a copy of this virtual environment with updated properties
  VirtualEnvironment copyWith({
    String? path,
    String? name,
    String? description,
    String? pythonVersion,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return VirtualEnvironment(
      path: path ?? this.path,
      name: name ?? this.name,
      description: description ?? this.description,
      pythonVersion: pythonVersion ?? this.pythonVersion,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  String toString() {
    return 'VirtualEnvironment(name: $name, path: ${this.path}, pythonVersion: $pythonVersion, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VirtualEnvironment && other.path == this.path;
  }

  @override
  int get hashCode => this.path.hashCode;
}