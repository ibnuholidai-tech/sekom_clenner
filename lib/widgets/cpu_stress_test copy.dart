import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'package:flutter/material.dart';

class CpuStressTest extends StatefulWidget {
  const CpuStressTest({super.key});

  @override
  State<CpuStressTest> createState() => _CpuStressTestState();
}

class _CpuStressTestState extends State<CpuStressTest> {
  bool _isTesting = false;
  final List<Isolate> _isolates = [];
  int _coreCount = 0;
  String _cpuName = 'Detecting...';
  String _status = 'Ready';
  Timer? _safetyTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _detectCPU();
  }

  @override
  void dispose() {
    _stopStressTest();
    _safetyTimer?.cancel();
    super.dispose();
  }

  Future<void> _detectCPU() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('wmic', [
          'cpu',
          'get',
          'Name,NumberOfLogicalProcessors',
          '/value'
        ]);
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          final lines = output.split('\n');
          
          for (var line in lines) {
            if (line.contains('Name=')) {
              setState(() {
                _cpuName = line.split('=')[1].trim();
              });
            }
            if (line.contains('NumberOfLogicalProcessors=')) {
              setState(() {
                _coreCount = int.tryParse(line.split('=')[1].trim()) ?? Platform.numberOfProcessors;
              });
            }
          }
        }
      } else if (Platform.isLinux) {
        final result = await Process.run('lscpu', []);
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          final lines = output.split('\n');
          
          for (var line in lines) {
            if (line.contains('Model name:')) {
              setState(() {
                _cpuName = line.split(':')[1].trim();
              });
            }
            if (line.contains('CPU(s):') && !line.contains('NUMA')) {
              setState(() {
                _coreCount = int.tryParse(line.split(':')[1].trim()) ?? Platform.numberOfProcessors;
              });
            }
          }
        }
      } else {
        setState(() {
          _coreCount = Platform.numberOfProcessors;
          _cpuName = 'CPU';
        });
      }
    } catch (e) {
      setState(() {
        _coreCount = Platform.numberOfProcessors;
        _cpuName = 'Unknown CPU';
      });
    }
  }

  static void _isolateStressWork(Map<String, dynamic> params) {
    final SendPort sendPort = params['sendPort'];
    final ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    bool shouldRun = true;

    receivePort.listen((message) {
      if (message == 'stop') {
        shouldRun = false;
        receivePort.close();
      }
    });

    while (shouldRun) {
      var result = 0;
      for (int i = 0; i < 1000000; i++) {
        result += (i * i + i) % 7;
        if (i % 100000 == 0) {
          result = result % 1000;
          if (!shouldRun) break;
        }
      }
    }
  }

  Future<void> _startStressTest() async {
    if (_isTesting) return;

    try {
      setState(() {
        _isTesting = true;
        _status = 'Starting stress test on $_coreCount cores...';
        _elapsedSeconds = 0;
      });

      _isolates.clear();

      for (int i = 0; i < _coreCount; i++) {
        final receivePort = ReceivePort();
        
        final isolate = await Isolate.spawn(
          _isolateStressWork,
          {'sendPort': receivePort.sendPort},
        );
        
        _isolates.add(isolate);
        
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() {
        _status = 'Stressing $_coreCount cores... (${_elapsedSeconds}s)';
      });

      _safetyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _elapsedSeconds++;
          _status = 'Stressing $_coreCount cores... (${_elapsedSeconds}s)';
        });
      });

    } catch (e) {
      setState(() {
        _isTesting = false;
        _status = 'Error: ${e.toString()}';
      });
      _stopStressTest();
    }
  }

  void _stopStressTest() {
    if (!_isTesting && _isolates.isEmpty) return;

    try {
      _safetyTimer?.cancel();
      
      for (var isolate in _isolates) {
        try {
          isolate.kill(priority: Isolate.immediate);
        } catch (e) {
          debugPrint('Error killing isolate: $e');
        }
      }
      _isolates.clear();

      if (mounted) {
        setState(() {
          _isTesting = false;
          _status = 'Stress test stopped after ${_elapsedSeconds}s';
        });
      }
    } catch (e) {
      debugPrint('Error stopping test: $e');
      if (mounted) {
        setState(() {
          _isTesting = false;
          _status = 'Stopped with error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_isTesting) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Stop Test?'),
                  content: const Text('Stress test is running. Stop before closing?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _stopStressTest();
                        Navigator.pop(context);
                      },
                      child: const Text('Stop & Close'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'CPU Stress Test',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isTesting)
                const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _status,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.memory, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _cpuName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.settings, size: 20, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Logical Cores: $_coreCount',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isTesting ? _stopStressTest : _startStressTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTesting ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isTesting ? 'Stop Stress Test' : 'Stress All Cores',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isTesting)
                Text(
                  'Warning: High CPU usage!',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
            ],
          ),
        ),
      ),
    );
  }
}