import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:py_engine_desktop/py_engine_desktop.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(const MyApp());
}

class ReplCell {
  final int id;
  final String input;
  final String output;
  final bool isExecuting;
  final DateTime timestamp;

  ReplCell({
    required this.id,
    required this.input,
    this.output = '',
    this.isExecuting = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  ReplCell copyWith({
    String? output,
    bool? isExecuting,
  }) {
    return ReplCell(
      id: id,
      input: input,
      output: output ?? this.output,
      isExecuting: isExecuting ?? this.isExecuting,
      timestamp: timestamp,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Python Engine Desktop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home: const PythonEngineDemo(),
    );
  }
}

class PythonEngineDemo extends StatefulWidget {
  const PythonEngineDemo({super.key});

  @override
  State<PythonEngineDemo> createState() => _PythonEngineDemoState();
}

class _PythonEngineDemoState extends State<PythonEngineDemo> {
  bool _initialized = false;
  String _status = 'Not initialized';
  final List<String> _scriptOutput = [];
  final List<ReplCell> _replCells = [];
  final TextEditingController _replController = TextEditingController();
  final ScrollController _replScrollController = ScrollController();
  PythonRepl? _currentRepl;
  PythonScript? _currentScript;
  String _currentInput = '';
  int _cellCounter = 0;
  
  // Virtual Environment Management
  final List<VirtualEnvironment> _virtualEnvironments = [];
  final TextEditingController _venvNameController = TextEditingController();
  final TextEditingController _venvPathController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  VirtualEnvironment? _activeVenv;
  bool _isCreatingVenv = false;
  
  @override
  void initState() {
    super.initState();
    _initializePython();
  }

  Future<void> _initializePython() async {
    final startTime = DateTime.now();
    
    setState(() {
      _status = 'Initializing Python engine on ${Platform.operatingSystem}...';
    });
    
    print('🐍 Starting Python engine initialization...');

    try {
      await PyEngineDesktop.init();
      
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      final pythonPath = PyEngineDesktop.pythonPath;
      
      setState(() {
        _initialized = true;
        _status = 'Python engine initialized successfully!\n'
                 'Platform: ${Platform.operatingSystem}\n'
                 'Python Path: $pythonPath\n'
                 'Initialization Time: ${duration}ms';
      });
      
      print('✅ Python engine ready - Path: $pythonPath');
      print('⏱️ Initialization completed in ${duration}ms');
      
      // Load virtual environments after initialization
      await _loadVirtualEnvironments();
      
    } catch (e) {
      setState(() {
        _status = 'Failed to initialize Python engine: $e';
      });
      print('❌ Python engine initialization failed: $e');
    }
  }

  Future<void> _runHelloScript() async {
    if (!_initialized) return;

    setState(() {
      _scriptOutput.clear();
      _status = 'Running hello.py script...';
    });
    
    print('🐍 Executing Python script: hello.py');

    try {
      final byteData = await rootBundle.load('assets/hello.py');
      final tempDir = await getTemporaryDirectory();
      final scriptFile = File(path.join(tempDir.path, 'hello.py'));
      await scriptFile.writeAsBytes(byteData.buffer.asUint8List());

      _currentScript = await PyEngineDesktop.startScript(scriptFile.path);
      
      _currentScript!.stdout.listen((line) {
        print('📤 STDOUT received: $line');
        setState(() {
          _scriptOutput.add(line);
        });
      });

      _currentScript!.stderr.listen((line) {
        print('📤 STDERR received: $line');
        setState(() {
          _scriptOutput.add('ERROR: $line');
        });
      });

      await _currentScript!.exitCode;
      setState(() {
        _status = 'Script completed';
        _currentScript = null;
      });
      print('✅ Python script completed successfully');
      print('📋 Script output lines captured: ${_scriptOutput.length}');
    } catch (e) {
      setState(() {
        _status = 'Script error: $e';
      });
      print('❌ Python script error: $e');
    }
  }

  Future<void> _startRepl() async {
    if (!_initialized || _currentRepl != null) return;

    setState(() {
      _replCells.clear();
      _status = 'Starting Python REPL...';
    });

    try {
      _currentRepl = await PyEngineDesktop.startRepl();
      
      _currentRepl!.output.listen((output) {
        _handleReplOutput(output);
      });

      setState(() {
        _status = 'REPL started - ready for commands';
      });
      print('🐍 Python REPL started successfully');
    } catch (e) {
      setState(() {
        _status = 'REPL error: $e';
      });
      print('❌ Python REPL error: $e');
    }
  }

  void _handleReplOutput(String output) {
    if (_replCells.isEmpty) return;
    
    setState(() {
      final lastCell = _replCells.last;
      final updatedCell = lastCell.copyWith(
        output: lastCell.output + output,
        isExecuting: !output.contains('>>>') && !output.contains('...'),
      );
      _replCells[_replCells.length - 1] = updatedCell;
    });
    
    _scrollToBottom();
  }

  void _sendReplCommand() {
    if (_currentRepl == null || _replController.text.isEmpty) return;

    final command = _replController.text.trim();
    if (command.isEmpty) return;

    setState(() {
      _cellCounter++;
      _replCells.add(ReplCell(
        id: _cellCounter,
        input: command,
        isExecuting: true,
      ));
    });

    _currentRepl!.send(command);
    _replController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_replScrollController.hasClients) {
        _replScrollController.animateTo(
          _replScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _stopRepl() {
    if (_currentRepl == null) return;

    _currentRepl!.stop();
    setState(() {
      _currentRepl = null;
      _status = 'REPL stopped';
    });
  }

  Future<void> _installPackage(String packageName) async {
    if (!_initialized) return;

    setState(() {
      _status = 'Installing $packageName package...';
    });

    try {
      await PyEngineDesktop.pipInstall(packageName);
      setState(() {
        _status = '$packageName installed successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to install $packageName: $e';
      });
    }
  }

  Future<void> _uninstallPackage(String packageName) async {
    if (!_initialized) return;

    setState(() {
      _status = 'Uninstalling $packageName package...';
    });

    try {
      await PyEngineDesktop.pipUninstall(packageName);
      setState(() {
        _status = '$packageName uninstalled successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to uninstall $packageName: $e';
      });
    }
  }

  void _addPredefinedCommand(String command) {
    if (_currentRepl == null) return;
    
    _replController.text = command;
  }

  void _runPredefinedCommands(List<String> commands) {
    if (_currentRepl == null) return;

    for (final command in commands) {
      setState(() {
        _cellCounter++;
        _replCells.add(ReplCell(
          id: _cellCounter,
          input: command,
          isExecuting: true,
        ));
      });
      _currentRepl!.send(command);
    }
    _scrollToBottom();
  }

  // Virtual Environment Management Methods

  Future<void> _loadVirtualEnvironments() async {
    if (!_initialized) return;
    
    try {
      // Get default venv directory (user documents/venvs)
      final docsDir = await getApplicationDocumentsDirectory();
      final venvDir = Directory(path.join(docsDir.path, 'python_venvs'));
      
      if (!await venvDir.exists()) {
        await venvDir.create(recursive: true);
      }
      
      final venvs = await PyEngineDesktop.listVirtualEnvironments(venvDir.path);
      final activeVenv = PyEngineDesktop.activeVirtualEnvironment;
      
      setState(() {
        _virtualEnvironments.clear();
        _virtualEnvironments.addAll(venvs);
        _activeVenv = activeVenv;
      });
    } catch (e) {
      print('Error loading virtual environments: $e');
    }
  }

  Future<void> _createVirtualEnvironment() async {
    if (!_initialized || _isCreatingVenv) return;
    
    final name = _venvNameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Please enter a virtual environment name');
      return;
    }
    
    setState(() {
      _isCreatingVenv = true;
      _status = 'Creating virtual environment: $name...';
    });
    
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final venvDir = Directory(path.join(docsDir.path, 'python_venvs'));
      final venvPath = path.join(venvDir.path, name);
      
      final venv = await PyEngineDesktop.createVirtualEnvironment(venvPath, name: name);
      
      setState(() {
        _virtualEnvironments.add(venv);
        _status = 'Virtual environment "$name" created successfully';
        _venvNameController.clear();
      });
      
      _showSnackBar('Virtual environment "$name" created successfully!');
    } catch (e) {
      setState(() {
        _status = 'Failed to create virtual environment: $e';
      });
      _showSnackBar('Failed to create virtual environment: $e');
    } finally {
      setState(() {
        _isCreatingVenv = false;
      });
    }
  }

  Future<void> _activateVirtualEnvironment(VirtualEnvironment venv) async {
    if (!_initialized) return;
    
    try {
      await PyEngineDesktop.activateVirtualEnvironment(venv.path);
      setState(() {
        _activeVenv = venv.copyWith(isActive: true);
        _status = 'Activated virtual environment: ${venv.name}';
      });
      _showSnackBar('Activated virtual environment: ${venv.name}');
    } catch (e) {
      _showSnackBar('Failed to activate virtual environment: $e');
    }
  }

  void _deactivateVirtualEnvironment() {
    if (_activeVenv == null) return;
    
    PyEngineDesktop.deactivateVirtualEnvironment();
    setState(() {
      final oldName = _activeVenv!.name;
      _activeVenv = null;
      _status = 'Deactivated virtual environment: $oldName';
    });
    _showSnackBar('Deactivated virtual environment');
  }

  Future<void> _deleteVirtualEnvironment(VirtualEnvironment venv) async {
    if (!_initialized) return;
    
    try {
      await PyEngineDesktop.deleteVirtualEnvironment(venv.path);
      setState(() {
        _virtualEnvironments.remove(venv);
        if (_activeVenv?.path == venv.path) {
          _activeVenv = null;
        }
        _status = 'Deleted virtual environment: ${venv.name}';
      });
      _showSnackBar('Deleted virtual environment: ${venv.name}');
    } catch (e) {
      _showSnackBar('Failed to delete virtual environment: $e');
    }
  }

  Future<void> _installRequirementsFromJson() async {
    if (_activeVenv == null) {
      _showSnackBar('Please activate a virtual environment first');
      return;
    }
    
    final jsonText = _requirementsController.text.trim();
    if (jsonText.isEmpty) {
      _showSnackBar('Please enter requirements JSON');
      return;
    }
    
    setState(() {
      _status = 'Installing packages from requirements...';
    });
    
    try {
      await PyEngineDesktop.installRequirementsFromJson(jsonText);
      setState(() {
        _status = 'Packages installed successfully in ${_activeVenv!.name}';
      });
      _showSnackBar('Packages installed successfully!');
    } catch (e) {
      setState(() {
        _status = 'Failed to install packages: $e';
      });
      _showSnackBar('Failed to install packages: $e');
    }
  }

  Future<void> _exportRequirements() async {
    if (_activeVenv == null) {
      _showSnackBar('Please activate a virtual environment first');
      return;
    }
    
    try {
      final requirementsJson = await PyEngineDesktop.exportRequirementsAsJson(
        name: _activeVenv!.name,
        description: 'Exported from ${_activeVenv!.name}',
      );
      
      setState(() {
        _requirementsController.text = requirementsJson;
      });
      
      _showSnackBar('Requirements exported successfully!');
    } catch (e) {
      _showSnackBar('Failed to export requirements: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Hero Section
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Python Engine Desktop',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.terminal,
                        size: 48,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Embedded Python Runtime',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Status Card with better design
                _buildStatusCard(context),
                // Script Execution Section
                _buildScriptCard(context),
                // Python REPL Section  
                _buildReplCard(context),
                // Package Management Section
                _buildPackageManagementCard(context),
                // Virtual Environment Management Section
                _buildVirtualEnvironmentCard(context),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _initialized ? Icons.check_circle : Icons.pending,
                  color: _initialized ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Python Engine Status',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _status,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_initialized) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Python runtime initialized and ready',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScriptCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle_filled,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Script Execution',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Execute Python scripts with the embedded runtime',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _initialized && _currentScript == null ? _runHelloScript : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run hello.py'),
                ),
                if (_currentScript != null) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      _currentScript?.stop();
                      setState(() {
                        _currentScript = null;
                        _status = 'Script stopped';
                      });
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ],
              ],
            ),
            if (_scriptOutput.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Output',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _scriptOutput.join('\n'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.terminal,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Interactive Python Shell',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _initialized && _currentRepl == null ? _startRepl : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start REPL'),
                ),
                const SizedBox(width: 8),
                if (_currentRepl != null)
                  OutlinedButton.icon(
                    onPressed: _stopRepl,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Interactive Python environment for testing and experimentation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (_currentRepl != null) ...[
              const SizedBox(height: 20),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // REPL cells display
                    Expanded(
                      child: _replCells.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.code,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Start typing Python commands below',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _replScrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _replCells.length,
                              itemBuilder: (context, index) {
                                final cell = _replCells[index];
                                return _buildReplCell(cell);
                              },
                            ),
                    ),
                    // Input area
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                        ),
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            '[${_cellCounter + 1}]:',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _replController,
                              decoration: const InputDecoration(
                                hintText: 'Enter Python command...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                              maxLines: null,
                              onSubmitted: (_) => _sendReplCommand(),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _sendReplCommand,
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Run'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Quick commands
              Text(
                'Quick Commands',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickCommandChip('import numpy as np', Icons.functions),
                  _buildQuickCommandChip('import pandas as pd', Icons.table_chart),
                  _buildQuickCommandChip('print("Hello, World!")', Icons.print),
                  _buildQuickCommandChip('help()', Icons.help_outline),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPackageManagementCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.extension,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Package Management',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Install and manage Python packages with pip',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Popular Packages',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildModernPackageCard('numpy', 'Scientific computing', Icons.functions, Colors.blue),
                _buildModernPackageCard('pandas', 'Data manipulation', Icons.table_chart, Colors.green),
                _buildModernPackageCard('matplotlib', 'Plotting library', Icons.insert_chart, Colors.orange),
                _buildModernPackageCard('requests', 'HTTP library', Icons.http, Colors.purple),
                _buildModernPackageCard('flask', 'Web framework', Icons.web, Colors.red),
                _buildModernPackageCard('pillow', 'Image processing', Icons.image, Colors.teal),
              ],
            ),
            if (_currentRepl != null) ...[
              const SizedBox(height: 24),
              Text(
                'Quick Tests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildTestButton(
                    'Test NumPy',
                    Icons.science,
                    Colors.blue,
                    () => _runPredefinedCommands([
                      'import numpy as np',
                      'print("NumPy version:", np.__version__)',
                      'arr = np.array([1, 2, 3, 4, 5])',
                      'print("Array:", arr)',
                      'print("Mean:", np.mean(arr))',
                    ]),
                  ),
                  _buildTestButton(
                    'Test Pandas',
                    Icons.table_chart,
                    Colors.green,
                    () => _runPredefinedCommands([
                      'import pandas as pd',
                      'print("Pandas version:", pd.__version__)',
                      'df = pd.DataFrame({"A": [1, 2, 3], "B": [4, 5, 6]})',
                      'print("DataFrame:")',
                      'print(df)',
                    ]),
                  ),
                  _buildTestButton(
                    'Test Requests',
                    Icons.http,
                    Colors.purple,
                    () => _runPredefinedCommands([
                      'import requests',
                      'print("Requests version:", requests.__version__)',
                      'response = requests.get("https://httpbin.org/json")',
                      'print("Status code:", response.status_code)',
                    ]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplCell(ReplCell cell) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '[${cell.id}]:',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  cell.input,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
              if (cell.isExecuting)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
            ],
          ),
          // Output
          if (cell.output.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                cell.output,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickCommandChip(String command, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(
        command,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
      onPressed: () => _addPredefinedCommand(command),
    );
  }

  Widget _buildModernPackageCard(String packageName, String description, IconData icon, Color color) {
    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      packageName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32,
                    height: 24,
                    child: IconButton(
                      onPressed: _initialized ? () => _installPackage(packageName) : null,
                      icon: Icon(Icons.download, size: 14, color: Colors.green.shade600),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 32,
                    height: 24,
                    child: IconButton(
                      onPressed: _initialized ? () => _uninstallPackage(packageName) : null,
                      icon: Icon(Icons.delete, size: 14, color: Colors.red.shade600),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildVirtualEnvironmentCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.computer,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Virtual Environment Management',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Create and manage isolated Python environments',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            
            // Active Environment Status
            if (_activeVenv != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Environment: ${_activeVenv!.name}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Python ${_activeVenv!.pythonVersion ?? 'Unknown'}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _deactivateVirtualEnvironment,
                      child: const Text('Deactivate'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Create New Environment
            Text(
              'Create New Environment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _venvNameController,
                    decoration: const InputDecoration(
                      labelText: 'Environment Name',
                      hintText: 'e.g., data_science_env',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _initialized && !_isCreatingVenv ? _createVirtualEnvironment : null,
                  icon: _isCreatingVenv 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isCreatingVenv ? 'Creating...' : 'Create'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Existing Environments
            Text(
              'Existing Environments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_virtualEnvironments.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No virtual environments found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _virtualEnvironments.length,
                itemBuilder: (context, index) {
                  final venv = _virtualEnvironments[index];
                  final isActive = _activeVenv?.path == venv.path;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        isActive ? Icons.check_circle : Icons.folder,
                        color: isActive ? Colors.green : colorScheme.primary,
                      ),
                      title: Text(
                        venv.name,
                        style: TextStyle(
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        'Python ${venv.pythonVersion ?? 'Unknown'} • ${venv.path}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isActive)
                            IconButton(
                              onPressed: () => _activateVirtualEnvironment(venv),
                              icon: const Icon(Icons.play_arrow),
                              tooltip: 'Activate',
                            ),
                          IconButton(
                            onPressed: () => _deleteVirtualEnvironment(venv),
                            icon: const Icon(Icons.delete),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            
            const SizedBox(height: 24),
            
            // Requirements Management
            Text(
              'Requirements Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _requirementsController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Enter requirements JSON here...\n\nExample:\n{\n  "requirements": [\n    {"package": "numpy", "version": ">=1.20.0"},\n    {"package": "pandas", "version": "latest"}\n  ],\n  "name": "my_environment"\n}',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _activeVenv != null ? _installRequirementsFromJson : null,
                  icon: const Icon(Icons.download),
                  label: const Text('Install'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _activeVenv != null ? _exportRequirements : null,
                  icon: const Icon(Icons.upload),
                  label: const Text('Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentScript?.stop();
    _currentRepl?.stop();
    _replController.dispose();
    _replScrollController.dispose();
    _venvNameController.dispose();
    _venvPathController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }
}
