# py_engine_desktop

[![pub package](https://img.shields.io/pub/v/py_engine_desktop.svg)](https://pub.dev/packages/py_engine_desktop)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Flutter plugin for managing embedded Python runtimes on desktop platforms (Windows, macOS, Linux). This plugin allows you to run Python scripts and interactive REPLs directly from your Flutter desktop applications.

**🎯 Production Ready** - Tested on Windows & macOS, Linux testing in progress

## Features

- 🐍 **Embedded Python Runtime**: Automatically downloads and extracts portable Python distributions
- 🖥️ **Desktop Support**: Works on Windows, macOS, and Linux
- 📜 **Script Execution**: Run Python scripts with real-time stdout/stderr output
- 🔄 **Interactive REPL**: Start Python REPLs and send commands interactively
- 📦 **Package Management**: Install Python packages using pip
- 🚀 **Easy Setup**: One-time initialization handles everything automatically

## Supported Platforms

| Platform | Support | Architecture | Tested |
|----------|---------|--------------|--------|
| Windows | ✅ | x64 | ✅ |
| macOS | ✅ | x64 | ✅ |
| Linux | ✅ | x64 | 🔄 In Progress |
| Android | ❌ | - | - |
| iOS | ❌ | - | - |
| Web | ❌ | - | - |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  py_engine_desktop: ^0.0.1
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
  py_engine_desktop: ^0.0.1
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

## API Reference & Detailed Function Usage

### PyEngineDesktop

Main class providing static methods for Python engine management.

#### `PyEngineDesktop.init()`
Initializes the Python engine by downloading and setting up the Python runtime.

```dart
// Basic initialization
await PyEngineDesktop.init();

// With error handling and loading feedback
Future<void> initializePythonWithFeedback() async {
  print('Initializing Python engine...');
  final stopwatch = Stopwatch()..start();
  
  try {
    await PyEngineDesktop.init();
    stopwatch.stop();
    print('✅ Python initialized in ${stopwatch.elapsedMilliseconds}ms');
    print('📂 Python path: ${PyEngineDesktop.pythonPath}');
  } catch (e) {
    print('❌ Failed to initialize Python: $e');
    if (e.toString().contains('UnsupportedError')) {
      print('💡 This platform is not supported');
    } else if (e.toString().contains('network')) {
      print('💡 Check your internet connection');
    }
  }
}
```

#### `PyEngineDesktop.startScript(String scriptPath)`
Executes a Python script file and returns a `PythonScript` object.

```dart
// Basic script execution
Future<void> runBasicScript() async {
  final script = await PyEngineDesktop.startScript('/path/to/script.py');
  await script.exitCode; // Wait for completion
}

// Advanced script execution with full output handling
Future<void> runAdvancedScript(String scriptPath) async {
  print('🐍 Starting Python script: $scriptPath');
  
  final script = await PyEngineDesktop.startScript(scriptPath);
  final outputBuffer = <String>[];
  final errorBuffer = <String>[];
  
  // Capture all stdout
  script.stdout.listen(
    (line) {
      print('📤 OUT: $line');
      outputBuffer.add(line);
    },
    onError: (error) => print('❌ Stdout error: $error'),
    onDone: () => print('✅ Stdout stream closed'),
  );
  
  // Capture all stderr
  script.stderr.listen(
    (line) {
      print('🚨 ERR: $line');
      errorBuffer.add(line);
    },
    onError: (error) => print('❌ Stderr error: $error'),
    onDone: () => print('✅ Stderr stream closed'),
  );
  
  // Wait for script completion
  final exitCode = await script.exitCode;
  
  print('🏁 Script finished with exit code: $exitCode');
  print('📊 Total output lines: ${outputBuffer.length}');
  print('🚨 Total error lines: ${errorBuffer.length}');
  
  if (exitCode != 0) {
    print('💥 Script failed! Errors:');
    errorBuffer.forEach((line) => print('  $line'));
  }
}

// Create and run a dynamic script
Future<void> createAndRunScript(String pythonCode) async {
  // Write Python code to temporary file
  final tempDir = await getTemporaryDirectory();
  final scriptFile = File(path.join(tempDir.path, 'dynamic_script.py'));
  await scriptFile.writeAsString(pythonCode);
  
  // Execute the script
  final script = await PyEngineDesktop.startScript(scriptFile.path);
  
  // Handle output with timeout
  final outputTimeout = Duration(seconds: 30);
  final outputCompleter = Completer<List<String>>();
  final output = <String>[];
  
  script.stdout.listen((line) => output.add(line));
  script.stderr.listen((line) => output.add('ERROR: $line'));
  
  script.exitCode.then((_) {
    if (!outputCompleter.isCompleted) {
      outputCompleter.complete(output);
    }
  });
  
  // Wait for completion or timeout
  try {
    final result = await outputCompleter.future.timeout(outputTimeout);
    print('Script output: ${result.join('\n')}');
  } catch (e) {
    print('Script timed out or failed: $e');
    script.stop(); // Force stop if timeout
  }
  
  // Cleanup
  await scriptFile.delete();
}
```

#### `PyEngineDesktop.startRepl()`
Starts an interactive Python REPL session.

```dart
// Basic REPL usage
Future<void> basicReplUsage() async {
  final repl = await PyEngineDesktop.startRepl();
  
  repl.output.listen((output) => print('REPL: $output'));
  
  repl.send('print("Hello from REPL!")');
  repl.send('2 + 2');
  
  await Future.delayed(Duration(seconds: 2));
  repl.stop();
}

// Advanced REPL with command queue and response tracking
class PythonReplManager {
  PythonRepl? _repl;
  final StreamController<String> _responseController = StreamController<String>();
  final Queue<String> _commandQueue = Queue<String>();
  bool _isProcessingCommand = false;
  
  Stream<String> get responses => _responseController.stream;
  
  Future<void> initialize() async {
    _repl = await PyEngineDesktop.startRepl();
    
    _repl!.output.listen((output) {
      _responseController.add(output);
      
      // Check if command completed (basic detection)
      if (output.contains('>>>') || output.contains('...')) {
        _isProcessingCommand = false;
        _processNextCommand();
      }
    });
  }
  
  Future<String> executeCommand(String command) async {
    final completer = Completer<String>();
    final responseBuffer = <String>[];
    
    late StreamSubscription subscription;
    subscription = responses.listen((output) {
      responseBuffer.add(output);
      
      // Simple completion detection
      if (output.contains('>>>') && responseBuffer.length > 1) {
        subscription.cancel();
        completer.complete(responseBuffer.join('\n'));
      }
    });
    
    _commandQueue.add(command);
    _processNextCommand();
    
    return completer.future.timeout(
      Duration(seconds: 10),
      onTimeout: () {
        subscription.cancel();
        return 'Command timed out';
      },
    );
  }
  
  void _processNextCommand() {
    if (_isProcessingCommand || _commandQueue.isEmpty || _repl == null) return;
    
    _isProcessingCommand = true;
    final command = _commandQueue.removeFirst();
    _repl!.send(command);
  }
  
  void dispose() {
    _repl?.stop();
    _responseController.close();
  }
}

// Usage of advanced REPL manager
Future<void> useAdvancedRepl() async {
  final replManager = PythonReplManager();
  await replManager.initialize();
  
  // Execute commands sequentially
  final result1 = await replManager.executeCommand('import math');
  print('Command 1 result: $result1');
  
  final result2 = await replManager.executeCommand('print(math.pi)');
  print('Command 2 result: $result2');
  
  final result3 = await replManager.executeCommand('x = [1, 2, 3, 4, 5]');
  print('Command 3 result: $result3');
  
  final result4 = await replManager.executeCommand('print(sum(x))');
  print('Command 4 result: $result4');
  
  replManager.dispose();
}
```

#### `PyEngineDesktop.pipInstall(String package)` / `PyEngineDesktop.pipUninstall(String package)`
Manages Python packages using pip.

```dart
// Basic package installation
await PyEngineDesktop.pipInstall('numpy');
await PyEngineDesktop.pipUninstall('numpy');

// Advanced package management with error handling
class PythonPackageManager {
  static Future<bool> installPackage(String packageName, {
    String? version,
    bool upgrade = false,
    void Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Installing $packageName...');
      
      String fullPackageName = packageName;
      if (version != null) {
        fullPackageName = '$packageName==$version';
      }
      
      if (upgrade) {
        // For upgrade, we need to use pip directly
        final repl = await PyEngineDesktop.startRepl();
        repl.send('import subprocess');
        repl.send('subprocess.run(["pip", "install", "--upgrade", "$fullPackageName"])');
        await Future.delayed(Duration(seconds: 5));
        repl.stop();
      } else {
        await PyEngineDesktop.pipInstall(fullPackageName);
      }
      
      onProgress?.call('✅ $packageName installed successfully');
      return true;
    } catch (e) {
      onProgress?.call('❌ Failed to install $packageName: $e');
      return false;
    }
  }
  
  static Future<bool> verifyPackage(String packageName) async {
    try {
      final repl = await PyEngineDesktop.startRepl();
      final completer = Completer<bool>();
      
      repl.output.listen((output) {
        if (output.contains('ImportError') || output.contains('ModuleNotFoundError')) {
          completer.complete(false);
        } else if (output.contains('>>>')) {
          completer.complete(true);
        }
      });
      
      repl.send('import $packageName');
      repl.send('print("$packageName imported successfully")');
      
      final result = await completer.future.timeout(Duration(seconds: 5));
      repl.stop();
      return result;
    } catch (e) {
      return false;
    }
  }
  
  static Future<List<String>> getInstalledPackages() async {
    try {
      final repl = await PyEngineDesktop.startRepl();
      final packages = <String>[];
      final completer = Completer<List<String>>();
      
      repl.output.listen((output) {
        if (output.trim().isNotEmpty && !output.contains('>>>') && !output.contains('...')) {
          // Parse pip list output
          final lines = output.split('\n');
          for (final line in lines) {
            if (line.contains(' ')) {
              final packageName = line.split(' ')[0].trim();
              if (packageName.isNotEmpty && !packages.contains(packageName)) {
                packages.add(packageName);
              }
            }
          }
        }
        if (output.contains('>>>') && packages.isNotEmpty) {
          completer.complete(packages);
        }
      });
      
      repl.send('import subprocess');
      repl.send('result = subprocess.run(["pip", "list"], capture_output=True, text=True)');
      repl.send('print(result.stdout)');
      
      final result = await completer.future.timeout(Duration(seconds: 10));
      repl.stop();
      return result;
    } catch (e) {
      print('Failed to get package list: $e');
      return [];
    }
  }
}

// Usage example
Future<void> managePackages() async {
  final packages = ['numpy', 'pandas', 'matplotlib', 'requests'];
  
  for (final package in packages) {
    final success = await PythonPackageManager.installPackage(
      package,
      onProgress: (message) => print(message),
    );
    
    if (success) {
      final verified = await PythonPackageManager.verifyPackage(package);
      print('$package verification: ${verified ? "✅" : "❌"}');
    }
  }
  
  // List all installed packages
  final installed = await PythonPackageManager.getInstalledPackages();
  print('Installed packages: ${installed.join(", ")}');
}
```

#### `PyEngineDesktop.pythonPath`
Gets the path to the Python executable.

```dart
// Get Python path and system info
Future<void> getPythonInfo() async {
  await PyEngineDesktop.init();
  
  final pythonPath = PyEngineDesktop.pythonPath;
  print('Python executable: $pythonPath');
  
  // Get Python version and system info
  final repl = await PyEngineDesktop.startRepl();
  
  repl.output.listen((output) => print('Info: $output'));
  
  repl.send('import sys');
  repl.send('print("Python version:", sys.version)');
  repl.send('print("Platform:", sys.platform)');
  repl.send('print("Executable:", sys.executable)');
  repl.send('print("Path:", sys.path[:3])');  // First 3 paths
  
  await Future.delayed(Duration(seconds: 2));
  repl.stop();
}
```

### PythonScript

Represents a running Python script process.

```dart
class PythonScriptRunner {
  static Future<Map<String, dynamic>> runScriptWithResults(String scriptPath) async {
    final script = await PyEngineDesktop.startScript(scriptPath);
    final stdout = <String>[];
    final stderr = <String>[];
    final startTime = DateTime.now();
    
    script.stdout.listen((line) => stdout.add(line));
    script.stderr.listen((line) => stderr.add(line));
    
    final exitCode = await script.exitCode;
    final duration = DateTime.now().difference(startTime);
    
    return {
      'exitCode': exitCode,
      'stdout': stdout,
      'stderr': stderr,
      'duration': duration.inMilliseconds,
      'success': exitCode == 0,
    };
  }
}
```

### PythonRepl

Represents an interactive Python REPL session.

```dart
// Complete REPL wrapper with history and state management
class InteractivePythonShell {
  PythonRepl? _repl;
  final List<String> _history = [];
  final Map<String, dynamic> _variables = {};
  
  Future<void> start() async {
    _repl = await PyEngineDesktop.startRepl();
  }
  
  Future<String> execute(String command) async {
    if (_repl == null) throw StateError('REPL not started');
    
    _history.add(command);
    
    final completer = Completer<String>();
    final output = <String>[];
    
    late StreamSubscription subscription;
    subscription = _repl!.output.listen((line) {
      output.add(line);
      if (line.contains('>>>')) {
        subscription.cancel();
        completer.complete(output.join('\n'));
      }
    });
    
    _repl!.send(command);
    return completer.future.timeout(Duration(seconds: 10));
  }
  
  List<String> get history => List.unmodifiable(_history);
  
  void stop() => _repl?.stop();
}
```

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

