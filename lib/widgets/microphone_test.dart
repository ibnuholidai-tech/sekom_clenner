import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';

class MicrophoneTest extends StatefulWidget {
  const MicrophoneTest({super.key});

  @override
  State<MicrophoneTest> createState() => _MicrophoneTestState();
}

class _MicrophoneTestState extends State<MicrophoneTest>
    with SingleTickerProviderStateMixin {
  final Record _audioRecorder = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecording = false;
  String? _recordingPath;
  String? _error;

  // Volume meter
  double _currentVolume = 0.0;
  double _noiseLevel = 0.0;
  Timer? _volumeTimer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  // Recording info
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  int _fileSize = 0;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _setupAudioPlayer();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        setState(() {
          _error = 'Izin mikrofon diperlukan untuk melakukan test';
        });
      }
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path =
            '${directory.path}/mic_test_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          path: path,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );

        // Start duration timer
        _recordingDuration = Duration.zero;
        _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordingDuration = Duration(seconds: timer.tick);
            });
          }
        });

        // Listen to amplitude for volume meter
        _amplitudeSubscription = _audioRecorder
            .onAmplitudeChanged(const Duration(milliseconds: 100))
            .listen((Amplitude amplitude) {
              if (mounted) {
                setState(() {
                  // Normalize amplitude to 0-1 range
                  _currentVolume = (amplitude.current + 50) / 50;
                  _currentVolume = _currentVolume.clamp(0.0, 1.0);

                  // Calculate noise level (average of low volumes)
                  if (_currentVolume < 0.2) {
                    _noiseLevel = (_noiseLevel + _currentVolume) / 2;
                  }
                });
              }
            });

        setState(() {
          _isRecording = true;
          _recordingPath = path;
          _error = null;
          _noiseLevel = 0.0;
        });
      } else {
        setState(() {
          _error = 'Izin mikrofon tidak diberikan';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal memulai recording: $e';
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _amplitudeSubscription?.cancel();
      _durationTimer?.cancel();

      // Get file size
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final size = await file.length();
          setState(() {
            _fileSize = size;
          });
        }
      }

      setState(() {
        _isRecording = false;
        _currentVolume = 0.0;
        if (path != null) {
          _recordingPath = path;
          _hasRecording = true;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal menghentikan recording: $e';
        _isRecording = false;
      });
    }
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null || !_hasRecording) return;

    try {
      await _audioPlayer.play(DeviceFileSource(_recordingPath!));
      setState(() {
        _isPlaying = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memutar recording: $e';
      });
    }
  }

  Future<void> _stopPlaying() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal menghentikan playback: $e';
      });
    }
  }

  Future<void> _deleteRecording() async {
    if (_recordingPath != null) {
      try {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        setState(() {
          _hasRecording = false;
          _recordingPath = null;
          _recordingDuration = Duration.zero;
          _fileSize = 0;
        });
      } catch (e) {
        setState(() {
          _error = 'Gagal menghapus recording: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _volumeTimer?.cancel();
    _durationTimer?.cancel();
    _pulseController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Color _getVolumeColor() {
    if (_currentVolume > 0.7) return Colors.red;
    if (_currentVolume > 0.4) return Colors.orange;
    return Colors.green;
  }

  String _getNoiseLevelText() {
    if (_noiseLevel < 0.1) return 'Sangat Rendah';
    if (_noiseLevel < 0.2) return 'Rendah';
    if (_noiseLevel < 0.3) return 'Sedang';
    return 'Tinggi';
  }

  Color _getNoiseLevelColor() {
    if (_noiseLevel < 0.1) return Colors.green;
    if (_noiseLevel < 0.2) return Colors.lightGreen;
    if (_noiseLevel < 0.3) return Colors.orange;
    return Colors.red;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Microphone Test'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade700, Colors.purple.shade500],
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
            colors: [Colors.purple.shade50, Colors.white],
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

              // Microphone Icon and Volume Meter
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isRecording ? _pulseAnimation.value : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isRecording
                              ? [Colors.red.shade100, Colors.red.shade50]
                              : [Colors.purple.shade100, Colors.purple.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isRecording
                              ? Colors.red.shade300
                              : Colors.purple.shade300,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording ? Colors.red : Colors.purple)
                                .withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _isRecording ? Icons.mic : Icons.mic_none,
                            size: 100,
                            color: _isRecording
                                ? Colors.red.shade700
                                : Colors.purple.shade700,
                          ),
                          const SizedBox(height: 24),

                          // Recording Duration
                          if (_isRecording || _hasRecording)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDuration(_recordingDuration),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Volume Meter
                          if (_isRecording) ...[
                            const Text(
                              'Volume Level',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade300,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green,
                                            Colors.yellow,
                                            Colors.orange,
                                            Colors.red,
                                          ],
                                          stops: const [0.0, 0.4, 0.7, 1.0],
                                        ),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: 1 - _currentVolume,
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_currentVolume * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _getVolumeColor(),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Noise Level Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _getNoiseLevelColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getNoiseLevelColor(),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.graphic_eq,
                                    color: _getNoiseLevelColor(),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Noise: ${_getNoiseLevelText()}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _getNoiseLevelColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Recording Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isRecording
                            ? [Colors.red.shade600, Colors.red.shade800]
                            : [Colors.purple.shade600, Colors.purple.shade800],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Colors.purple)
                              .withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isRecording
                          ? _stopRecording
                          : _startRecording,
                      icon: Icon(
                        _isRecording
                            ? Icons.stop_circle
                            : Icons.fiber_manual_record,
                        size: 28,
                      ),
                      label: Text(
                        _isRecording ? 'Stop Recording' : 'Start Recording',
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

              const SizedBox(height: 24),

              // File Info
              if (_hasRecording)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade300, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(_recordingDuration),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          Text(
                            'Duration',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 2,
                        height: 50,
                        color: Colors.blue.shade300,
                      ),
                      Column(
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFileSize(_fileSize),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          Text(
                            'File Size',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Playback Controls
              if (_hasRecording) ...[
                const SizedBox(height: 24),
                const Divider(height: 48, thickness: 2),
                const Text(
                  'Playback',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isPlaying
                              ? [Colors.orange.shade600, Colors.orange.shade800]
                              : [Colors.green.shade600, Colors.green.shade800],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (_isPlaying ? Colors.orange : Colors.green)
                                .withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isPlaying ? _stopPlaying : _playRecording,
                        icon: Icon(
                          _isPlaying ? Icons.stop : Icons.play_arrow,
                          size: 24,
                        ),
                        label: Text(
                          _isPlaying ? 'Stop' : 'Play Recording',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 18,
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
                    ElevatedButton.icon(
                      onPressed: _isPlaying ? null : _deleteRecording,
                      icon: const Icon(Icons.delete, size: 24),
                      label: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 18,
                        ),
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // Instructions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Cara Test Mikrofon',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInstruction(
                      '1. Klik "Start Recording" untuk mulai merekam',
                    ),
                    _buildInstruction(
                      '2. Bicara ke mikrofon dan lihat volume meter',
                    ),
                    _buildInstruction(
                      '3. Perhatikan noise level (harus rendah)',
                    ),
                    _buildInstruction(
                      '4. Klik "Stop Recording" untuk berhenti',
                    ),
                    _buildInstruction(
                      '5. Klik "Play Recording" untuk mendengar hasil',
                    ),
                    _buildInstruction(
                      '6. Pastikan suara terdengar jelas tanpa noise',
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

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              style: TextStyle(
                fontSize: 15,
                color: Colors.blue.shade900,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
