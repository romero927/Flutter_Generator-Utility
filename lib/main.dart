import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:bitsdojo_window/bitsdojo_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());

  doWhenWindowReady(() {
    final win = appWindow;
    win.maximize();
    win.show();
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Utility App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        iconTheme: IconThemeData(color: Colors.blue),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        iconTheme: IconThemeData(color: Colors.lightBlue),
      ),
      themeMode: _themeMode,
      home: Scaffold(
        body: WindowBorder(
          color: Colors.blue,
          width: 1,
          child: MyHomePage(title: 'Flutter Utility App', toggleTheme: _toggleTheme),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title, required this.toggleTheme}) : super(key: key);

  final String title;
  final VoidCallback toggleTheme;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _uuids = [];
  String _password = '';
  TextEditingController _uuidCountController = TextEditingController(text: '1');
  
  // Password generation options
  int _passwordLength = 12;
  bool _useLowercase = true;
  bool _useUppercase = true;
  bool _useNumbers = true;
  bool _useSymbols = true;
  bool _excludeSimilar = false;
  bool _excludeAmbiguous = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _uuidCountController.dispose();
    super.dispose();
  }

 void _generateUUIDs() {
    setState(() {
      int count = int.tryParse(_uuidCountController.text) ?? 1;
      count = count.clamp(1, 100); // Limit to 100 UUIDs for performance
      _uuids = List.generate(count, (_) => Uuid().v4());
    });
  }

  void _generatePassword() {
    setState(() {
      _password = _generateRandomPassword();
    });
  }

  String _generateRandomPassword() {
    String lowercase = 'abcdefghijklmnopqrstuvwxyz';
    String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    String numbers = '0123456789';
    String symbols = r'!@#$%^&*()_+-=[]{}|;:,.<>?';
    String similarChars = 'o0il1';
    String ambiguousChars = r'{}[]()/\`~;:.,<>';

    String chars = '';
    if (_useLowercase) chars += lowercase;
    if (_useUppercase) chars += uppercase;
    if (_useNumbers) chars += numbers;
    if (_useSymbols) chars += symbols;
    
    if (_excludeSimilar) {
      for (var char in similarChars.split('')) {
        chars = chars.replaceAll(char, '');
      }
    }
    if (_excludeAmbiguous) {
      for (var char in ambiguousChars.split('')) {
        chars = chars.replaceAll(char, '');
      }
    }

    Random rnd = Random.secure();
    return List.generate(_passwordLength, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  void _copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard')),
    );
  }

  String _getPasswordStrength() {
    if (_password.isEmpty) return '';
    
    int score = 0;
    
    // Length
    if (_passwordLength >= 8) score++;
    if (_passwordLength >= 12) score++;
    if (_passwordLength >= 16) score++;
    
    // Character types
    if (_useLowercase) score++;
    if (_useUppercase) score++;
    if (_useNumbers) score++;
    if (_useSymbols) score++;
    
    // Exclusions (these make the password potentially stronger)
    if (_excludeSimilar) score++;
    if (_excludeAmbiguous) score++;
    
    // Evaluate score
    if (score <= 4) return 'Weak';
    if (score <= 6) return 'Moderate';
    if (score <= 8) return 'Strong';
    return 'Very Strong';
  }

  Color _getPasswordStrengthColor() {
    switch (_getPasswordStrength()) {
      case 'Weak':
        return Colors.red;
      case 'Moderate':
        return Colors.orange;
      case 'Strong':
        return Colors.green;
      case 'Very Strong':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _clearUUIDs() {
    setState(() {
      _uuids.clear();
    });
  }

  void _copyUUIDsToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _uuids.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${_uuids.length} UUID(s) to clipboard')),
    );
  }


  void _clearPassword() {
    setState(() {
      _password = '';
    });
  }

  Widget _buildOptionTile(String title, bool value, Function(bool?) onChanged, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

   @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Theme.of(context).iconTheme.color;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.fingerprint, color: iconColor), text: 'UUID'),
            Tab(icon: Icon(Icons.lock, color: iconColor), text: 'Password'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // UUID Tab
          SingleChildScrollView(
            child: Center(
              child: Card(
                margin: EdgeInsets.all(16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.fingerprint, size: 50, color: iconColor),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _uuidCountController,
                              decoration: InputDecoration(
                                labelText: 'Number of UUIDs',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon: Icon(Icons.refresh),
                            label: Text('Generate'),
                            onPressed: _generateUUIDs,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text('Generated UUIDs:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: SelectableText(
                          _uuids.join('\n'),
                          style: TextStyle(fontSize: 16, fontFamily: 'Courier'),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.copy),
                            label: Text('Copy All'),
                            onPressed: _uuids.isNotEmpty ? () => _copyUUIDsToClipboard(context) : null,
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.clear),
                            label: Text('Clear All'),
                            onPressed: _uuids.isNotEmpty ? _clearUUIDs : null,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Password Tab
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Password Generator', style: Theme.of(context).textTheme.titleLarge),
                          SizedBox(height: 20),
                          Text('Password Length: $_passwordLength'),
                          Slider(
                            value: _passwordLength.toDouble(),
                            min: 4,
                            max: 32,
                            divisions: 28,
                            label: _passwordLength.toString(),
                            onChanged: (value) {
                              setState(() {
                                _passwordLength = value.round();
                              });
                            },
                          ),
                          _buildOptionTile('Lowercase Characters', _useLowercase, (value) => setState(() => _useLowercase = value!), Icons.text_fields),
                          _buildOptionTile('Uppercase Characters', _useUppercase, (value) => setState(() => _useUppercase = value!), Icons.text_fields),
                          _buildOptionTile('Numbers', _useNumbers, (value) => setState(() => _useNumbers = value!), Icons.numbers),
                          _buildOptionTile('Symbols', _useSymbols, (value) => setState(() => _useSymbols = value!), Icons.emoji_symbols),
                          _buildOptionTile('Exclude Similar Characters', _excludeSimilar, (value) => setState(() => _excludeSimilar = value!), Icons.remove_circle_outline),
                          _buildOptionTile('Exclude Ambiguous Characters', _excludeAmbiguous, (value) => setState(() => _excludeAmbiguous = value!), Icons.block),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Generated Password:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(_password, style: TextStyle(fontSize: 16, fontFamily: 'Courier')),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Strength: ${_getPasswordStrength()}',
                            style: TextStyle(color: _getPasswordStrengthColor(), fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                icon: Icon(Icons.refresh),
                                label: Text('Generate'),
                                onPressed: _generatePassword,
                              ),
                              ElevatedButton.icon(
                                icon: Icon(Icons.copy),
                                label: Text('Copy'),
                                onPressed: _password.isNotEmpty ? () => _copyToClipboard(_password, context) : null,
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Center(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.clear),
                              label: Text('Clear Password'),
                              onPressed: _password.isNotEmpty ? _clearPassword : null,
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}