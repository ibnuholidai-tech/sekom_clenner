import 'package:flutter/material.dart';
import '../models/system_status.dart';
import '../services/system_service.dart';
import '../widgets/sound_test_lr.dart';
import '../widgets/keyboard_test_complete_fixed.dart';

class QuickActionsSection extends StatefulWidget {
  const QuickActionsSection({super.key});

  @override
  State<QuickActionsSection> createState() => _QuickActionsSectionState();
}

class _QuickActionsSectionState extends State<QuickActionsSection> {
  BatteryStatus _batteryStatus = BatteryStatus();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBatteryInfo();
  }

  Future<void> _loadBatteryInfo() async {
    try {
      final status = await SystemService.getBatteryStatus();
      if (!mounted) return;
      setState(() {
        _batteryStatus = status;
        _loading = false;
      });
    } catch (e) {
      // If battery status fails, use safe defaults
      if (!mounted) return;
      setState(() {
        _batteryStatus = BatteryStatus(
          isPresent: false,
          batteryHealth: 0.0,
          healthStatus: 'Unknown',
        );
        _loading = false;
      });
      print('Battery status error: $e');
    }
  }

  Color _getBatteryColor() {
    if (!_batteryStatus.isPresent) return Colors.grey;
    final health = _batteryStatus.batteryHealth;
    if (health >= 80) return Colors.green;
    if (health >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getBatteryText() {
    if (_loading) return 'Loading...';
    if (!_batteryStatus.isPresent) return 'No Battery';
    try {
      final health = _batteryStatus.batteryHealth;
      if (health == 0.0) return 'N/A';
      final healthStr = health.toStringAsFixed(0);
      final status = _batteryStatus.healthStatus.isNotEmpty
          ? _batteryStatus.healthStatus
          : 'Unknown';
      return '$healthStr% $status';
    } catch (e) {
      print('Battery text error: $e');
      return 'Error';
    }
  }

  void _showKeyboardTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KeyboardTestCompleteFixed(),
      ),
    );
  }

  void _showSoundTest() {
    // Navigate to full screen instead of popup to prevent crashes
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Battery Health Info
            Expanded(
              child: InkWell(
                onTap: _loadBatteryInfo,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getBatteryColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getBatteryColor().withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.battery_charging_full,
                        size: 16,
                        color: _getBatteryColor(),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _loading ? 'Loading...' : _getBatteryText(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getBatteryColor(),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Keyboard Test Button
            Expanded(
              child: InkWell(
                onTap: _showKeyboardTest,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Keyboard',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Sound L/R Test Button
            Expanded(
              child: InkWell(
                onTap: _showSoundTest,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.volume_up,
                        size: 16,
                        color: Colors.purple.shade700,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Sound L/R',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
