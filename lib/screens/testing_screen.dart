import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/sound_test_lr.dart';
import '../widgets/rgb_screen_test.dart';
import '../widgets/keyboard_test_complete_fixed.dart';
import '../widgets/cpu_stress_test.dart';
import '../widgets/battery_test.dart';
import '../widgets/microphone_test.dart';
import '../widgets/webcam_test.dart';
import '../widgets/network_speed_test.dart';
import '../utils/test_summary.dart';

class TestingScreen extends StatefulWidget {
  const TestingScreen({super.key});

  @override
  State<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  List<String> _summaryLines = [];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final lines = await TestSummary.loadLines();
    if (!mounted) return;
    setState(() {
      _summaryLines = lines;
    });
  }

  Future<void> _copySummary() async {
    final text = _summaryLines.isEmpty
        ? 'Belum ada hasil tes.'
        : _summaryLines.join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ringkasan tes disalin')),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildTestIcon(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: color ?? Colors.blue.shade50,
            shape: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Icon(
                icon,
                size: 36,
                color: iconColor ?? Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openKeyboardTestKhusus() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const KeyboardTestCompleteFixed(),
          ),
        )
        .then((_) => _loadSummary());
  }

  void _openCpuStressTest() {
    Navigator.of(
      context,
    )
        .push(MaterialPageRoute(builder: (context) => const CpuStressTest()))
        .then((_) => _loadSummary());
  }

  void _openBatteryTest() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const BatteryTest()));
  }

  void _openMicrophoneTest() {
    Navigator.of(
      context,
    )
        .push(MaterialPageRoute(builder: (context) => const MicrophoneTest()))
        .then((_) => _loadSummary());
  }

  void _openWebcamTest() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const WebcamTest()));
  }

  void _openNetworkSpeedTest() {
    Navigator.of(
      context,
    )
        .push(MaterialPageRoute(builder: (context) => const NetworkSpeedTest()))
        .then((_) => _loadSummary());
  }

  void _openSoundTest() {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Sound Test L/R'),
              backgroundColor: Colors.blue.shade700,
            ),
            backgroundColor: Colors.grey.shade100,
            body: const Padding(
              padding: EdgeInsets.all(20.0),
              child: SoundTestLR(),
            ),
          ),
        ),
      ).then((_) => _loadSummary());
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal membuka sound test: $e')));
    }
  }

  Future<void> _showRgbTestDialog() async {
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const RgbScreenTest(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuka RGB test: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 24,
            children: [
              SizedBox(
                width: 340,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.summarize, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'Ringkasan Tes Terakhir',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _copySummary,
                              icon: const Icon(Icons.copy, size: 14),
                              label: const Text('Copy'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (_summaryLines.isEmpty)
                          const Text(
                            'Belum ada hasil tes.',
                            style: TextStyle(fontSize: 12),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _summaryLines
                                .map(
                                  (line) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            size: 14, color: Colors.green),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            line,
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Original Tests
              _buildTestIcon(
                Icons.keyboard,
                'Keyboard\nTest',
                _openKeyboardTestKhusus,
                color: Colors.blue.shade50,
                iconColor: Colors.blue.shade700,
              ),
              _buildTestIcon(
                Icons.volume_up,
                'Sound\nL/R',
                _openSoundTest,
                color: Colors.blue.shade50,
                iconColor: Colors.blue.shade700,
              ),
              _buildTestIcon(
                Icons.palette,
                'RGB\nScreen',
                _showRgbTestDialog,
                color: Colors.indigo.shade50,
                iconColor: Colors.indigo.shade700,
              ),
              _buildTestIcon(
                Icons.speed,
                'CPU\nStress',
                _openCpuStressTest,
                color: Colors.blue.shade50,
                iconColor: Colors.blue.shade700,
              ),

              // New Hardware Tests
              _buildTestIcon(
                Icons.battery_charging_full,
                'Battery\nHealth',
                _openBatteryTest,
                color: Colors.green.shade100,
                iconColor: Colors.black87,
              ),
              _buildTestIcon(
                Icons.mic,
                'Microphone\nTest',
                _openMicrophoneTest,
                color: Colors.pink.shade100,
                iconColor: Colors.black87,
              ),
              _buildTestIcon(
                Icons.camera_alt,
                'Webcam\nTest',
                _openWebcamTest,
                color: Colors.lightBlue.shade100,
                iconColor: Colors.black87,
              ),
              _buildTestIcon(
                Icons.network_check,
                'Network\nSpeed',
                _openNetworkSpeedTest,
                color: Colors.teal.shade100,
                iconColor: Colors.black87,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
