import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Modern loading widgets menggunakan Flutter SpinKit
class ModernLoading {
  /// Rotating circle loading indicator
  static Widget circle({Color? color, double size = 50.0}) {
    return SpinKitFadingCircle(color: color ?? Colors.blue, size: size);
  }

  /// Rotating arc loading indicator
  static Widget arc({Color? color, double size = 50.0}) {
    return SpinKitSpinningCircle(color: color ?? Colors.blue, size: size);
  }

  /// Wave loading indicator
  static Widget wave({Color? color, double size = 50.0}) {
    return SpinKitWave(color: color ?? Colors.blue, size: size);
  }

  /// Pulse loading indicator
  static Widget pulse({Color? color, double size = 50.0}) {
    return SpinKitPulse(color: color ?? Colors.blue, size: size);
  }

  /// Three bounce loading indicator
  static Widget threeBounce({Color? color, double size = 50.0}) {
    return SpinKitThreeBounce(color: color ?? Colors.blue, size: size);
  }

  /// Wandering cubes loading indicator
  static Widget wanderingCubes({Color? color, double size = 50.0}) {
    return SpinKitWanderingCubes(color: color ?? Colors.blue, size: size);
  }

  /// Fading grid loading indicator
  static Widget fadingGrid({Color? color, double size = 50.0}) {
    return SpinKitFadingGrid(color: color ?? Colors.blue, size: size);
  }

  /// Ring loading indicator
  static Widget ring({Color? color, double size = 50.0}) {
    return SpinKitRing(color: color ?? Colors.blue, size: size, lineWidth: 4.0);
  }

  /// Dual ring loading indicator
  static Widget dualRing({Color? color, double size = 50.0}) {
    return SpinKitDualRing(
      color: color ?? Colors.blue,
      size: size,
      lineWidth: 4.0,
    );
  }

  /// Ripple loading indicator
  static Widget ripple({Color? color, double size = 50.0}) {
    return SpinKitRipple(color: color ?? Colors.blue, size: size);
  }

  /// Dancing square loading indicator
  static Widget dancingSquare({Color? color, double size = 50.0}) {
    return SpinKitDancingSquare(color: color ?? Colors.blue, size: size);
  }

  /// Cube grid loading indicator
  static Widget cubeGrid({Color? color, double size = 50.0}) {
    return SpinKitCubeGrid(color: color ?? Colors.blue, size: size);
  }

  /// Loading overlay untuk full screen
  static Widget overlay({
    required Widget child,
    bool isLoading = false,
    Color? loadingColor,
    Color? backgroundColor,
    String? message,
  }) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  circle(color: loadingColor ?? Colors.white),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: TextStyle(
                        color: loadingColor ?? Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Loading dialog
  static void showLoadingDialog(
    BuildContext context, {
    String? message,
    Color? color,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              circle(color: color ?? Colors.blue),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}
