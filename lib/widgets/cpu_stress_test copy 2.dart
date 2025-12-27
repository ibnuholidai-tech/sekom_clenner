import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class CpuStressTest extends StatefulWidget {
  const CpuStressTest({super.key});

  @override
  State<CpuStressTest> createState() => _CpuStressTestState();
}

class _CpuStressTestState extends State<CpuStressTest> {
  bool _isCpuTesting = false;
  bool _isMemoryTesting = false;
  final List<Isolate> _cpuIsolates = [];
  final List<Isolate> _memoryIsolates = [];
  final List<SendPort> _memorySendPorts = [];
  int _coreCount = 0;
  String _cpuName = 'Detecting...';
  String _cpuStatus = 'Ready';
  String _memoryStatus = 'Ready';
  Timer? _cpuTimer;
  Timer? _memoryTimer;
  int _cpuElapsedSeconds = 0;
  int _memoryElapsedSeconds = 0;
  int _totalMemoryMB = 0;
  int _usedMemoryMB = 0;
  int _availableMemoryMB = 0;
  double _memoryUsagePercent = 0.0;
  int _allocatedBlocks = 0;
  int _allocationRate = 0;
  String _memoryIntensity = 'Normal';

  @override
  void initState() {
    super.initState();
    _detectCPU();
    _detectMemory();
  }

  @override
  void dispose() {
    _stopCpuTest();
    _stopMemoryTest();
    _cpuTimer?.cancel();
    _memoryTimer?.cancel();
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

  Future<void> _detectMemory() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('wmic', [
          'computersystem',
          'get',
          'TotalPhysicalMemory',
          '/value'
        ]);
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          final lines = output.split('\n');
          
          for (var line in lines) {
            if (line.contains('TotalPhysicalMemory=')) {
              final bytes = int.tryParse(line.split('=')[1].trim()) ?? 0;
              setState(() {
                _totalMemoryMB = (bytes / (1024 * 1024)).round();
              });
            }
          }
        }
      } else if (Platform.isLinux) {
        final result = await Process.run('free', ['-m']);
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          final lines = output.split('\n');
          
          for (var line in lines) {
            if (line.contains('Mem:')) {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length > 1) {
                setState(() {
                  _totalMemoryMB = int.tryParse(parts[1]) ?? 0;
                });
              }
            }
          }
        }
      } else {
        setState(() {
          _totalMemoryMB = 8192;
        });
      }
    } catch (e) {
      setState(() {
        _totalMemoryMB = 8192;
      });
    }
  }

  Future<void> _updateMemoryStats() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('wmic', [
          'OS',
          'get',
          'FreePhysicalMemory',
          '/value'
        ]);
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          final lines = output.split('\n');
          
          for (var line in lines) {
            if (line.contains('FreePhysicalMemory=')) {
              final kb = int.tryParse(line.split('=')[1].trim()) ?? 0;
              setState(() {
                _availableMemoryMB = (kb / 1024).round();
                _usedMemoryMB = _totalMemoryMB - _availableMemoryMB;
                _memoryUsagePercent = (_usedMemoryMB / _totalMemoryMB) * 100;
              });
            }
          }
        }
      } else if (Platform.isLinux) {
        final result = await Process.run('free', ['-m']);
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          final lines = output.split('\n');
          
          for (var line in lines) {
            if (line.contains('Mem:')) {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length > 2) {
                setState(() {
                  _usedMemoryMB = int.tryParse(parts[2]) ?? 0;
                  _availableMemoryMB = int.tryParse(parts[6]) ?? 0;
                  _memoryUsagePercent = (_usedMemoryMB / _totalMemoryMB) * 100;
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating memory stats: $e');
    }
  }

  static void _cpuStressWork(Map<String, dynamic> params) {
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

  static void _memoryStressWork(Map<String, dynamic> params) {
    final SendPort sendPort = params['sendPort'];
    final ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    bool shouldRun = true;
    List<Uint8List> memoryBlocks = [];
    int blockSize = params['blockSize'] ?? (50 * 1024 * 1024);
    int maxBlocks = params['maxBlocks'] ?? 20;
    String pattern = params['pattern'] ?? 'sequential';
    int allocatedCount = 0;

    receivePort.listen((message) {
      if (message == 'stop') {
        shouldRun = false;
        memoryBlocks.clear();
        receivePort.close();
      } else if (message is Map) {
        if (message['action'] == 'setIntensity') {
          blockSize = message['blockSize'];
          maxBlocks = message['maxBlocks'];
          pattern = message['pattern'];
        } else if (message['action'] == 'getStats') {
          sendPort.send({
            'allocatedBlocks': allocatedCount,
            'totalMemory': (allocatedCount * blockSize) ~/ (1024 * 1024),
          });
        }
      }
    });

    while (shouldRun) {
      try {
        if (memoryBlocks.length < maxBlocks) {
          final block = Uint8List(blockSize);
          
          switch (pattern) {
            case 'random':
              for (int i = 0; i < block.length; i += 4096) {
                block[i] = (DateTime.now().millisecondsSinceEpoch % 256);
              }
              break;
            case 'sequential':
              for (int i = 0; i < block.length; i += 1024) {
                block[i] = (i % 256);
              }
              break;
            case 'intensive':
              for (int i = 0; i < block.length; i += 512) {
                block[i] = ((i * 31) % 256);
                if (i % 2048 == 0 && !shouldRun) break;
              }
              break;
            case 'fragmented':
              for (int i = 0; i < block.length; i += 8192) {
                block[i] = (i ~/ 8192) % 256;
              }
              break;
          }
          
          memoryBlocks.add(block);
          allocatedCount++;
          
          if (pattern == 'intensive') {
            for (int i = 0; i < memoryBlocks.length; i++) {
              var currentBlock = memoryBlocks[i];
              for (int j = 0; j < currentBlock.length; j += 16384) {
                currentBlock[j] = (currentBlock[j] + 1) % 256;
              }
            }
          }
        } else {
          if (pattern == 'fragmented') {
            if (memoryBlocks.isNotEmpty) {
              memoryBlocks.removeAt(0);
              allocatedCount--;
            }
          } else {
            for (var block in memoryBlocks) {
              for (int i = 0; i < block.length; i += 4096) {
                block[i] = (block[i] + 1) % 256;
              }
            }
          }
        }
        
        if (pattern == 'intensive') {
          Future.delayed(const Duration(milliseconds: 10));
        } else {
          Future.delayed(const Duration(milliseconds: 50));
        }
        
      } catch (e) {
        memoryBlocks.clear();
        allocatedCount = 0;
      }
    }
  }

  Future<void> _startCpuTest() async {
    if (_isCpuTesting) return;

    try {
      setState(() {
        _isCpuTesting = true;
        _cpuStatus = 'Starting CPU stress test on $_coreCount cores...';
        _cpuElapsedSeconds = 0;
      });

      _cpuIsolates.clear();

      for (int i = 0; i < _coreCount; i++) {
        final receivePort = ReceivePort();
        
        final isolate = await Isolate.spawn(
          _cpuStressWork,
          {'sendPort': receivePort.sendPort},
        );
        
        _cpuIsolates.add(isolate);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() {
        _cpuStatus = 'CPU Stressing $_coreCount cores... (${_cpuElapsedSeconds}s)';
      });

      _cpuTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _cpuElapsedSeconds++;
          _cpuStatus = 'CPU Stressing $_coreCount cores... (${_cpuElapsedSeconds}s)';
        });
      });

    } catch (e) {
      setState(() {
        _isCpuTesting = false;
        _cpuStatus = 'CPU Error: ${e.toString()}';
      });
      _stopCpuTest();
    }
  }

  void _stopCpuTest() {
    if (!_isCpuTesting && _cpuIsolates.isEmpty) return;

    try {
      _cpuTimer?.cancel();
      
      for (var isolate in _cpuIsolates) {
        try {
          isolate.kill(priority: Isolate.immediate);
        } catch (e) {
          debugPrint('Error killing CPU isolate: $e');
        }
      }
      _cpuIsolates.clear();

      if (mounted) {
        setState(() {
          _isCpuTesting = false;
          _cpuStatus = 'CPU test stopped after ${_cpuElapsedSeconds}s';
        });
      }
    } catch (e) {
      debugPrint('Error stopping CPU test: $e');
      if (mounted) {
        setState(() {
          _isCpuTesting = false;
          _cpuStatus = 'CPU stopped with error';
        });
      }
    }
  }

  Future<void> _startMemoryTest() async {
    if (_isMemoryTesting) return;

    try {
      setState(() {
        _isMemoryTesting = true;
        _memoryStatus = 'Starting Memory stress test...';
        _memoryElapsedSeconds = 0;
        _allocatedBlocks = 0;
        _allocationRate = 0;
      });

      _memoryIsolates.clear();
      _memorySendPorts.clear();

      int blockSize = 50 * 1024 * 1024;
      int maxBlocks = 20;
      String pattern = 'sequential';

      switch (_memoryIntensity) {
        case 'Low':
          blockSize = 25 * 1024 * 1024;
          maxBlocks = 10;
          pattern = 'sequential';
          break;
        case 'Normal':
          blockSize = 50 * 1024 * 1024;
          maxBlocks = 20;
          pattern = 'sequential';
          break;
        case 'High':
          blockSize = 75 * 1024 * 1024;
          maxBlocks = 30;
          pattern = 'intensive';
          break;
        case 'Extreme':
          blockSize = 100 * 1024 * 1024;
          maxBlocks = 40;
          pattern = 'intensive';
          break;
      }

      int isolateCount = _memoryIntensity == 'Extreme' ? 6 : 4;

      for (int i = 0; i < isolateCount; i++) {
        final receivePort = ReceivePort();
        
        receivePort.listen((message) {
          if (message is SendPort) {
            _memorySendPorts.add(message);
          } else if (message is Map) {
            if (mounted) {
              setState(() {
                _allocatedBlocks = message['allocatedBlocks'] ?? 0;
              });
            }
          }
        });
        
        final isolate = await Isolate.spawn(
          _memoryStressWork,
          {
            'sendPort': receivePort.sendPort,
            'blockSize': blockSize,
            'maxBlocks': maxBlocks,
            'pattern': pattern,
          },
        );
        
        _memoryIsolates.add(isolate);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      setState(() {
        _memoryStatus = 'Memory Stressing ($_memoryIntensity)... (${_memoryElapsedSeconds}s)';
      });

      _memoryTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        await _updateMemoryStats();
        
        for (var sendPort in _memorySendPorts) {
          sendPort.send({'action': 'getStats'});
        }
        
        setState(() {
          _memoryElapsedSeconds++;
          _allocationRate = (_allocatedBlocks / _memoryElapsedSeconds).round();
          _memoryStatus = 'Memory Stressing ($_memoryIntensity)... ${_memoryUsagePercent.toStringAsFixed(1)}% (${_memoryElapsedSeconds}s)';
        });
      });

    } catch (e) {
      setState(() {
        _isMemoryTesting = false;
        _memoryStatus = 'Memory Error: ${e.toString()}';
      });
      _stopMemoryTest();
    }
  }

  void _stopMemoryTest() {
    if (!_isMemoryTesting && _memoryIsolates.isEmpty) return;

    try {
      _memoryTimer?.cancel();
      
      for (var sendPort in _memorySendPorts) {
        try {
          sendPort.send('stop');
        } catch (e) {
          debugPrint('Error sending stop to isolate: $e');
        }
      }
      
      Future.delayed(const Duration(milliseconds: 500), () {
        for (var isolate in _memoryIsolates) {
          try {
            isolate.kill(priority: Isolate.immediate);
          } catch (e) {
            debugPrint('Error killing Memory isolate: $e');
          }
        }
        _memoryIsolates.clear();
        _memorySendPorts.clear();
      });

      if (mounted) {
        setState(() {
          _isMemoryTesting = false;
          _memoryStatus = 'Memory test stopped after ${_memoryElapsedSeconds}s';
          _allocatedBlocks = 0;
          _allocationRate = 0;
        });
      }
    } catch (e) {
      debugPrint('Error stopping Memory test: $e');
      if (mounted) {
        setState(() {
          _isMemoryTesting = false;
          _memoryStatus = 'Memory stopped with error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade400,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_isCpuTesting || _isMemoryTesting) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Stop Tests?'),
                  content: const Text('Stress tests are running. Stop before closing?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _stopCpuTest();
                        _stopMemoryTest();
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
          'System Stress Test',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.memory, color: Colors.blue, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'CPU Stress Test',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isCpuTesting)
                      const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      _cpuStatus,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _cpuName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Logical Cores: $_coreCount',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isCpuTesting ? _stopCpuTest : _startCpuTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCpuTesting ? Colors.red : Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isCpuTesting ? 'Stop CPU Test' : 'Start CPU Test',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.storage, color: Colors.green, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Memory Stress Test',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!_isMemoryTesting)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Test Intensity:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ['Low', 'Normal', 'High', 'Extreme'].map((intensity) {
                                bool isSelected = _memoryIntensity == intensity;
                                Color color = intensity == 'Low' 
                                    ? Colors.blue
                                    : intensity == 'Normal'
                                    ? Colors.green
                                    : intensity == 'High'
                                    ? Colors.orange
                                    : Colors.red;
                                
                                return ChoiceChip(
                                  label: Text(intensity),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _memoryIntensity = intensity;
                                      });
                                    }
                                  },
                                  selectedColor: color.withOpacity(0.3),
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.grey : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? color : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (_isMemoryTesting)
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: _memoryUsagePercent / 100,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _memoryUsagePercent > 80 ? Colors.red : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    Text(
                      _memoryStatus,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Memory:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$_totalMemoryMB MB',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Used Memory:',
                                style: TextStyle(fontSize: 13),
                              ),
                              Text(
                                '$_usedMemoryMB MB (${_memoryUsagePercent.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _memoryUsagePercent > 80 ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Available:',
                                style: TextStyle(fontSize: 13),
                              ),
                              Text(
                                '$_availableMemoryMB MB',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (_isMemoryTesting) ...[
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Allocated Blocks:',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Text(
                                  '$_allocatedBlocks',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Allocation Rate:',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Text(
                                  '$_allocationRate blocks/s',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Test Mode:',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Text(
                                  _memoryIntensity,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _memoryIntensity == 'Low'
                                        ? Colors.blue
                                        : _memoryIntensity == 'Normal'
                                        ? Colors.green
                                        : _memoryIntensity == 'High'
                                        ? Colors.orange
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isMemoryTesting ? _stopMemoryTest : _startMemoryTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isMemoryTesting ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isMemoryTesting ? 'Stop Memory Test' : 'Start Memory Test',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_isCpuTesting || _isMemoryTesting)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Warning: High system resource usage!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isMemoryTesting && _memoryUsagePercent > 80)
                              const Text(
                                'Memory usage critical - device may become unstable',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}