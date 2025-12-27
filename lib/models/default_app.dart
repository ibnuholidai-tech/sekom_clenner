import 'package:flutter/material.dart';

class DefaultApp {
  final String id;
  final String displayName;
  final List<String> registryKeys;
  final IconData iconData;
  bool isInstalled;
  String? installerPath;
  bool isRequired; // Whether this app is marked as required

  DefaultApp({
    required this.id,
    required this.displayName,
    required this.registryKeys,
    this.iconData = Icons.apps, // Default icon
    this.isInstalled = false,
    this.installerPath,
    this.isRequired = true, // Default to required
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'registryKeys': registryKeys,
      'isInstalled': isInstalled,
      'installerPath': installerPath,
      'isRequired': isRequired,
    };
  }

  factory DefaultApp.fromJson(Map<String, dynamic> json) {
    return DefaultApp(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      registryKeys: List<String>.from(json['registryKeys'] as List),
      isInstalled: json['isInstalled'] as bool? ?? false,
      installerPath: json['installerPath'] as String?,
      isRequired: json['isRequired'] as bool? ?? true,
    );
  }
}
