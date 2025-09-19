# 🐍 PyEngine Desktop - Embedded Python Runtime for Flutter

[![pub package](https://img.shields.io/pub/v/py_engine_desktop.svg)](https://pub.dev/packages/py_engine_desktop)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-blue)](https://pub.dev/packages/py_engine_desktop)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.3.0-blue)](https://flutter.dev)

**The ultimate Flutter plugin for embedded Python scripting and automation on desktop platforms.** Seamlessly integrate Python interpreter, execute scripts, run interactive REPL sessions, and manage packages - all within your Flutter desktop applications.

**🚀 Perfect for**: Data science apps, automation tools, machine learning integrations, scripting interfaces, educational platforms, and any desktop app requiring Python backend processing.

**🎯 Production Ready** - Fully tested on Windows, macOS & Linux

## ✨ Key Features

- 🐍 **Embedded Python Runtime**: Zero-dependency Python 3.11 interpreter with automatic distribution management
- 🖥️ **Cross-Platform Desktop**: Native support for Windows x64, macOS x64, and Linux x64
- 📜 **Python Script Execution**: Real-time stdout/stderr streaming with process control
- 🔄 **Interactive Python REPL**: Full-featured Python shell with command history and output capture
- 📦 **Pip Package Management**: Install NumPy, Pandas, Requests, and any PyPI package
- 🔒 **Isolated Environment**: App-specific Python installation prevents system conflicts
- 🎯 **NEW: Virtual Environment Support**: Create and manage isolated Python environments with custom dependencies
- 📋 **NEW: JSON Requirements Management**: Advanced package management with metadata and version constraints
- 🔄 **NEW: Dual Mode Operation**: Seamless switching between base Python and virtual environments
- 🚀 **Zero Configuration**: One-line initialization with automatic runtime setup
- ⚡ **High Performance**: Cached runtime for instant subsequent launches
- 🛠️ **Developer Friendly**: Comprehensive error handling and debugging support

## Supported Platforms

| Platform | Support | Architecture | Tested |
|----------|---------|--------------|--------|
| Windows | ✅ | x64 | ✅ |
| macOS | ✅ | x64 | ✅ |
| Linux | ✅ | x64 | ✅ |
| Android | ❌ | - | - |
| iOS | ❌ | - | - |
| Web | ❌ | - | - |

## 🎯 Use Cases & Applications

**Perfect for developers building:**

### 📊 Data Science & Analytics
- **Business Intelligence Tools**: Real-time data processing with Pandas and NumPy
- **Data Visualization Apps**: Interactive charts using Matplotlib and Seaborn
- **Scientific Computing**: Mathematical modeling and statistical analysis
- **Machine Learning Interfaces**: Model training and inference with scikit-learn, TensorFlow

### 🤖 Automation & Scripting
- **Desktop Automation Tools**: System administration and task automation
- **File Processing Applications**: Batch operations, format conversions, data migration
- **API Integration Platforms**: REST API clients, web scraping tools
- **DevOps Dashboards**: Deployment scripts, monitoring tools, CI/CD interfaces

### 🎓 Educational & Learning
- **Python Learning Platforms**: Interactive coding environments and tutorials
- **STEM Education Apps**: Mathematical computing, physics simulations
- **Code Playgrounds**: Live Python coding with instant feedback
- **Algorithm Visualization**: Data structures and algorithms teaching tools

### 🔧 Developer Tools & IDEs
- **Code Editors**: Python syntax highlighting, code completion
- **Testing Frameworks**: Automated testing interfaces, test runners
- **Database Management**: SQL query builders, data migration tools
- **Configuration Managers**: Settings editors, environment management

### 🏢 Enterprise Applications
- **Report Generators**: Automated PDF/Excel report creation
- **System Monitoring**: Performance dashboards, log analysis
- **Integration Platforms**: ERP connectors, data synchronization
- **Workflow Automation**: Business process automation, approval systems

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  py_engine_desktop: ^1.1.0
```

Then run:

```bash
flutter pub get
```

### 🍎 Important: macOS Configuration

**For macOS apps, you MUST disable sandbox mode to allow Python executable execution.**

In your Flutter macOS project, update the following files:

**`macos/Runner/DebugProfile.entitlements`** and **`macos/Runner/Release.entitlements`**

Change:
```xml
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
</dict>
```

To:
```xml
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
```

> ⚠️ **Note**: Disabling sandbox mode is required for executing Python processes. This is a limitation of macOS security model when running external executables. Without this change, you'll get `ProcessException: Operation not permitted` errors.

## Quick Start

### 1. Add dependency
Add this to your `pubspec.yaml`:
```yaml
dependencies:
  py_engine_desktop: ^1.1.0
```

### 2. Import and Initialize

```dart
import 'package:py_engine_desktop/py_engine_desktop.dart';

class MyPythonApp extends StatefulWidget {
  @override
  _MyPythonAppState createState() => _MyPythonAppState();
}

class _MyPythonAppState extends State<MyPythonApp> {
  bool _initialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializePython();
  }
  
  Future<void> _initializePython() async {
    try {
      await PyEngineDesktop.init();
      setState(() => _initialized = true);
      print('Python engine ready!');
    } catch (e) {
      print('Failed to initialize: $e');
    }
  }
}
```

### 3. Run Python Scripts

```dart
Future<void> runPythonScript() async {
  if (!_initialized) return;
  
  // Create a simple Python script
  final script = '''
import math
print("Hello from Python!")
print(f"Pi = {math.pi}")
for i in range(5):
    print(f"Count: {i}")
  ''';
  
  // Write script to temp file
  final tempDir = await getTemporaryDirectory();
  final scriptFile = File(path.join(tempDir.path, 'my_script.py'));
  await scriptFile.writeAsString(script);
  
  // Execute the script
  final pythonScript = await PyEngineDesktop.startScript(scriptFile.path);
  
  // Listen to output
  pythonScript.stdout.listen((line) {
    print('Python Output: $line');
  });
  
  pythonScript.stderr.listen((line) {
    print('Python Error: $line');
  });
  
  // Wait for completion
  await pythonScript.exitCode;
  print('Script completed!');
}
```

### 4. Interactive Python REPL

```dart
PythonRepl? _repl;

Future<void> startInteractivePython() async {
  if (!_initialized) return;
  
  _repl = await PyEngineDesktop.startRepl();
  
  // Listen to all output
  _repl!.output.listen((output) {
    print('REPL: $output');
  });
  
  // Send some commands
  _repl!.send('import numpy as np');
  _repl!.send('arr = np.array([1, 2, 3, 4, 5])');
  _repl!.send('print("Array:", arr)');
  _repl!.send('print("Mean:", np.mean(arr))');
}

void sendCommand(String command) {
  if (_repl != null) {
    _repl!.send(command);
  }
}
```

### 5. Package Management

```dart
Future<void> setupPythonPackages() async {
  if (!_initialized) return;
  
  // Install essential packages
  await PyEngineDesktop.pipInstall('numpy');
  await PyEngineDesktop.pipInstall('pandas');
  await PyEngineDesktop.pipInstall('requests');
  
  print('Packages installed successfully!');
}

// Test if packages work
Future<void> testPackages() async {
  final repl = await PyEngineDesktop.startRepl();
  
  repl.output.listen((output) => print(output));
  
  // Test numpy
  repl.send('import numpy as np');
  repl.send('print("NumPy version:", np.__version__)');
  
  // Test pandas
  repl.send('import pandas as pd');
  repl.send('df = pd.DataFrame({"A": [1,2,3], "B": [4,5,6]})');
  repl.send('print(df)');
  
  repl.stop();
}
```

### 6. Complete Widget Example

```dart
class PythonConsole extends StatefulWidget {
  @override
  _PythonConsoleState createState() => _PythonConsoleState();
}

class _PythonConsoleState extends State<PythonConsole> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _output = [];
  PythonRepl? _repl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initPython();
  }

  Future<void> _initPython() async {
    await PyEngineDesktop.init();
    _repl = await PyEngineDesktop.startRepl();
    
    _repl!.output.listen((line) {
      setState(() => _output.add(line));
    });
    
    setState(() => _initialized = true);
  }

  void _sendCommand() {
    final command = _controller.text.trim();
    if (command.isNotEmpty && _repl != null) {
      setState(() => _output.add('>>> $command'));
      _repl!.send(command);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(8),
            color: Colors.black,
            child: ListView.builder(
              itemCount: _output.length,
              itemBuilder: (context, index) => Text(
                _output[index],
                style: TextStyle(color: Colors.green, fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
        if (_initialized)
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: 'Enter Python command...'),
                    onSubmitted: (_) => _sendCommand(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendCommand,
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _repl?.stop();
    super.dispose();
  }
}
```

## 🆕 Virtual Environment Management

### 7. Create and Use Virtual Environments

```dart
Future<void> setupVirtualEnvironment() async {
  // Initialize Python engine
  await PyEngineDesktop.init();
  
  // Create a virtual environment
  final venv = await PyEngineDesktop.createVirtualEnvironment(
    '/path/to/my_project_env',
    name: 'data_science_project'
  );
  
  // Activate the virtual environment
  await PyEngineDesktop.activateVirtualEnvironment('/path/to/my_project_env');
  
  // Install packages in the virtual environment
  final requirements = '''
  {
    "requirements": [
      {"package": "numpy", "version": ">=1.20.0"},
      {"package": "pandas", "version": ">=1.5.0"},
      {"package": "matplotlib", "version": "*"},
      {"package": "scikit-learn", "version": "latest"}
    ],
    "name": "data_science_env",
    "description": "Data science development environment"
  }
  ''';
  
  await PyEngineDesktop.installRequirementsFromJson(requirements);
  
  // Now scripts and REPL will use the virtual environment
  final repl = await PyEngineDesktop.startRepl();
  repl.send('import numpy as np; print("NumPy version:", np.__version__)');
  
  // Deactivate when done
  PyEngineDesktop.deactivateVirtualEnvironment();
}
```

### 8. Dual Mode Usage - Base vs Virtual Environment

```dart
class DualModeExample extends StatefulWidget {
  @override
  _DualModeExampleState createState() => _DualModeExampleState();
}

class _DualModeExampleState extends State<DualModeExample> {
  VirtualEnvironment? activeVenv;
  
  @override
  void initState() {
    super.initState();
    _initializePython();
  }
  
  Future<void> _initializePython() async {
    await PyEngineDesktop.init();
    _updateActiveEnvironment();
  }
  
  void _updateActiveEnvironment() {
    setState(() {
      activeVenv = PyEngineDesktop.activeVirtualEnvironment;
    });
  }
  
  Future<void> _testCurrentEnvironment() async {
    final envInfo = PyEngineDesktop.getCurrentEnvironmentInfo();
    print('Environment type: ${envInfo['type']}'); // 'base' or 'virtual'
    
    if (envInfo['type'] == 'virtual') {
      final venv = envInfo['environment'];
      print('Virtual environment: ${venv['name']}');
    }
    
    // Test package availability
    final repl = await PyEngineDesktop.startRepl();
    repl.send('try: import numpy; print("✅ NumPy available"); except: print("❌ NumPy not found")');
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Environment Status
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: activeVenv != null ? Colors.blue.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                activeVenv != null ? Icons.computer : Icons.home,
                color: activeVenv != null ? Colors.blue : Colors.grey,
              ),
              SizedBox(width: 8),
              Text(
                activeVenv != null 
                    ? 'Virtual Environment: ${activeVenv!.name}'
                    : 'Base Python Environment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: activeVenv != null ? Colors.blue.shade700 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        
        // Actions
        SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton(
              onPressed: _testCurrentEnvironment,
              child: Text('Test Current Environment'),
            ),
            SizedBox(width: 8),
            if (activeVenv != null)
              ElevatedButton(
                onPressed: () {
                  PyEngineDesktop.deactivateVirtualEnvironment();
                  _updateActiveEnvironment();
                },
                child: Text('Deactivate VEnv'),
              ),
          ],
        ),
      ],
    );
  }
}
```

### 9. Requirements Management Examples

```dart
// Basic requirements
final basicRequirements = '''
{
  "requirements": [
    {"package": "requests", "version": "*"}
  ],
  "name": "basic_env"
}
''';

// Data science requirements
final dataScienceRequirements = '''
{
  "requirements": [
    {"package": "numpy", "version": ">=1.20.0"},
    {"package": "pandas", "version": ">=1.5.0"},
    {"package": "matplotlib", "version": ">=3.5.0"},
    {"package": "seaborn", "version": "*"},
    {"package": "scikit-learn", "version": ">=1.0.0"},
    {"package": "jupyter", "version": "latest"}
  ],
  "python_version": "3.11",
  "name": "data_science_env",
  "description": "Complete data science development environment"
}
''';

// Machine learning requirements with extras
final mlRequirements = '''
{
  "requirements": [
    {"package": "tensorflow", "version": ">=2.10.0", "extras": ["gpu"]},
    {"package": "torch", "version": ">=1.12.0"},
    {"package": "transformers", "version": ">=4.20.0"},
    {"package": "datasets", "version": ">=2.0.0"}
  ],
  "python_version": "3.11",
  "name": "ml_environment",
  "description": "Machine Learning with TensorFlow and PyTorch",
  "pip_options": ["--no-cache-dir"]
}
''';

// Install any of these
await PyEngineDesktop.installRequirementsFromJson(dataScienceRequirements);

// Export current environment
final currentRequirements = await PyEngineDesktop.exportRequirementsAsJson(
  name: 'my_project',
  description: 'Project dependencies'
);
```

## API Reference

### PyEngineDesktop

Main class providing static methods for Python engine management.

#### `PyEngineDesktop.init()`
**Purpose**: Initializes the Python engine by extracting and setting up the embedded Python runtime.

**What it does**:
- Extracts Python runtime from bundled assets (first run only)
- Sets up Python executable with proper permissions 
- Configures site-packages directory for pip installations
- Caches runtime for faster subsequent launches

```dart
// Basic initialization
await PyEngineDesktop.init();

// With error handling
try {
  await PyEngineDesktop.init();
  print('Python engine ready!');
} catch (e) {
  if (e is UnsupportedError) {
    print('Platform not supported');
  } else {
    print('Initialization failed: $e');
  }
}
```

#### `PyEngineDesktop.startScript(String scriptPath)`
**Purpose**: Executes a Python script file and returns a `PythonScript` object for monitoring.

**What it does**:
- Validates script file exists before execution
- Starts Python process with the script
- Automatically includes site-packages in Python path
- Returns `PythonScript` object for output monitoring and control

```dart
// Basic script execution
final script = await PyEngineDesktop.startScript('/path/to/script.py');

// Listen to output streams
script.stdout.listen((line) => print('Output: $line'));
script.stderr.listen((line) => print('Error: $line'));

// Wait for completion
final exitCode = await script.exitCode;
print('Script finished with code: $exitCode');

// Or stop manually if needed
script.stop();
```

#### `PyEngineDesktop.startRepl()`
**Purpose**: Starts an interactive Python REPL (Read-Eval-Print Loop) session.

**What it does**:
- Launches Python in interactive mode using `code.interact()`
- Automatically includes site-packages for installed packages
- Combines stdout/stderr into single output stream
- Allows sending commands via `send()` method

```dart
// Start REPL and send commands
final repl = await PyEngineDesktop.startRepl();

// Listen to all output (both results and prompts)
repl.output.listen((output) => print(output));

// Send Python commands
repl.send('print("Hello Python!")');
repl.send('x = 5 + 3');
repl.send('print(f"Result: {x}")');

// Send multi-line code
repl.send('for i in range(3):');
repl.send('    print(f"Count: {i}")');

// Stop when done
repl.stop();
```

#### `PyEngineDesktop.pipInstall(String package)` / `PyEngineDesktop.pipUninstall(String package)`
**Purpose**: Manages Python packages using pip package manager.

**What it does**:
- `pipInstall`: Downloads and installs Python packages from PyPI
- `pipUninstall`: Removes installed Python packages  
- Automatically downloads and sets up pip if not available
- Installs packages to embedded Python's site-packages directory

```dart
// Install packages
try {
  await PyEngineDesktop.pipInstall('numpy');
  await PyEngineDesktop.pipInstall('requests==2.28.1'); // Specific version
  print('Packages installed successfully');
} catch (e) {
  print('Installation failed: $e');
}

// Uninstall packages  
try {
  await PyEngineDesktop.pipUninstall('numpy');
  print('Package uninstalled successfully');
} catch (e) {
  print('Uninstallation failed: $e');
}
```

#### `PyEngineDesktop.pythonPath`
**Purpose**: Gets the absolute path to the embedded Python executable.

**What it does**:
- Returns full path to Python executable after initialization
- Throws `StateError` if called before `init()`
- Path points to embedded Python runtime, not system Python

```dart
// Get Python executable path
await PyEngineDesktop.init();
final pythonPath = PyEngineDesktop.pythonPath;
print('Python executable: $pythonPath');
// Output example: C:\Users\...\AppData\Roaming\py_engine_desktop\python\python.exe
```

#### `PyEngineDesktop.stopScript(PythonScript script)`
**Purpose**: Stops a running Python script process.

**What it does**:
- Terminates the script process immediately
- Closes output streams
- Safe to call multiple times

```dart
final script = await PyEngineDesktop.startScript('script.py');
// ... later
await PyEngineDesktop.stopScript(script);
// Or use script.stop() directly
```

#### `PyEngineDesktop.stopRepl(PythonRepl repl)`
**Purpose**: Stops a running Python REPL session.

**What it does**:
- Terminates the REPL process
- Closes output streams  
- Safe to call multiple times

```dart
final repl = await PyEngineDesktop.startRepl();
// ... later
await PyEngineDesktop.stopRepl(repl);
// Or use repl.stop() directly
```

#### 🆕 Virtual Environment Management Methods

#### `PyEngineDesktop.createVirtualEnvironment(String venvPath, {String? name})`
**Purpose**: Creates a new isolated Python virtual environment.

**What it does**:
- Creates a new virtual environment using Python's venv module
- Sets up isolated site-packages directory
- Configures proper Python executable permissions
- Returns VirtualEnvironment object with metadata

```dart
// Create a virtual environment
final venv = await PyEngineDesktop.createVirtualEnvironment(
  '/path/to/my_project_env',
  name: 'my_project'
);
print('Created: ${venv.name}');
```

#### `PyEngineDesktop.activateVirtualEnvironment(String venvPath)`
**Purpose**: Activates a virtual environment for use.

**What it does**:
- Switches Python execution context to the virtual environment
- All subsequent scripts and REPL sessions use the venv Python
- Package installations go to the venv site-packages

```dart
await PyEngineDesktop.activateVirtualEnvironment('/path/to/my_project_env');
// Now all Python operations use the virtual environment
```

#### `PyEngineDesktop.deactivateVirtualEnvironment()`
**Purpose**: Deactivates the current virtual environment.

**What it does**:
- Returns to base Python environment
- Scripts and REPL use base Python installation
- Package operations affect base site-packages

```dart
PyEngineDesktop.deactivateVirtualEnvironment();
// Back to base Python environment
```

#### `PyEngineDesktop.installRequirementsFromJson(String requirementsJson)`
**Purpose**: Installs packages from JSON requirements specification.

**What it does**:
- Parses JSON requirements with metadata
- Supports version constraints, extras, and pip options
- Installs to currently active environment (base or venv)

```dart
final requirements = '''
{
  "requirements": [
    {"package": "numpy", "version": ">=1.20.0"},
    {"package": "tensorflow", "version": ">=2.10.0", "extras": ["gpu"]}
  ],
  "name": "ml_project"
}
''';

await PyEngineDesktop.installRequirementsFromJson(requirements);
```

#### `PyEngineDesktop.exportRequirementsAsJson({String? name, String? description})`
**Purpose**: Exports currently installed packages as JSON requirements.

**What it does**:
- Lists all packages in active environment
- Captures exact versions for reproducibility
- Returns formatted JSON with metadata

```dart
final requirements = await PyEngineDesktop.exportRequirementsAsJson(
  name: 'my_project',
  description: 'Project dependencies'
);
print(requirements); // JSON string
```

#### `PyEngineDesktop.getCurrentEnvironmentInfo()`
**Purpose**: Gets detailed information about the current Python environment.

**What it does**:
- Returns environment type ('base' or 'virtual')
- Provides Python paths and metadata
- Shows active virtual environment details

```dart
final envInfo = PyEngineDesktop.getCurrentEnvironmentInfo();
print('Type: ${envInfo['type']}');
if (envInfo['type'] == 'virtual') {
  print('VEnv: ${envInfo['environment']['name']}');
}
```

#### `PyEngineDesktop.activeVirtualEnvironment`
**Purpose**: Gets the currently active virtual environment.

**Returns**: `VirtualEnvironment?` - null if using base Python

```dart
final activeVenv = PyEngineDesktop.activeVirtualEnvironment;
if (activeVenv != null) {
  print('Active: ${activeVenv.name}');
  print('Python: ${activeVenv.pythonVersion}');
  print('Path: ${activeVenv.path}');
}
```

### PythonScript

Object returned by `startScript()` representing a running Python script.

**Properties**:
- `Stream<String> stdout` - Script's standard output (line by line)
- `Stream<String> stderr` - Script's error output (line by line)  
- `Process process` - Underlying Dart process object
- `Future<int> exitCode` - Completes when script finishes with exit code

**Methods**:
- `void stop()` - Terminates the script immediately

### PythonRepl

Object returned by `startRepl()` representing an interactive Python session.

**Properties**:
- `Stream<String> output` - Combined stdout/stderr output stream
- `Process process` - Underlying Dart process object  
- `Future<int> exitCode` - Completes when REPL session ends

**Methods**:
- `void send(String code)` - Sends Python code to execute
- `void stop()` - Terminates the REPL session

## Example Usage

Check out the [example](example/) directory for a complete demo application that shows:

- Python engine initialization
- Running Python scripts with output display
- Interactive REPL with command input
- Installing and testing NumPy package

## How It Works

### Python Runtime Distribution

The plugin automatically downloads portable Python distributions:

- **Windows**: Embeddable Python distribution (python.org)
- **macOS/Linux**: Standalone Python builds (python-build-standalone)

### File Locations

Python runtimes are extracted to platform-specific application support directories:

- **Windows**: `%AppData%/py_engine_desktop/python`
- **macOS**: `~/Library/Application Support/py_engine_desktop/python`
- **Linux**: `~/.local/share/py_engine_desktop/python`

### First Run Setup

On first initialization:
1. Detects the current platform
2. Extracts the appropriate Python runtime from assets
3. Sets up the Python environment
4. Subsequent runs use the cached Python installation

## Error Handling

The plugin provides comprehensive error handling:

```dart
try {
  await PyEngineDesktop.init();
} catch (e) {
  if (e is UnsupportedError) {
    print('Platform not supported: $e');
  } else {
    print('Initialization failed: $e');
  }
}
```

## Limitations

- **Desktop Only**: Only works on desktop platforms (Windows, macOS, Linux)
- **Single Architecture**: Currently supports x64 architectures only
- **Python Version**: Uses Python 3.11.x
- **Size**: Python runtimes add ~10-30MB to your app's size
- **First Run**: Initial setup requires extracting Python runtime (one-time delay)

## Performance & Size

| Platform | Runtime Size | First Init Time |
|----------|-------------|-----------------|
| Windows | ~15MB | 2-5 seconds |
| macOS | ~25MB | 3-7 seconds |
| Linux | ~30MB | 3-8 seconds |

> **Note**: Python runtime is cached after first initialization. Subsequent app launches are instant.

## Development

### Building from Source

```bash
git clone https://github.com/NagarChinmay/py_engine_desktop.git
cd py_engine_desktop
flutter pub get
cd example
flutter run
```

### Running Tests

```bash
flutter test
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Issues & Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/NagarChinmay/py_engine_desktop/issues)
- 💡 **Feature Requests**: [GitHub Issues](https://github.com/NagarChinmay/py_engine_desktop/issues)
- 📖 **Documentation**: Check the [example](example/) for complete usage

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.

---

## 🔍 Keywords & SEO

**Flutter Python Plugin | Desktop Python Runtime | Embedded Python Interpreter | Python Script Execution | Interactive Python REPL | Flutter Desktop Automation | Python Package Management | Cross-Platform Python | Flutter Data Science | Machine Learning Flutter | Python Integration Flutter | Desktop Python Tools | Flutter Scripting | Python Backend Flutter | Educational Python Apps**

*Popular searches: flutter python, python desktop app, embedded python runtime, flutter scripting, python automation, data science flutter, machine learning desktop app, python repl flutter, cross-platform python, desktop python integration*

