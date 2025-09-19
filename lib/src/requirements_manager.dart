import 'dart:convert';
import 'dart:io';

/// Represents a single Python package requirement
class PackageRequirement {
  /// The package name (e.g., 'numpy')
  final String package;
  
  /// The version specification (e.g., '>=1.20.0', '==1.5.3', '*')
  final String version;
  
  /// Optional extras for the package (e.g., ['dev', 'test'])
  final List<String>? extras;
  
  /// Optional source/index URL for the package
  final String? source;

  const PackageRequirement({
    required this.package,
    required this.version,
    this.extras,
    this.source,
  });

  /// Creates a PackageRequirement from a map
  factory PackageRequirement.fromMap(Map<String, dynamic> map) {
    return PackageRequirement(
      package: map['package'] as String,
      version: map['version'] as String? ?? '*',
      extras: map['extras'] != null ? List<String>.from(map['extras']) : null,
      source: map['source'] as String?,
    );
  }

  /// Converts this requirement to a map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'package': package,
      'version': version,
    };
    if (extras != null && extras!.isNotEmpty) {
      map['extras'] = extras;
    }
    if (source != null) {
      map['source'] = source;
    }
    return map;
  }

  /// Converts this requirement to pip install format
  String toPipFormat() {
    final buffer = StringBuffer(package);
    
    if (extras != null && extras!.isNotEmpty) {
      buffer.write('[${extras!.join(',')}]');
    }
    
    // Only add version if it's not '*' or 'latest' (which means install latest)
    if (version != '*' && version != 'latest') {
      buffer.write(version);
    }
    
    return buffer.toString();
  }

  @override
  String toString() => toPipFormat();
}

/// Represents a complete requirements specification
class RequirementsSpec {
  /// List of package requirements
  final List<PackageRequirement> requirements;
  
  /// Target Python version
  final String? pythonVersion;
  
  /// Name of the environment/project
  final String? name;
  
  /// Description of the environment
  final String? description;
  
  /// Additional pip options/flags
  final List<String>? pipOptions;

  const RequirementsSpec({
    required this.requirements,
    this.pythonVersion,
    this.name,
    this.description,
    this.pipOptions,
  });

  /// Creates a RequirementsSpec from JSON string
  factory RequirementsSpec.fromJson(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return RequirementsSpec.fromMap(map);
  }

  /// Creates a RequirementsSpec from a map
  factory RequirementsSpec.fromMap(Map<String, dynamic> map) {
    final requirementsList = map['requirements'] as List<dynamic>? ?? [];
    final requirements = requirementsList
        .map((req) => PackageRequirement.fromMap(req as Map<String, dynamic>))
        .toList();

    return RequirementsSpec(
      requirements: requirements,
      pythonVersion: map['python_version'] as String?,
      name: map['name'] as String?,
      description: map['description'] as String?,
      pipOptions: map['pip_options'] != null 
          ? List<String>.from(map['pip_options']) 
          : null,
    );
  }

  /// Converts this specification to JSON string
  String toJson() {
    return json.encode(toMap());
  }

  /// Converts this specification to a map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'requirements': requirements.map((req) => req.toMap()).toList(),
    };
    
    if (pythonVersion != null) map['python_version'] = pythonVersion;
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (pipOptions != null && pipOptions!.isNotEmpty) {
      map['pip_options'] = pipOptions;
    }
    
    return map;
  }

  /// Converts this specification to traditional requirements.txt format
  String toRequirementsTxt() {
    return requirements.map((req) => req.toPipFormat()).join('\n');
  }
}

/// Manages requirements parsing, validation, and installation
class RequirementsManager {
  /// Parses requirements from JSON string
  static RequirementsSpec parseJson(String jsonString) {
    try {
      return RequirementsSpec.fromJson(jsonString);
    } catch (e) {
      throw FormatException('Invalid requirements JSON format: $e');
    }
  }

  /// Parses requirements from traditional requirements.txt format
  static RequirementsSpec parseRequirementsTxt(String requirementsTxt) {
    final lines = requirementsTxt.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();

    final requirements = <PackageRequirement>[];
    
    for (final line in lines) {
      try {
        final requirement = _parseRequirementLine(line);
        if (requirement != null) {
          requirements.add(requirement);
        }
      } catch (e) {
        // Skip invalid lines with warning
        print('Warning: Skipping invalid requirement line: $line');
      }
    }

    return RequirementsSpec(requirements: requirements);
  }

  /// Parses a single requirement line from requirements.txt
  static PackageRequirement? _parseRequirementLine(String line) {
    // Basic parsing for common formats like:
    // numpy>=1.20.0
    // pandas==1.5.3
    // requests
    
    final versionPattern = RegExp(r'^([a-zA-Z0-9\-_.]+)(.*?)$');
    final match = versionPattern.firstMatch(line);
    
    if (match == null) return null;
    
    final package = match.group(1)!;
    final versionSpec = match.group(2)?.trim() ?? '*';
    
    return PackageRequirement(
      package: package,
      version: versionSpec.isEmpty ? '*' : versionSpec,
    );
  }

  /// Loads requirements from a file
  static Future<RequirementsSpec> loadFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Requirements file not found: $filePath');
    }

    final content = await file.readAsString();
    final fileName = file.path.toLowerCase();
    
    if (fileName.endsWith('.json')) {
      return parseJson(content);
    } else {
      // Assume requirements.txt format
      return parseRequirementsTxt(content);
    }
  }

  /// Saves requirements to a file
  static Future<void> saveToFile(RequirementsSpec spec, String filePath) async {
    final file = File(filePath);
    final fileName = file.path.toLowerCase();
    
    String content;
    if (fileName.endsWith('.json')) {
      content = spec.toJson();
    } else {
      content = spec.toRequirementsTxt();
    }
    
    await file.writeAsString(content);
  }

  /// Validates a requirements specification
  static List<String> validate(RequirementsSpec spec) {
    final errors = <String>[];
    
    // Check for duplicate packages
    final packageNames = <String>{};
    for (final req in spec.requirements) {
      if (packageNames.contains(req.package)) {
        errors.add('Duplicate package: ${req.package}');
      } else {
        packageNames.add(req.package);
      }
      
      // Basic package name validation
      if (req.package.isEmpty) {
        errors.add('Empty package name found');
      }
      
      // Basic version validation
      if (req.version.isEmpty) {
        errors.add('Empty version specification for package: ${req.package}');
      }
    }
    
    return errors;
  }

  /// Creates a default requirements specification
  static RequirementsSpec createDefault({
    String? name,
    String? description,
    List<PackageRequirement>? initialPackages,
  }) {
    return RequirementsSpec(
      requirements: initialPackages ?? [
        const PackageRequirement(package: 'pip', version: 'latest'),
        const PackageRequirement(package: 'setuptools', version: 'latest'),
      ],
      pythonVersion: '3.11',
      name: name ?? 'default_environment',
      description: description ?? 'Default Python virtual environment',
    );
  }

  /// Merges two requirements specifications
  static RequirementsSpec merge(RequirementsSpec spec1, RequirementsSpec spec2) {
    final packageMap = <String, PackageRequirement>{};
    
    // Add requirements from first spec
    for (final req in spec1.requirements) {
      packageMap[req.package] = req;
    }
    
    // Add/override with requirements from second spec
    for (final req in spec2.requirements) {
      packageMap[req.package] = req;
    }
    
    return RequirementsSpec(
      requirements: packageMap.values.toList(),
      pythonVersion: spec2.pythonVersion ?? spec1.pythonVersion,
      name: spec2.name ?? spec1.name,
      description: spec2.description ?? spec1.description,
      pipOptions: spec2.pipOptions ?? spec1.pipOptions,
    );
  }
}