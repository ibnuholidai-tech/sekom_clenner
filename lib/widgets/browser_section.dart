
import 'package:flutter/material.dart';
import '../services/system_service.dart';

class BrowserSection extends StatefulWidget {
  final bool chromeSelected;
  final bool edgeSelected;
  final bool firefoxSelected;
  final bool resetBrowserSelected;
  final bool selectAllBrowsers;
  final Function(bool) onChromeChanged;
  final Function(bool) onEdgeChanged;
  final Function(bool) onFirefoxChanged;
  final Function(bool) onResetBrowserChanged;
  final Function(bool) onSelectAllBrowsersChanged;

  // Compact mode to reduce paddings/spacing
  final bool compactMode;
  // Whether Disk Usage section should be shown expanded by default
  final bool showDiskUsage;

  const BrowserSection({
    super.key,
    required this.chromeSelected,
    required this.edgeSelected,
    required this.firefoxSelected,
    required this.resetBrowserSelected,
    required this.selectAllBrowsers,
    required this.onChromeChanged,
    required this.onEdgeChanged,
    required this.onFirefoxChanged,
    required this.onResetBrowserChanged,
    required this.onSelectAllBrowsersChanged,
    this.compactMode = false,
    this.showDiskUsage = true,
  });

  @override
  State<BrowserSection> createState() => _BrowserSectionState();
}

class _BrowserSectionState extends State<BrowserSection> {
  List<Map<String, dynamic>> _disks = [];
  bool _loadingDisks = false;
  String? _diskError;
  bool _diskExpanded = true;

  @override
  void initState() {
    super.initState();
    _diskExpanded = widget.showDiskUsage;
    _loadDisks();
  }

  Future<void> _loadDisks() async {
    setState(() {
      _loadingDisks = true;
      _diskError = null;
    });
  }

  Future<void> _visitDrive(String drive) async {
    await SystemService.openDrive(drive);
  }

  Widget _buildDiskList() {
    if (_diskError != null) {
      return Text(
        'Gagal memuat info disk: $_diskError',
        style: TextStyle(color: Colors.red),
      );
    }
    if (_loadingDisks) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_disks.isEmpty) {
      return Text(
        'Tidak ada disk yang terdeteksi.',
        style: TextStyle(color: Colors.grey.shade700),
      );
    }

    return Column(
      children: _disks.map((d) {
        final drive = (d['drive'] ?? '').toString();
        final totalText = (d['totalText'] ?? '').toString();
        final freeText = (d['freeText'] ?? '').toString();
        final usedText = (d['usedText'] ?? '').toString();
        final usedPercent = (d['usedPercent'] is num) ? (d['usedPercent'] as num).toDouble() : 0.0;

        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    drive,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total $totalText • Used $usedText • Free $freeText',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _visitDrive(drive),
                    child: Text('Visit'),
                  ),
                ],
              ),
              SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: usedPercent.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double pad = widget.compactMode ? 12.0 : 16.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with browser icon and title in a more compact layout
            Row(
              children: [
                Icon(Icons.web, color: Colors.blue, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Browser Cleaning',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Integrated select all button in header
                InkWell(
                  onTap: () {
                    widget.onSelectAllBrowsersChanged(!widget.selectAllBrowsers);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.selectAllBrowsers 
                              ? Icons.check_box 
                              : Icons.check_box_outline_blank,
                          size: 14,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'All',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            
            // Ultra-compact browser selection with horizontal layout
            Row(
              children: [
                // Chrome
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onChromeChanged(!widget.chromeSelected),
                    child: Row(
                      children: [
                        Icon(
                          widget.chromeSelected ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Chrome',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                
                // Edge
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onEdgeChanged(!widget.edgeSelected),
                    child: Row(
                      children: [
                        Icon(
                          widget.edgeSelected ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Edge',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                
                // Firefox
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onFirefoxChanged(!widget.firefoxSelected),
                    child: Row(
                      children: [
                        Icon(
                          widget.firefoxSelected ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Firefox',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            // Reset browser action - more compact
            InkWell(
              onTap: () => widget.onResetBrowserChanged(!widget.resetBrowserSelected),
              child: Row(
                children: [
                  Icon(
                    widget.resetBrowserSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '🔄 Reset browser ke setelan awal',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Only show disk usage section if explicitly enabled
            if (widget.showDiskUsage) ...[
              SizedBox(height: 6),
              Divider(height: 1),
              SizedBox(height: 4),

              // Disk Usage section (collapsible) - more compact
              InkWell(
                onTap: () => setState(() => _diskExpanded = !_diskExpanded),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.storage, color: Colors.blueGrey, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Disk Usage',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      Icon(_diskExpanded ? Icons.expand_less : Icons.expand_more, size: 16),
                      SizedBox(width: 4),
                      InkWell(
                        onTap: _loadingDisks ? null : _loadDisks,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: _loadingDisks
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.refresh, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_diskExpanded) ...[
                SizedBox(height: 6),
                _buildDiskList(),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
