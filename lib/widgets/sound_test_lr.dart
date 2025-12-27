import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/test_summary.dart';

class SoundTestLR extends StatefulWidget {
  const SoundTestLR({super.key});

  @override
  State<SoundTestLR> createState() => _SoundTestLRState();
}

class _SoundTestLRState extends State<SoundTestLR>
    with TickerProviderStateMixin {
  final ap.AudioPlayer _player = ap.AudioPlayer();
  bool _initialized = false;
  String? _error;

  bool _isPlayingLeft = false;
  bool _isPlayingRight = false;
  bool _isAlternating = false;
  double _volume = 0.9;

  late final AnimationController _pulseLeft;
  late final AnimationController _pulseRight;

  @override
  void initState() {
    super.initState();
    _pulseLeft = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseRight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseLeft.value = 0.0;
    _pulseRight.value = 0.0;
    _init();
  }

  @override
  void dispose() {
    _isAlternating = false;
    _pulseLeft.stop();
    _pulseRight.stop();
    unawaited(_player.stop());
    _player.dispose();
    _pulseLeft.dispose();
    _pulseRight.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      if (!Platform.isWindows) {
        setState(() {
          _error = 'Sound L/R test saat ini hanya didukung pada Windows.';
        });
        return;
      }

      // Load saved volume from preferences
      await _loadVolume();

      await _player.setVolume(_volume);

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal inisialisasi Sound Test: $e';
      });
    }
  }

  // Load saved volume from SharedPreferences
  Future<void> _loadVolume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVolume = prefs.getDouble('sound_test_volume');
      if (savedVolume != null) {
        setState(() {
          _volume = savedVolume;
        });
      }
    } catch (e) {
      print('Error loading volume: $e');
    }
  }

  // Save volume to SharedPreferences
  Future<void> _saveVolume(double volume) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('sound_test_volume', volume);
    } catch (e) {
      print('Error saving volume: $e');
    }
  }

  Future<void> _playLeft() async {
    if (!_initialized) return;
    try {
      _stopAnimations();
      _isAlternating = false;
      setState(() {
        _isPlayingLeft = true;
        _isPlayingRight = false;
      });
      _pulseLeft.repeat(reverse: true);
      await _player.stop();
      await _player.setVolume(_volume);
      await _player.setBalance(-1.0); // full left
      await _player.play(ap.AssetSource('ringtone-193209.mp3'));
      unawaited(TestSummary.saveSound(channel: 'Left', volume: _volume));
      _player.onPlayerComplete.first
          .then((_) {
            if (!_isAlternating && mounted) {
              _stopAnimations();
            }
          })
          .catchError((e) {
            if (mounted) {
              setState(() {
                _error = 'Error playing sound: $e';
              });
              _stopAnimations();
            }
          });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memutar suara kiri: $e';
        });
        _stopAnimations();
      }
    }
  }

  Future<void> _playRight() async {
    if (!_initialized) return;
    try {
      _stopAnimations();
      _isAlternating = false;
      setState(() {
        _isPlayingLeft = false;
        _isPlayingRight = true;
      });
      _pulseRight.repeat(reverse: true);
      await _player.stop();
      await _player.setVolume(_volume);
      await _player.setBalance(1.0); // full right
      await _player.play(ap.AssetSource('ringtone-193209.mp3'));
      unawaited(TestSummary.saveSound(channel: 'Right', volume: _volume));
      _player.onPlayerComplete.first
          .then((_) {
            if (!_isAlternating && mounted) {
              _stopAnimations();
            }
          })
          .catchError((e) {
            if (mounted) {
              setState(() {
                _error = 'Error playing sound: $e';
              });
              _stopAnimations();
            }
          });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memutar suara kanan: $e';
        });
        _stopAnimations();
      }
    }
  }

  Future<void> _playAlternate() async {
    if (!_initialized) return;
    try {
      _isAlternating = true;

      _stopAnimations();
      setState(() {
        _isPlayingLeft = true;
        _isPlayingRight = true;
      });
      _pulseLeft.repeat(reverse: true);
      _pulseRight.repeat(reverse: true);

      await _player.stop();
      await _player.setVolume(_volume);
      await _player.setBalance(0.0); // center: L+R
      await _player.play(ap.AssetSource('ringtone-193209.mp3'));
      unawaited(TestSummary.saveSound(channel: 'Both', volume: _volume));
      _player.onPlayerComplete.first
          .then((_) {
            if (mounted) {
              _isAlternating = false;
              _stopAnimations();
            }
          })
          .catchError((e) {
            if (mounted) {
              setState(() {
                _error = 'Error playing sound: $e';
              });
              _isAlternating = false;
              _stopAnimations();
            }
          });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memutar suara stereo: $e';
        });
        _isAlternating = false;
        _stopAnimations();
      }
    }
  }

  Future<void> _stopAll() async {
    try {
      _isAlternating = false;
      await _player.stop();
      _stopAnimations();
    } catch (e) {
      // Silently handle stop errors
      _stopAnimations();
    }
  }

  void _stopAnimations() {
    _pulseLeft.stop();
    _pulseRight.stop();
    _pulseLeft.value = 0.0;
    _pulseRight.value = 0.0;
    if (mounted) {
      setState(() {
        _isPlayingLeft = false;
        _isPlayingRight = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _errorPane(_error!);
    }
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              color: Colors.blue.shade50,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.volume_up,
                      size: 24,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sound Test - Left / Right',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Test your speakers or headphones',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message:
                          'Uji speaker kiri/kanan dengan suara notifikasi pendek. Gunakan headphone/speaker stereo.',
                      child: Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Visualizer circles
            Row(
              children: [
                Expanded(
                  child: _channelCircle(
                    'LEFT',
                    Colors.tealAccent,
                    _pulseLeft,
                    _isPlayingLeft,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _channelCircle(
                    'RIGHT',
                    Colors.pinkAccent,
                    _pulseRight,
                    _isPlayingRight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Controls in Grid
            Card(
              color: Colors.white,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Controls',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _playLeft,
                            icon: const Icon(Icons.arrow_left),
                            label: const Text('Play Left'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _playRight,
                            icon: const Icon(Icons.arrow_right),
                            label: const Text('Play Right'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isAlternating ? null : _playAlternate,
                            icon: const Icon(Icons.surround_sound),
                            label: const Text('Both (L+R)'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _stopAll,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: Colors.red.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Volume Control Card
            Card(
              color: Colors.white,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Volume',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.volume_mute,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                        Expanded(
                          child: Slider(
                            value: _volume,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (v) async {
                              setState(() {
                                _volume = v;
                              });
                              await _player.setVolume(_volume);
                              await _saveVolume(
                                _volume,
                              ); // Save volume preference
                            },
                          ),
                        ),
                        Icon(
                          Icons.volume_up,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(_volume * 100).toInt()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Back button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _channelCircle(
    String label,
    Color color,
    AnimationController pulse,
    bool isActive,
  ) {
    final anim = CurvedAnimation(parent: pulse, curve: Curves.easeInOut);
    final scale = Tween(begin: 0.96, end: 1.06).animate(anim);
    final glow = (isActive ? 0.6 : 0.15);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(isActive ? 0.35 : 0.15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(glow),
                  blurRadius: isActive ? 28 : 6,
                  spreadRadius: isActive ? 6 : 1,
                ),
              ],
              border: Border.all(color: Colors.grey.shade300),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorPane(String message) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red.shade900),
      ),
    );
  }
}

void unawaited(Future<void> f) {}
