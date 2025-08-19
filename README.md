# py_engine_desktop

A Flutter plugin for managing embedded Python runtimes on desktop platforms (Windows, macOS, Linux). This plugin allows you to run Python scripts and interactive REPLs directly from your Flutter desktop applications.

## Features

- 🐍 **Embedded Python Runtime**: Automatically downloads and extracts portable Python distributions
- 🖥️ **Desktop Support**: Works on Windows, macOS, and Linux
- 📜 **Script Execution**: Run Python scripts with real-time stdout/stderr output
- 🔄 **Interactive REPL**: Start Python REPLs and send commands interactively
- 📦 **Package Management**: Install Python packages using pip
- 🚀 **Easy Setup**: One-time initialization handles everything automatically

## Supported Platforms

- ✅ Windows (x64)
- ✅ macOS (x64)
- ✅ Linux (x64)
- ❌ Android (Not supported)
- ❌ iOS (Not supported)
- ❌ Web (Not supported)

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

## Quick Start

### 1. Initialize the Python Engine

```dart
import 'package:py_engine_desktop/py_engine_desktop.dart';

// Initialize the Python engine (one-time setup)
await PyEngineDesktop.init();
```

### 2. Run a Python Script

```dart
// Run a Python script file
final script = await PyEngineDesktop.startScript('/path/to/your/script.py');

// Listen to output
script.stdout.listen((line) => print('OUT: $line'));
script.stderr.listen((line) => print('ERR: $line'));

// Wait for completion
await script.exitCode;

// Or stop manually
script.stop();
```

### 3. Use Interactive REPL

```dart
// Start a Python REPL
final repl = await PyEngineDesktop.startRepl();

// Listen to output
repl.output.listen((output) => print(output));

// Send commands
repl.send('print("Hello from Python!")');
repl.send('import math');
repl.send('print(math.pi)');

// Stop REPL
repl.stop();
```

### 4. Install Python Packages

```dart
// Install packages using pip
await PyEngineDesktop.pipInstall('numpy');
await PyEngineDesktop.pipInstall('requests');
```

## API Reference

### PyEngineDesktop

Main class providing static methods for Python engine management.

#### Methods

- `static Future<void> init()` - Initialize the Python engine
- `static Future<PythonScript> startScript(String path)` - Start a Python script
- `static Future<void> stopScript(PythonScript script)` - Stop a running script
- `static Future<PythonRepl> startRepl()` - Start an interactive REPL
- `static Future<void> stopRepl(PythonRepl repl)` - Stop a REPL
- `static Future<void> pipInstall(String package)` - Install a Python package
- `static String get pythonPath` - Get the path to the Python executable

### PythonScript

Represents a running Python script process.

#### Properties

- `Stream<String> stdout` - Script's standard output stream
- `Stream<String> stderr` - Script's standard error stream
- `Process process` - Underlying process object
- `Future<int> exitCode` - Future that completes when script exits

#### Methods

- `void stop()` - Stop the script execution

### PythonRepl

Represents an interactive Python REPL session.

#### Properties

- `Stream<String> output` - Combined stdout/stderr output stream
- `Process process` - Underlying process object
- `Future<int> exitCode` - Future that completes when REPL exits

#### Methods

- `void send(String code)` - Send a command to the REPL
- `void stop()` - Stop the REPL session

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

## Development

### Building from Source

```bash
git clone <repository-url>
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

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.

