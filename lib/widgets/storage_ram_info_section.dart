import 'package:flutter/material.dart';
import '../services/system_service.dart';

class StorageRamInfoSection extends StatefulWidget {
  const StorageRamInfoSection({super.key});

  @override
  State<StorageRamInfoSection> createState() => _StorageRamInfoSectionState();
}

class _StorageRamInfoSectionState extends State<StorageRamInfoSection> {
  List<Map<String, dynamic>> _disks = [];
  Map<String, dynamic> _ramInfo = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    setState(() {
      _loading = true;
    });

    try {
      final disks = await SystemService.getPhysicalDiskInfo();
      final ram = await SystemService.getRamInfo();

      if (!mounted) return;
      setState(() {
        _disks = disks;
        _ramInfo = ram;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Color _getHealthColor(int health) {
    if (health >= 90) return Colors.green;
    if (health >= 75) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.storage, color: Colors.blue, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Storage & RAM Info',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_loading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.refresh, size: 16),
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                    onPressed: _loadInfo,
                  ),
              ],
            ),
            SizedBox(height: 8),

            // RAM Info
            if (_ramInfo.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final totalBytes = _ramInfo['totalBytes'] ?? 0;
                  final totalGB = totalBytes / (1024 * 1024 * 1024);

                  // Color based on capacity
                  Color bgColor;
                  Color borderColor;
                  Color iconColor;
                  Color textColor;
                  bool showWarning = false;

                  if (totalGB > 10) {
                    // > 10 GB: Red with warning - MORE PROMINENT
                    bgColor = Colors.red.shade100;
                    borderColor = Colors.red.shade400;
                    iconColor = Colors.red.shade700;
                    textColor = Colors.red.shade900;
                    showWarning = true;
                  } else if (totalGB >= 7 && totalGB <= 10) {
                    // 7-10 GB: Blue
                    bgColor = Colors.blue.shade50;
                    borderColor = Colors.blue.shade200;
                    iconColor = Colors.blue;
                    textColor = Colors.blue.shade700;
                  } else {
                    // < 7 GB: Default gray
                    bgColor = Colors.grey.shade50;
                    borderColor = Colors.grey.shade300;
                    iconColor = Colors.grey.shade600;
                    textColor = Colors.grey.shade700;
                  }

                  return Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: borderColor,
                        width: showWarning ? 2.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.memory, color: iconColor, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'RAM Total:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          _ramInfo['totalText'] ?? '-',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (showWarning) ...[
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade400,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  color: Colors.red.shade900,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'HIGH',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 8),
            ],

            // Disk Info
            if (_disks.isEmpty && !_loading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No disk information available',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),

            if (_disks.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _disks.length,
                  itemBuilder: (context, index) {
                    final disk = _disks[index];
                    final diskNumber = disk['diskNumber'] ?? 0;
                    final model = disk['model'] ?? 'Unknown';
                    final sizeText = disk['sizeText'] ?? '';
                    final sizeBytes = disk['sizeBytes'] ?? 0;
                    final health = (disk['health'] is int)
                        ? disk['health'] as int
                        : 100;
                    final temperature = disk['temperature'];
                    final mediaType = disk['mediaType'] ?? 'HDD';
                    final healthColor = _getHealthColor(health);

                    // Calculate size in GB
                    final sizeGB = sizeBytes / (1024 * 1024 * 1024);

                    // Color and icon based on capacity for SSD
                    Color diskIconColor;
                    Color containerBgColor;
                    Color containerBorderColor;
                    IconData diskIcon;
                    bool showWarning = false;

                    if (mediaType.toUpperCase().contains('SSD')) {
                      if (sizeGB > 300) {
                        // > 300 GB: Red with warning - VERY PROMINENT
                        diskIconColor = Colors.red.shade700;
                        containerBgColor = Colors.red.shade100;
                        containerBorderColor = Colors.red.shade400;
                        showWarning = true;
                      } else if (sizeGB >= 200 && sizeGB <= 300) {
                        // 200-300 GB: Blue
                        diskIconColor = Colors.blue;
                        containerBgColor = Colors.blue.shade50;
                        containerBorderColor = Colors.blue.shade200;
                      } else {
                        // < 200 GB: Default
                        diskIconColor = Colors.grey.shade600;
                        containerBgColor = Colors.grey.shade50;
                        containerBorderColor = Colors.grey.shade300;
                      }
                      diskIcon = Icons.flash_on;
                    } else {
                      // HDD: Default
                      diskIcon = Icons.storage;
                      diskIconColor = Colors.grey.shade700;
                      containerBgColor = Colors.grey.shade50;
                      containerBorderColor = Colors.grey.shade300;
                    }

                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: containerBorderColor,
                          width: showWarning ? 2.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        color: containerBgColor,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Disk header with icon
                          Row(
                            children: [
                              Icon(diskIcon, color: diskIconColor, size: 22),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Disk $diskNumber - $mediaType',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: showWarning
                                                ? Colors.red.shade800
                                                : null,
                                          ),
                                        ),
                                        if (showWarning) ...[
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade400,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.amber
                                                      .withOpacity(0.6),
                                                  blurRadius: 6,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.warning_rounded,
                                                  color: Colors.red.shade900,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'HIGH CAPACITY',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red.shade900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      model,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),

                          // Capacity
                          Row(
                            children: [
                              Icon(
                                Icons.sd_storage,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Capacity: $sizeText',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: showWarning
                                      ? Colors.red.shade800
                                      : Colors.grey.shade700,
                                  fontWeight: showWarning
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),

                          // Health and Temperature
                          Row(
                            children: [
                              // Health
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: healthColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Health: $health%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: healthColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (temperature != null) ...[
                                SizedBox(width: 12),
                                Icon(
                                  Icons.thermostat,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '$temperature°C',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
