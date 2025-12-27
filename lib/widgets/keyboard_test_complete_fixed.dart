import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardTestCompleteFixed extends StatefulWidget {
  const KeyboardTestCompleteFixed({super.key});

  @override
  State<KeyboardTestCompleteFixed> createState() => _KeyboardTestCompleteFixedState();
}

class _KeyboardTestCompleteFixedState extends State<KeyboardTestCompleteFixed> {
  final Map<String, bool> _keyPressed = {};
  final Map<String, bool> _keyActive = {};
  final FocusNode _focusNode = FocusNode();
  final List<String> _history = [];
  final ScrollController _scrollController = ScrollController();
  
  int _totalPresses = 0;
  int _uniquePressed = 0;

  @override
  void initState() {
    super.initState();
    _initializeKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeKeys() {
    final allKeys = [
      'Esc', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12',
      'Insert', 'Home', 'PgUp', 'Delete', 'End', 'PgDn',
      '`', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 'Backspace',
      'Tab', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']', '\\',
      'Caps', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', "'", 'Enter',
      'Shift', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', ',', '.', '/', 'Shift',
      'Ctrl', 'Win', 'Alt', 'Space', 'Alt', 'Ctrl',
      '↑', '↓', '←', '→',
    ];

    for (final key in allKeys) {
      if (key != 'Space') {
        _keyPressed[key] = false;
        _keyActive[key] = false;
      }
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    final keyLabel = _getKeyLabel(event.logicalKey);
    if (keyLabel == null || keyLabel.isEmpty) return;

    setState(() {
      if (event is KeyDownEvent) {
        _keyPressed[keyLabel] = true;
        _keyActive[keyLabel] = true;
        _totalPresses++;
        _history.add(keyLabel);
        
        _uniquePressed = _keyPressed.entries
            .where((entry) => entry.value && entry.key != 'Space')
            .length;
        
        // Auto-scroll ke tombol terbaru
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
        
        // Auto-focus kembali setelah key press
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      } else if (event is KeyUpEvent) {
        _keyActive[keyLabel] = false;
      }
    });
  }

  String? _getKeyLabel(LogicalKeyboardKey key) {
    // Handle semua karakter khusus
    final keyLabel = key.keyLabel;
    
    // Handle tanda kutip ganda
    if (keyLabel == '"' || keyLabel == 'Quote' || keyLabel == 'DoubleQuote') {
      return '"';
    }
    
    // Handle tanda kutip tunggal
    if (keyLabel == "'" || keyLabel == 'Apostrophe' || keyLabel == 'SingleQuote') {
      return "'";
    }
    
    // Handle backslash
    if (keyLabel == '\\' || keyLabel == 'Backslash') {
      return '\\';
    }
    
    // Handle backtick
    if (keyLabel == '`' || keyLabel == 'Backquote') {
      return '`';
    }

    final keyMap = {
      LogicalKeyboardKey.escape: 'Esc',
      LogicalKeyboardKey.backspace: 'Backspace',
      LogicalKeyboardKey.tab: 'Tab',
      LogicalKeyboardKey.enter: 'Enter',
      LogicalKeyboardKey.space: 'Space',
      LogicalKeyboardKey.shiftLeft: 'Shift',
      LogicalKeyboardKey.shiftRight: 'Shift',
      LogicalKeyboardKey.controlLeft: 'Ctrl',
      LogicalKeyboardKey.controlRight: 'Ctrl',
      LogicalKeyboardKey.altLeft: 'Alt',
      LogicalKeyboardKey.altRight: 'Alt',
      LogicalKeyboardKey.metaLeft: 'Win',
      LogicalKeyboardKey.metaRight: 'Win',
      LogicalKeyboardKey.capsLock: 'Caps',
      LogicalKeyboardKey.delete: 'Delete',
      LogicalKeyboardKey.insert: 'Insert',
      LogicalKeyboardKey.home: 'Home',
      LogicalKeyboardKey.end: 'End',
      LogicalKeyboardKey.pageUp: 'PgUp',
      LogicalKeyboardKey.pageDown: 'PgDn',
      LogicalKeyboardKey.arrowUp: '↑',
      LogicalKeyboardKey.arrowDown: '↓',
      LogicalKeyboardKey.arrowLeft: '←',
      LogicalKeyboardKey.arrowRight: '→',
    };

    return keyMap[key] ?? (keyLabel.isEmpty ? null : keyLabel);
  }

  Widget _buildKey(String key) {
    final isPressed = _keyPressed[key] ?? false;
    final isActive = _keyActive[key] ?? false;

    Color backgroundColor;
    Color textColor;

    if (isActive) {
      backgroundColor = Colors.green;
      textColor = Colors.white;
    } else if (isPressed) {
      backgroundColor = Colors.blue.withOpacity(0.3);
      textColor = Colors.blue[900]!;
    } else {
      backgroundColor = Colors.grey[200]!;
      textColor = Colors.black87;
    }

    double width = 60;
    switch (key) {
      case 'Backspace': width = 100; break;
      case 'Tab': width = 75; break;
      case 'Caps': width = 85; break;
      case 'Enter': width = 100; break;
      case 'Shift': width = 110; break;
      case 'Ctrl': width = 75; break;
      case 'Alt': width = 75; break;
      case 'Win': width = 75; break;
      case 'Space': width = 280; break;
      case '↑': case '↓': case '←': case '→': width = 65; break;
      case 'Insert': case 'Home': case 'PgUp': case 'Delete': case 'End': case 'PgDn': width = 70; break;
      case '"': width = 45; break;
      case "'": width = 45; break;
      case '\\': width = 45; break;
    }

    return Container(
      width: width,
      height: 50,
      margin: const EdgeInsets.all(2),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        elevation: isActive ? 3 : 1,
        child: Center(
          child: Text(
            key,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildArrowKeys() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 200),
        _buildKey('←'),
        const SizedBox(width: 5),
        Column(
          children: [
            _buildKey('↑'),
            const SizedBox(height: 5),
            _buildKey('↓'),
          ],
        ),
        const SizedBox(width: 5),
        _buildKey('→'),
        const SizedBox(width: 200),
      ],
    );
  }

  void _resetTest() {
    setState(() {
      _initializeKeys();
      _totalPresses = 0;
      _uniquePressed = 0;
      _history.clear();
    });
  }

  int getTotalKeys() {
    return _keyPressed.keys.where((key) => key != 'Space').length;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Keyboard Test Khusus'),
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Kembali ke Menu Testing',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetTest,
              tooltip: 'Reset Test',
            ),
          ],
        ),
        body: Row(
          children: [
            // Main keyboard area
            Expanded(
              flex: 3,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                _totalPresses.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Text(
                                'Total Presses',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                _uniquePressed.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Text(
                                'Unique Pressed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                (getTotalKeys() - _uniquePressed).toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const Text(
                                'Not Pressed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildRow(['Esc', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12']),
                            const SizedBox(height: 8),
                            _buildRow(['Insert', 'Home', 'PgUp', 'Delete', 'End', 'PgDn']),
                            const SizedBox(height: 16),
                            _buildRow(['`', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 'Backspace']),
                            _buildRow(['Tab', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']', '\\']),
                            _buildRow(['Caps', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', '"', 'Enter']),
                            _buildRow(['Shift', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', ',', '.', '/', 'Shift']),
                            _buildRow(['Ctrl', 'Win', 'Alt', 'Space', 'Alt', 'Ctrl']),
                            const SizedBox(height: 16),
                            _buildArrowKeys(),
                          ],
                        ),
                      ),
                      // const SizedBox(height: 20),
                      // ElevatedButton.icon(
                      //   onPressed: _resetTest,
                      //   icon: const Icon(Icons.refresh),
                      //   label: const Text('Reset Test (kecuali Space)'),
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.blue,
                      //     foregroundColor: Colors.white,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
            
            // History panel
            Container(
              width: 250,
              color: Colors.grey[200],
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue,
                    child: Row(
                      children: [
                        const Text(
                          'Riwayat Tombol',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _history.clear();
                            });
                          },
                          tooltip: 'Hapus Riwayat',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              _history[index],
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: Text(
                              '#${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
