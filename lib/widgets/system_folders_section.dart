import 'package:flutter/material.dart';
import '../models/system_status.dart';

class SystemFoldersSection extends StatefulWidget {
  final bool objects3dSelected;
  final bool documentsSelected;
  final bool downloadsSelected;
  final bool musicSelected;
  final bool picturesSelected;
  final bool videosSelected;
  final bool selectAllFolders;
  final List<FolderInfo> folderInfos;
  final Function(bool) onObjects3dChanged;
  final Function(bool) onDocumentsChanged;
  final Function(bool) onDownloadsChanged;
  final Function(bool) onMusicChanged;
  final Function(bool) onPicturesChanged;
  final Function(bool) onVideosChanged;
  final Function(bool) onSelectAllFoldersChanged;

  // Compact mode to reduce paddings/spacing
  final bool compactMode;

  const SystemFoldersSection({
    super.key,
    required this.objects3dSelected,
    required this.documentsSelected,
    required this.downloadsSelected,
    required this.musicSelected,
    required this.picturesSelected,
    required this.videosSelected,
    required this.selectAllFolders,
    required this.folderInfos,
    required this.onObjects3dChanged,
    required this.onDocumentsChanged,
    required this.onDownloadsChanged,
    required this.onMusicChanged,
    required this.onPicturesChanged,
    required this.onVideosChanged,
    required this.onSelectAllFoldersChanged,
    this.compactMode = false,
  });

  @override
  State<SystemFoldersSection> createState() => _SystemFoldersSectionState();
}

class _SystemFoldersSectionState extends State<SystemFoldersSection> {
  String _getFolderSize(String folderName) {
    try {
      FolderInfo? info = widget.folderInfos.firstWhere(
        (folder) => folder.name == folderName,
        orElse: () => FolderInfo(name: folderName, path: '', size: ''),
      );
      return info.size.isNotEmpty ? '(${info.size})' : '';
    } catch (e) {
      return '';
    }
  }

  String _getTotalSize() {
    if (widget.folderInfos.isEmpty) return '';
    try {
      int total = 0;
      for (final info in widget.folderInfos) {
        if (info.exists) {
          total += info.sizeBytes;
        }
      }
      return 'Total: ${_formatSize(total)}';
    } catch (e) {
      return 'Total: -';
    }
  }

  String _formatSize(int sizeBytes) {
    if (sizeBytes <= 0) return "0 B";
    const units = ["B", "KB", "MB", "GB", "TB"];
    int i = 0;
    double size = sizeBytes.toDouble();
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(2)} ${units[i]}";
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
            // Header with folder icon and title in a more compact layout
            Row(
              children: [
                Icon(Icons.folder, color: Colors.orange, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'System Folders',
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
                    widget.onSelectAllFoldersChanged(!widget.selectAllFolders);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.selectAllFolders 
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
            
            // Compact warning
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 12),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'WARNING: Files will be permanently deleted!',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6),
            
            // Grid layout for folders (2 columns)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  child: Column(
                    children: [
                      _buildCompactFolderCheckbox(
                        '📦 3D Objects',
                        widget.objects3dSelected,
                        widget.onObjects3dChanged,
                        '3D Objects',
                      ),
                      _buildCompactFolderCheckbox(
                        '📄 Documents',
                        widget.documentsSelected,
                        widget.onDocumentsChanged,
                        'Documents',
                      ),
                      _buildCompactFolderCheckbox(
                        '📥 Downloads',
                        widget.downloadsSelected,
                        widget.onDownloadsChanged,
                        'Downloads',
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // Right column
                Expanded(
                  child: Column(
                    children: [
                      _buildCompactFolderCheckbox(
                        '🎵 Music',
                        widget.musicSelected,
                        widget.onMusicChanged,
                        'Music',
                      ),
                      _buildCompactFolderCheckbox(
                        '🖼️ Pictures',
                        widget.picturesSelected,
                        widget.onPicturesChanged,
                        'Pictures',
                      ),
                      _buildCompactFolderCheckbox(
                        '🎬 Videos',
                        widget.videosSelected,
                        widget.onVideosChanged,
                        'Videos',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (widget.folderInfos.isNotEmpty) ...[
              SizedBox(height: 6),
              Text(
                _getTotalSize(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Ultra-compact folder checkbox for the grid layout
  Widget _buildCompactFolderCheckbox(
    String title,
    bool value,
    Function(bool) onChanged,
    String folderName,
  ) {
    String sizeInfo = _getFolderSize(folderName);
    
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          InkWell(
            onTap: () => onChanged(!value),
            child: Row(
              children: [
                Icon(
                  value ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 16,
                  color: Colors.blue,
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (sizeInfo.isNotEmpty) ...[
            SizedBox(width: 4),
            Text(
              sizeInfo,
              style: TextStyle(
                fontSize: 9,
                color: Colors.blue.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
