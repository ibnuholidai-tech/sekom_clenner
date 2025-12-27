import 'package:connectivity_plus/connectivity_plus.dart';

/// Network connectivity service
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connection
  static Future<bool> hasInternet() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Get current connectivity status
  static Future<ConnectivityResult> getStatus() async {
    return await _connectivity.checkConnectivity();
  }

  /// Listen to connectivity changes
  static Stream<ConnectivityResult> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  /// Check if connected to WiFi
  static Future<bool> isWiFi() async {
    final result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.wifi;
  }

  /// Check if connected to Ethernet
  static Future<bool> isEthernet() async {
    final result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.ethernet;
  }

  /// Get connectivity status as string
  static Future<String> getStatusString() async {
    final result = await _connectivity.checkConnectivity();
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.none:
        return 'No Connection';
      default:
        return 'Unknown';
    }
  }
}
