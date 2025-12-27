import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../utils/test_summary.dart';

class TestResult {
  final DateTime timestamp;
  final double downloadSpeed;
  final double uploadSpeed;
  final int ping;
  final int jitter;
  final String server;

  TestResult({
    required this.timestamp,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.ping,
    required this.jitter,
    required this.server,
  });
}

class NetworkSpeedTest extends StatefulWidget {
  const NetworkSpeedTest({super.key});

  @override
  State<NetworkSpeedTest> createState() => _NetworkSpeedTestState();
}

class _NetworkSpeedTestState extends State<NetworkSpeedTest> {
  final NetworkInfo _networkInfo = NetworkInfo();

  bool _isTesting = false;
  double _downloadSpeed = 0.0;
  double _uploadSpeed = 0.0;
  int _ping = 0;
  int _jitter = 0;
  String? _ipAddress;
  String? _connectionType;
  String? _error;

  // Test history
  List<TestResult> _testHistory = [];

  // Server selection
  String _selectedServer = 'Cloudflare';
  final Map<String, Map<String, String>> _servers = {
    'Cloudflare': {
      'download': 'https://speed.cloudflare.com/__down?bytes=25000000',
      'upload': 'https://speed.cloudflare.com/__up',
      'ping': 'https://speed.cloudflare.com',
    },
    'Google': {
      'download': 'https://www.google.com',
      'upload': 'https://www.google.com',
      'ping': 'https://www.google.com',
    },
  };

  // Ping measurements for jitter
  List<int> _pingMeasurements = [];

  @override
  void initState() {
    super.initState();
    _getNetworkInfo();
  }

  Future<void> _getNetworkInfo() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      String connectionType = 'Unknown';

      if (connectivityResult == ConnectivityResult.wifi) {
        connectionType = 'WiFi';
      } else if (connectivityResult == ConnectivityResult.ethernet) {
        connectionType = 'Ethernet';
      } else if (connectivityResult == ConnectivityResult.mobile) {
        connectionType = 'Mobile Data';
      }

      String? wifiIP;
      try {
        wifiIP = await _networkInfo.getWifiIP();
      } catch (e) {
        wifiIP = 'N/A';
      }

      if (!mounted) return;
      setState(() {
        _connectionType = connectionType;
        _ipAddress = wifiIP ?? 'N/A';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal mendapatkan info jaringan: $e';
        });
      }
    }
  }

  Future<void> _runSpeedTest() async {
    setState(() {
      _isTesting = true;
      _error = null;
      _downloadSpeed = 0.0;
      _uploadSpeed = 0.0;
      _ping = 0;
      _jitter = 0;
      _pingMeasurements.clear();
    });

    try {
      // Test ping multiple times for jitter calculation
      await _testPingMultiple();

      // Calculate jitter
      _calculateJitter();

      // Test download speed
      await _testDownloadSpeed();

      // Test upload speed
      await _testUploadSpeed();

      // Save to history
      _saveToHistory();
      TestSummary.saveNetwork(
        downloadMbps: _downloadSpeed,
        uploadMbps: _uploadSpeed,
        pingMs: _ping,
      );

      if (!mounted) return;
      setState(() {
        _isTesting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Test gagal: $e';
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _testPingMultiple() async {
    // Test ping 5 times for jitter calculation
    for (int i = 0; i < 5; i++) {
      try {
        final stopwatch = Stopwatch()..start();
        final response = await http
            .head(Uri.parse(_servers[_selectedServer]!['ping']!))
            .timeout(const Duration(seconds: 5));
        stopwatch.stop();

        if (response.statusCode == 200 ||
            response.statusCode == 301 ||
            response.statusCode == 302 ||
            response.statusCode == 405) {
          _pingMeasurements.add(stopwatch.elapsedMilliseconds);
        }
      } catch (e) {
        // Ignore individual ping failures
      }

      // Small delay between pings
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_pingMeasurements.isNotEmpty) {
      if (mounted) {
        setState(() {
          _ping =
              (_pingMeasurements.reduce((a, b) => a + b) /
                      _pingMeasurements.length)
                  .round();
        });
      }
    }
  }

  void _calculateJitter() {
    if (_pingMeasurements.length < 2) {
      _jitter = 0;
      return;
    }

    // Calculate variance in ping times
    double sum = 0;
    for (int i = 1; i < _pingMeasurements.length; i++) {
      sum += (_pingMeasurements[i] - _pingMeasurements[i - 1]).abs();
    }

    if (mounted) {
      setState(() {
        _jitter = (sum / (_pingMeasurements.length - 1)).round();
      });
    }
  }

  Future<void> _testDownloadSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(Uri.parse(_servers[_selectedServer]!['download']!))
          .timeout(const Duration(seconds: 30));
      stopwatch.stop();

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes.length;
        final seconds = stopwatch.elapsedMilliseconds / 1000;
        final mbps = (bytes * 8) / (seconds * 1000000);

        if (mounted) {
          setState(() {
            _downloadSpeed = mbps;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadSpeed = -1;
        });
      }
    }
  }

  Future<void> _testUploadSpeed() async {
    try {
      // Create test data (1MB)
      final testData = List.generate(1024 * 1024, (i) => i % 256);

      final stopwatch = Stopwatch()..start();
      final response = await http
          .post(
            Uri.parse(_servers[_selectedServer]!['upload']!),
            body: testData,
          )
          .timeout(const Duration(seconds: 30));
      stopwatch.stop();

      if (response.statusCode == 200 || response.statusCode == 405) {
        final bytes = testData.length;
        final seconds = stopwatch.elapsedMilliseconds / 1000;
        final mbps = (bytes * 8) / (seconds * 1000000);

        if (mounted) {
          setState(() {
            _uploadSpeed = mbps;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadSpeed = -1;
        });
      }
    }
  }

  void _saveToHistory() {
    if (!mounted) return;
    setState(() {
      _testHistory.insert(
        0,
        TestResult(
          timestamp: DateTime.now(),
          downloadSpeed: _downloadSpeed,
          uploadSpeed: _uploadSpeed,
          ping: _ping,
          jitter: _jitter,
          server: _selectedServer,
        ),
      );

      // Keep only last 10 results
      if (_testHistory.length > 10) {
        _testHistory = _testHistory.sublist(0, 10);
      }
    });
  }

  void _clearHistory() {
    setState(() {
      _testHistory.clear();
    });
  }

  Color _getSpeedColor(double speed) {
    if (speed < 0) return Colors.grey;
    if (speed > 50) return Colors.green;
    if (speed > 10) return Colors.orange;
    return Colors.red;
  }

  String _getSpeedRating(double speed) {
    if (speed < 0) return 'Error';
    if (speed > 100) return 'Sangat Cepat';
    if (speed > 50) return 'Cepat';
    if (speed > 10) return 'Sedang';
    if (speed > 1) return 'Lambat';
    return 'Sangat Lambat';
  }

  Color _getPingColor(int ping) {
    if (ping < 0) return Colors.grey;
    if (ping < 50) return Colors.green;
    if (ping < 100) return Colors.orange;
    return Colors.red;
  }

  Color _getJitterColor(int jitter) {
    if (jitter < 10) return Colors.green;
    if (jitter < 30) return Colors.orange;
    return Colors.red;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Speed Test'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          // Server selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.dns),
            tooltip: 'Select Server',
            onSelected: (server) {
              setState(() {
                _selectedServer = server;
              });
            },
            itemBuilder: (context) => _servers.keys.map((server) {
              return PopupMenuItem(
                value: server,
                child: Row(
                  children: [
                    if (_selectedServer == server)
                      const Icon(Icons.check, size: 20),
                    if (_selectedServer == server) const SizedBox(width: 8),
                    Text(server),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Error Message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade50, Colors.red.shade100],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade100,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Network Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade100, Colors.teal.shade50],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.shade200, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.wifi, size: 64, color: Colors.teal.shade700),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Connection Type',
                      _connectionType ?? 'Unknown',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('IP Address', _ipAddress ?? 'N/A'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Server', _selectedServer),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Speed Test Results
              if (_downloadSpeed > 0 || _uploadSpeed > 0 || _ping > 0) ...[
                // Download Speed
                _buildSpeedCard(
                  'Download Speed',
                  _downloadSpeed,
                  'Mbps',
                  Icons.download,
                  _getSpeedColor(_downloadSpeed),
                  _getSpeedRating(_downloadSpeed),
                ),
                const SizedBox(height: 16),

                // Upload Speed
                _buildSpeedCard(
                  'Upload Speed',
                  _uploadSpeed,
                  'Mbps',
                  Icons.upload,
                  _getSpeedColor(_uploadSpeed),
                  _getSpeedRating(_uploadSpeed),
                ),
                const SizedBox(height: 16),

                // Ping & Jitter
                Row(
                  children: [
                    Expanded(child: _buildPingCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildJitterCard()),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // Test Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade600, Colors.teal.shade800],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : _runSpeedTest,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.speed, size: 24),
                  label: Text(
                    _isTesting ? 'Testing...' : 'Start Speed Test',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Test History
              if (_testHistory.isNotEmpty) ...[
                const Divider(height: 48, thickness: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Test History',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _clearHistory,
                      icon: const Icon(Icons.delete_sweep, size: 20),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._testHistory
                    .map((result) => _buildHistoryCard(result))
                    .toList(),
              ],

              const SizedBox(height: 24),

              // Instructions
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
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Informasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      'Test mengukur download, upload, ping, dan jitter',
                    ),
                    _buildTip(
                      'Pastikan tidak ada download/upload besar saat test',
                    ),
                    _buildTip(
                      'Hasil dapat bervariasi tergantung kondisi jaringan',
                    ),
                    _buildTip(
                      'Ping < 50ms = Baik, 50-100ms = Sedang, >100ms = Lambat',
                    ),
                    _buildTip(
                      'Jitter < 10ms = Baik, 10-30ms = Sedang, >30ms = Buruk',
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSpeedCard(
    String title,
    double speed,
    String unit,
    IconData icon,
    Color color,
    String rating,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      speed >= 0 ? speed.toStringAsFixed(2) : 'Error',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (speed >= 0) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          unit,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  rating,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPingCard() {
    final color = _getPingColor(_ping);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.network_ping, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            'Ping',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            _ping >= 0 ? '$_ping ms' : 'Error',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJitterCard() {
    final color = _getJitterColor(_jitter);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.graphic_eq, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            'Jitter',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            '$_jitter ms',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(TestResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTimestamp(result.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Text(
                  result.server,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHistoryItem(
                  Icons.download,
                  '${result.downloadSpeed.toStringAsFixed(1)} Mbps',
                  'Download',
                ),
              ),
              Expanded(
                child: _buildHistoryItem(
                  Icons.upload,
                  '${result.uploadSpeed.toStringAsFixed(1)} Mbps',
                  'Upload',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildHistoryItem(
                  Icons.network_ping,
                  '${result.ping} ms',
                  'Ping',
                ),
              ),
              Expanded(
                child: _buildHistoryItem(
                  Icons.graphic_eq,
                  '${result.jitter} ms',
                  'Jitter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
