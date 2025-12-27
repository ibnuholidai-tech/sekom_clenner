import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class WebcamTest extends StatefulWidget {
  const WebcamTest({super.key});

  @override
  State<WebcamTest> createState() => _WebcamTestState();
}

class _WebcamTestState extends State<WebcamTest>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  String? _error;
  List<String> _capturedPhotos = []; // Photo gallery

  // New features
  ResolutionPreset _selectedResolution = ResolutionPreset.high;
  bool _showGrid = false;
  double _zoomLevel = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  int _captureTimer = 0; // 0 = no timer, 3, 5, 10 seconds
  int _countdown = 0;
  Timer? _countdownTimer;

  // FPS counter
  int _fps = 0;
  int _frameCount = 0;
  DateTime? _lastFpsUpdate;

  late AnimationController _timerAnimationController;

  @override
  void initState() {
    super.initState();
    _timerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _initializeCamera();
    _startFpsCounter();
  }

  void _startFpsCounter() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted ||
          _controller == null ||
          !_controller!.value.isInitialized) {
        timer.cancel();
        return;
      }

      _frameCount++;
      final now = DateTime.now();

      if (_lastFpsUpdate == null) {
        _lastFpsUpdate = now;
      } else {
        final diff = now.difference(_lastFpsUpdate!);
        if (diff.inSeconds >= 1) {
          if (mounted) {
            setState(() {
              _fps = _frameCount;
              _frameCount = 0;
              _lastFpsUpdate = now;
            });
          }
        }
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      if (!mounted) return;
      setState(() {
        _isInitializing = true;
        _error = null;
      });

      // Check camera permission
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          if (!mounted) return;
          setState(() {
            _error = 'Izin kamera diperlukan untuk melakukan test';
            _isInitializing = false;
          });
          return;
        }
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (!mounted) return;

      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _error = 'Tidak ada kamera yang terdeteksi';
          _isInitializing = false;
        });
        return;
      }

      // Initialize first camera
      await _initializeCameraController(_selectedCameraIndex);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal menginisialisasi kamera: $e';
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _initializeCameraController(int cameraIndex) async {
    if (_cameras == null || _cameras!.isEmpty) return;

    // Dispose previous controller
    await _controller?.dispose();

    final camera = _cameras![cameraIndex];
    _controller = CameraController(
      camera,
      _selectedResolution,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();

      // Get zoom capabilities
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      _zoomLevel = _minZoom;

      if (!mounted) return;
      setState(() {
        _selectedCameraIndex = cameraIndex;
        _isInitializing = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal menginisialisasi kamera: $e';
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1) return;

    final newIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    setState(() {
      _isInitializing = true;
    });
    await _initializeCameraController(newIndex);
  }

  Future<void> _changeResolution(ResolutionPreset preset) async {
    setState(() {
      _selectedResolution = preset;
      _isInitializing = true;
    });
    await _initializeCameraController(_selectedCameraIndex);
  }

  void _toggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
    });
  }

  Future<void> _setZoom(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final clampedZoom = zoom.clamp(_minZoom, _maxZoom);
    await _controller!.setZoomLevel(clampedZoom);
    setState(() {
      _zoomLevel = clampedZoom;
    });
  }

  void _startCaptureTimer() {
    if (_captureTimer == 0) {
      _capturePhoto();
      return;
    }

    setState(() {
      _countdown = _captureTimer;
    });

    _timerAnimationController.repeat();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        timer.cancel();
        _timerAnimationController.stop();
        _timerAnimationController.reset();
        _capturePhoto();
      }
    });
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/webcam_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile image = await _controller!.takePicture();
      await image.saveTo(path);

      setState(() {
        _capturedPhotos.insert(0, path); // Add to beginning of list
        if (_capturedPhotos.length > 10) {
          // Keep only last 10 photos
          _capturedPhotos = _capturedPhotos.sublist(0, 10);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto ${_capturedPhotos.length} berhasil diambil!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal mengambil foto: $e';
      });
    }
  }

  void _deletePhoto(int index) {
    setState(() {
      _capturedPhotos.removeAt(index);
    });
  }

  void _clearAllPhotos() {
    setState(() {
      _capturedPhotos.clear();
    });
  }

  @override
  void dispose() {
    _timerAnimationController.stop();
    _controller?.dispose();
    _countdownTimer?.cancel();
    _timerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Webcam Test'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          // Grid toggle
          IconButton(
            icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off),
            onPressed: _toggleGrid,
            tooltip: 'Grid Overlay',
          ),
          // Camera switch
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_android),
              onPressed: _switchCamera,
              tooltip: 'Switch Camera',
            ),
          // Resolution selector
          PopupMenuButton<ResolutionPreset>(
            icon: const Icon(Icons.settings),
            tooltip: 'Resolution',
            onSelected: _changeResolution,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ResolutionPreset.low,
                child: Text('Low (480p)'),
              ),
              const PopupMenuItem(
                value: ResolutionPreset.medium,
                child: Text('Medium (720p)'),
              ),
              const PopupMenuItem(
                value: ResolutionPreset.high,
                child: Text('High (1080p)'),
              ),
              const PopupMenuItem(
                value: ResolutionPreset.veryHigh,
                child: Text('Very High (2K)'),
              ),
              const PopupMenuItem(
                value: ResolutionPreset.ultraHigh,
                child: Text('Ultra High (4K)'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isInitializing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.blue.shade700),
                    const SizedBox(height: 16),
                    Text(
                      'Menginisialisasi kamera...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade700,
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
                          colors: [Colors.blue.shade600, Colors.blue.shade800],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _initializeCamera,
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
            : Column(
                children: [
                  // Camera Preview with overlays
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        _buildCameraPreview(),

                        // Grid overlay
                        if (_showGrid) _buildGridOverlay(),

                        // FPS Counter
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.videocam,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_fps FPS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Countdown timer
                        if (_countdown > 0)
                          Center(
                            child: AnimatedBuilder(
                              animation: _timerAnimationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale:
                                      1.0 +
                                      (_timerAnimationController.value * 0.2),
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$_countdown',
                                        style: const TextStyle(
                                          fontSize: 64,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Photo Gallery
                  if (_capturedPhotos.isNotEmpty)
                    Container(
                      height: 120,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Gallery (${_capturedPhotos.length})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _clearAllPhotos,
                                  icon: const Icon(
                                    Icons.delete_sweep,
                                    size: 18,
                                  ),
                                  label: const Text('Clear All'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _capturedPhotos.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(_capturedPhotos[index]),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _deletePhoto(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
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

                  // Controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade900, Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Zoom Control
                        if (_controller != null &&
                            _controller!.value.isInitialized)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.zoom_out,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _zoomLevel,
                                    min: _minZoom,
                                    max: _maxZoom,
                                    activeColor: Colors.blue.shade400,
                                    inactiveColor: Colors.white30,
                                    onChanged: _setZoom,
                                  ),
                                ),
                                const Icon(
                                  Icons.zoom_in,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_zoomLevel.toStringAsFixed(1)}x',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Camera Info
                        if (_controller != null &&
                            _controller!.value.isInitialized)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildInfoChip(
                                  Icons.camera_alt,
                                  _cameras![_selectedCameraIndex].name,
                                ),
                                _buildInfoChip(
                                  Icons.aspect_ratio,
                                  '${_controller!.value.previewSize?.width.toInt() ?? 0}x${_controller!.value.previewSize?.height.toInt() ?? 0}',
                                ),
                              ],
                            ),
                          ),

                        // Timer Selector
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Timer: ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              ...[0, 3, 5, 10].map((seconds) {
                                final isSelected = _captureTimer == seconds;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(
                                      seconds == 0 ? 'Off' : '${seconds}s',
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _captureTimer = seconds;
                                      });
                                    },
                                    selectedColor: Colors.blue.shade600,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    backgroundColor: Colors.white24,
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),

                        // Capture Button
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.blue.shade800,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _countdown > 0
                                ? null
                                : _startCaptureTimer,
                            icon: Icon(
                              _captureTimer > 0 ? Icons.timer : Icons.camera,
                              size: 28,
                            ),
                            label: Text(
                              _captureTimer > 0
                                  ? 'Capture (${_captureTimer}s)'
                                  : 'Capture Photo',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 20,
                              ),
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
                ],
              ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: CameraPreview(_controller!),
      ),
    );
  }

  Widget _buildGridOverlay() {
    return CustomPaint(painter: GridPainter(), child: Container());
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Grid overlay painter (rule of thirds)
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0;

    // Vertical lines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
