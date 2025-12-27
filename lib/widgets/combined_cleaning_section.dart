import 'package:flutter/material.dart';
import '../models/system_status.dart';

class CombinedCleaningSection extends StatelessWidget {
  // Browser selection states
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

  // System folders selection states
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

  const CombinedCleaningSection({
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
  });

  String _getFolderSize(String folderName) {
    try {
      FolderInfo? info = folderInfos.firstWhere(
        (folder) => folder.name == folderName,
        orElse: () => FolderInfo(name: folderName, path: '', size: ''),
      );
      return info.size.isNotEmpty ? '(${info.size})' : '';
    } catch (e) {
      return '';
    }
  }

  String _getTotalSize() {
    if (folderInfos.isEmpty) return '';
    try {
      int total = 0;
      for (final info in folderInfos) {
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Combined header
            Row(
              children: [
                Icon(Icons.cleaning_services, color: Colors.blue, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Cleaning Options',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Browser section (compact)
            Row(
              children: [
                Icon(Icons.web, color: Colors.blue, size: 16),
                SizedBox(width: 4),
                Text(
                  'Browser',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Spacer(),
                InkWell(
                  onTap: () {
                    onSelectAllBrowsersChanged(!selectAllBrowsers);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectAllBrowsers
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 14,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'All',
                          style: TextStyle(fontSize: 11, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),

            // Browser checkboxes in one row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => onChromeChanged(!chromeSelected),
                    child: Row(
                      children: [
                        Icon(
                          chromeSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 14,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Chrome',
                            style: TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: () => onEdgeChanged(!edgeSelected),
                    child: Row(
                      children: [
                        Icon(
                          edgeSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 14,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Edge',
                            style: TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: () => onFirefoxChanged(!firefoxSelected),
                    child: Row(
                      children: [
                        Icon(
                          firefoxSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 14,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Firefox',
                            style: TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),

            // Reset browser option
            InkWell(
              onTap: () => onResetBrowserChanged(!resetBrowserSelected),
              child: Row(
                children: [
                  Icon(
                    resetBrowserSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 14,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '🔄 Reset browser ke setelan awal',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8),
            Divider(height: 1),
            SizedBox(height: 8),

            // System folders section (compact)
            Row(
              children: [
                Icon(Icons.folder, color: Colors.orange, size: 16),
                SizedBox(width: 4),
                Text(
                  'System Folders',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Spacer(),
                InkWell(
                  onTap: () {
                    onSelectAllFoldersChanged(!selectAllFolders);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectAllFolders
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 14,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'All',
                          style: TextStyle(fontSize: 11, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),

            // Warning
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

            // Folders in 2 columns
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  child: Column(
                    children: [
                      _buildCompactFolderCheckbox(
                        '📦 3D Objects',
                        objects3dSelected,
                        onObjects3dChanged,
                        '3D Objects',
                      ),
                      _buildCompactFolderCheckbox(
                        '📄 Documents',
                        documentsSelected,
                        onDocumentsChanged,
                        'Documents',
                      ),
                      _buildCompactFolderCheckbox(
                        '📥 Downloads',
                        downloadsSelected,
                        onDownloadsChanged,
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
                        musicSelected,
                        onMusicChanged,
                        'Music',
                      ),
                      _buildCompactFolderCheckbox(
                        '🖼️ Pictures',
                        picturesSelected,
                        onPicturesChanged,
                        'Pictures',
                      ),
                      _buildCompactFolderCheckbox(
                        '🎬 Videos',
                        videosSelected,
                        onVideosChanged,
                        'Videos',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (folderInfos.isNotEmpty) ...[
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
                  size: 14,
                  color: Colors.blue,
                ),
                SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (sizeInfo.isNotEmpty) ...[
            SizedBox(width: 4),
            Flexible(
              child: Text(
                sizeInfo,
                style: TextStyle(fontSize: 9, color: Colors.blue.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
