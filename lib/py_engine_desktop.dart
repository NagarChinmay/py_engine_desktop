

export 'src/python_script.dart';
export 'src/python_repl.dart';
export 'src/python_engine.dart';
export 'src/virtual_environment.dart';
export 'src/requirements_manager.dart';

import 'src/python_engine.dart';
import 'src/python_script.dart';
import 'src/python_repl.dart';
import 'src/virtual_environment.dart';
import 'src/requirements_manager.dart';

class PyEngineDesktop {
  static final PythonEngine _engine = PythonEngine.instance;
  
  // Core functionality
  static Future<void> init() => _engine.init();
  
  static Future<PythonScript> startScript(String path) => _engine.startScript(path);
  
  static Future<void> stopScript(PythonScript script) => _engine.stopScript(script);
  
  static Future<PythonRepl> startRepl() => _engine.startRepl();
  
  static Future<void> stopRepl(PythonRepl repl) => _engine.stopRepl(repl);
  
  static Future<void> pipInstall(String package) => _engine.pipInstall(package);
  
  static Future<void> pipUninstall(String package) => _engine.pipUninstall(package);
  
  static String get pythonPath => _engine.pythonPath;
  
  // Virtual Environment Management
  
  /// Creates a new virtual environment at the specified path
  static Future<VirtualEnvironment> createVirtualEnvironment(String venvPath, {String? name}) => 
      _engine.createVirtualEnvironment(venvPath, name: name);
  
  /// Activates a virtual environment
  static Future<void> activateVirtualEnvironment(String venvPath) => 
      _engine.activateVirtualEnvironment(venvPath);
  
  /// Deactivates the current virtual environment
  static void deactivateVirtualEnvironment() => _engine.deactivateVirtualEnvironment();
  
  /// Lists all virtual environments in a directory
  static Future<List<VirtualEnvironment>> listVirtualEnvironments(String searchPath) => 
      _engine.listVirtualEnvironments(searchPath);
  
  /// Deletes a virtual environment
  static Future<void> deleteVirtualEnvironment(String venvPath) => 
      _engine.deleteVirtualEnvironment(venvPath);
  
  /// Gets the currently active virtual environment
  static VirtualEnvironment? get activeVirtualEnvironment => _engine.activeVirtualEnvironment;
  
  /// Checks if a virtual environment exists and is valid
  static Future<bool> isValidVirtualEnvironment(String venvPath) => 
      _engine.isValidVirtualEnvironment(venvPath);
  
  // Requirements Management
  
  /// Installs packages from requirements specification
  static Future<void> installRequirements(RequirementsSpec requirements) => 
      _engine.installRequirements(requirements);
  
  /// Installs packages from requirements JSON string
  static Future<void> installRequirementsFromJson(String requirementsJson) => 
      _engine.installRequirementsFromJson(requirementsJson);
  
  /// Installs packages from a requirements file
  static Future<void> installRequirementsFromFile(String filePath) => 
      _engine.installRequirementsFromFile(filePath);
  
  /// Exports current environment's installed packages as requirements
  static Future<RequirementsSpec> exportRequirements({String? name, String? description}) => 
      _engine.exportRequirements(name: name, description: description);
  
  /// Exports current environment as JSON string
  static Future<String> exportRequirementsAsJson({String? name, String? description}) async {
    final requirements = await _engine.exportRequirements(name: name, description: description);
    return requirements.toJson();
  }
  
  // Environment Information
  
  /// Gets detailed information about the current environment
  static Map<String, dynamic> getCurrentEnvironmentInfo() => _engine.getCurrentEnvironmentInfo();
  
  /// Upgrades pip in the active virtual environment
  static Future<void> upgradePip() => _engine.upgradePip();
  
  /// Clears the pip cache for the active environment
  static Future<void> clearPipCache() => _engine.clearPipCache();
  
  // Utility methods for requirements management
  
  /// Parses requirements from JSON string
  static RequirementsSpec parseRequirementsJson(String jsonString) => 
      RequirementsManager.parseJson(jsonString);
  
  /// Parses requirements from traditional requirements.txt format
  static RequirementsSpec parseRequirementsTxt(String requirementsTxt) => 
      RequirementsManager.parseRequirementsTxt(requirementsTxt);
  
  /// Creates a default requirements specification
  static RequirementsSpec createDefaultRequirements({
    String? name,
    String? description,
    List<PackageRequirement>? initialPackages,
  }) => RequirementsManager.createDefault(
    name: name,
    description: description,
    initialPackages: initialPackages,
  );
  
  /// Validates a requirements specification
  static List<String> validateRequirements(RequirementsSpec spec) => 
      RequirementsManager.validate(spec);
}
