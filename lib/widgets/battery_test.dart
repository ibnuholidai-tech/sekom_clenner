import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:async';

class BatteryTest extends StatefulWidget {
  const BatteryTest({super.key});

  @override
  State<BatteryTest> createState() => _BatteryTestState();
}

class _BatteryTestState extends State<BatteryTest> {
  final Battery _battery = Battery();
  int? _batteryLevel;
  BatteryState? _batteryState;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initBattery();
  }

  Future<void> _initBattery() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get initial battery level
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      if (!mounted) return;

      // Listen to battery state changes
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen((
        BatteryState state,
      ) {
        if (mounted) {
          setState(() {
            _batteryState = state;
          });
        }
      });

      setState(() {
        _batteryLevel = level;
        _batteryState = state;
        _isLoading = false;
      });

      // Refresh battery level every 5 seconds
      _refreshTimer ??=
          Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          _refreshBatteryLevel();
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal membaca informasi baterai: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
        });
      }
    } catch (e) {
      // Ignore errors during refresh
    }
  }

  @override
  void dispose() {
    _batteryStateSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Color _getBatteryColor() {
    if (_batteryLevel == null) return Colors.grey;
    if (_batteryLevel! > 60) return Colors.green;
    if (_batteryLevel! > 20) return Colors.orange;
    return Colors.red;
  }

  IconData _getBatteryIcon() {
    if (_batteryState == BatteryState.charging) {
      return Icons.battery_charging_full;
    }
    if (_batteryLevel == null) return Icons.battery_unknown;
    if (_batteryLevel! > 90) return Icons.battery_full;
    if (_batteryLevel! > 60) return Icons.battery_6_bar;
    if (_batteryLevel! > 40) return Icons.battery_4_bar;
    if (_batteryLevel! > 20) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }

  String _getBatteryStateText() {
    switch (_batteryState) {
      case BatteryState.charging:
        return 'Sedang Mengisi';
      case BatteryState.full:
        return 'Penuh';
      case BatteryState.discharging:
        return 'Digunakan';
      case BatteryState.connectedNotCharging:
        return 'Terhubung (Tidak Mengisi)';
      default:
        return 'Tidak Diketahui';
    }
  }

  String _getBatteryHealthText() {
    if (_batteryLevel == null) return 'Tidak Diketahui';
    if (_batteryLevel! > 80) return 'Baik';
    if (_batteryLevel! > 50) return 'Cukup';
    return 'Perlu Perhatian';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Health Test'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.green.shade700),
                    const SizedBox(height: 16),
                    Text(
                      'Memuat info baterai...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _error!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade600,
                            Colors.green.shade800,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _initBattery,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Battery Icon and Level
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getBatteryColor().withOpacity(0.2),
                            _getBatteryColor().withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _getBatteryColor().withOpacity(0.4),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getBatteryColor().withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getBatteryIcon(),
                            size: 120,
                            color: _getBatteryColor(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_batteryLevel ?? 0}%',
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: _getBatteryColor(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getBatteryStateText(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Battery Information Cards
                    _buildInfoCard(
                      'Status Baterai',
                      _getBatteryStateText(),
                      Icons.info_outline,
                      Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Level Baterai',
                      '${_batteryLevel ?? 0}%',
                      Icons.battery_std,
                      _getBatteryColor(),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Kesehatan Baterai',
                      _getBatteryHealthText(),
                      Icons.favorite,
                      _batteryLevel != null && _batteryLevel! > 80
                          ? Colors.green
                          : Colors.orange,
                    ),

                    const SizedBox(height: 32),

                    // Tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tips Merawat Baterai',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTip('Jangan biarkan baterai habis total (0%)'),
                          _buildTip(
                            'Hindari pengisian daya hingga 100% terus-menerus',
                          ),
                          _buildTip(
                            'Gunakan mode hemat baterai saat diperlukan',
                          ),
                          _buildTip('Cabut charger saat baterai sudah penuh'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Refresh Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade600,
                            Colors.green.shade800,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _refreshBatteryLevel,
                        icon: const Icon(Icons.refresh, size: 24),
                        label: const Text(
                          'Refresh Info Baterai',
                          style: TextStyle(
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
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
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
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(fontSize: 14, color: Colors.amber.shade900),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(fontSize: 14, color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
