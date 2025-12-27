// System optimization suggestions for Sekom Cleaner
// These suggestions will be displayed to users to help them optimize their system

class SystemSuggestion {
  final String title;
  final String description;
  final String category;
  final String actionText;
  final bool requiresAdmin;

  const SystemSuggestion({
    required this.title,
    required this.description,
    required this.category,
    required this.actionText,
    this.requiresAdmin = false,
  });
}

class SystemSuggestions {
  // List of performance optimization suggestions
  static const List<SystemSuggestion> performanceSuggestions = [
    SystemSuggestion(
      title: 'Disable Startup Programs',
      description: 'Reduce startup time by disabling unnecessary startup programs.',
      category: 'Performance',
      actionText: 'Open Task Manager > Startup',
      requiresAdmin: false,
    ),
    SystemSuggestion(
      title: 'Optimize Visual Effects',
      description: 'Adjust visual effects for better performance.',
      category: 'Performance',
      actionText: 'Open Performance Options',
      requiresAdmin: true,
    ),
    SystemSuggestion(
      title: 'Disk Cleanup',
      description: 'Remove temporary files and system files to free up disk space.',
      category: 'Performance',
      actionText: 'Run Disk Cleanup',
      requiresAdmin: true,
    ),
    SystemSuggestion(
      title: 'Defragment Hard Drive',
      description: 'Optimize file storage for faster access (HDD only).',
      category: 'Performance',
      actionText: 'Run Defragmentation',
      requiresAdmin: true,
    ),
    SystemSuggestion(
      title: 'Disable Background Apps',
      description: 'Prevent apps from running in the background to save resources.',
      category: 'Performance',
      actionText: 'Open Background Apps Settings',
      requiresAdmin: false,
    ),
  ];

  // List of security optimization suggestions
  static const List<SystemSuggestion> securitySuggestions = [
    SystemSuggestion(
      title: 'Enable Windows Firewall',
      description: 'Protect your computer from unauthorized access.',
      category: 'Security',
      actionText: 'Open Windows Firewall',
      requiresAdmin: true,
    ),
    SystemSuggestion(
      title: 'Update Windows Defender',
      description: 'Keep your antivirus definitions up to date.',
      category: 'Security',
      actionText: 'Update Windows Defender',
      requiresAdmin: true,
    ),
    SystemSuggestion(
      title: 'Enable BitLocker',
      description: 'Encrypt your drive to protect your data.',
      category: 'Security',
      actionText: 'Open BitLocker Settings',
      requiresAdmin: true,
    ),
    SystemSuggestion(
      title: 'Check for Malware',
      description: 'Run a full system scan to detect and remove malware.',
      category: 'Security',
      actionText: 'Run Windows Security Scan',
      requiresAdmin: false,
    ),
    SystemSuggestion(
      title: 'Enable Controlled Folder Access',
      description: 'Protect important folders from ransomware attacks.',
      category: 'Security',
      actionText: 'Open Ransomware Protection',
      requiresAdmin: true,
    ),
  ];

  // List of privacy optimization suggestions
  static const List<SystemSuggestion> privacySuggestions = [
    SystemSuggestion(
      title: 'Disable Activity History',
      description: 'Prevent Windows from collecting your activity history.',
      category: 'Privacy',
      actionText: 'Open Activity History Settings',
      requiresAdmin: false,
    ),
    SystemSuggestion(
      title: 'Manage App Permissions',
      description: 'Control which apps can access your camera, microphone, and location.',
      category: 'Privacy',
      actionText: 'Open App Permissions',
      requiresAdmin: false,
    ),
    SystemSuggestion(
      title: 'Disable Advertising ID',
      description: 'Prevent apps from using your advertising ID to show personalized ads.',
      category: 'Privacy',
      actionText: 'Open Privacy Settings',
      requiresAdmin: false,
    ),
    SystemSuggestion(
      title: 'Clear Browsing Data',
      description: 'Remove browsing history, cookies, and cached files from your browsers.',
      category: 'Privacy',
      actionText: 'Clear Browser Data',
      requiresAdmin: false,
    ),
    SystemSuggestion(
      title: 'Disable Telemetry',
      description: 'Reduce data collection by Windows.',
      category: 'Privacy',
      actionText: 'Configure Telemetry Settings',
      requiresAdmin: true,
    ),
  ];

  // List of maintenance optimization suggestions
  static const List<SystemSuggestion> maintenanceSuggestions = [
    SystemSuggestion(
      title: 'Schedule Automatic Maintenance',
      description: 'Set up automatic maintenance to keep your system running smoothly.',
      category: 'Maintenance',
      actionText: 'Open Maintenance Settings',
      requiresAdmin: false,
    ),
    SystemSuggestion(
      title: 'Check Disk for Errors',
      description: 'Scan your disk for errors and fix them.',
      category: 'Maintenance',
      actionText: 'Run Check Disk',
      requiresAdmin: true,
    ),
    SystemSuggestion(
      title: 'Update Device Drivers',
      description: 'Keep your device drivers up to date for better performance and compatibility.',
      category: 'Maintenance',
      actionText: 'Open Device Manager',
      requiresAdmin: true,
    ),
    SystemSuggestion(
      title: 'Monitor System Health',
      description: 'Check system health and reliability history.',
      category: 'Maintenance',
      actionText: 'Open Reliability Monitor',
      requiresAdmin: false,
    ),
    SystemSuggestion(
      title: 'Create System Restore Point',
      description: 'Create a restore point before making system changes.',
      category: 'Maintenance',
      actionText: 'Create Restore Point',
      requiresAdmin: true,
    ),
  ];

  // Get all suggestions
  static List<SystemSuggestion> getAllSuggestions() {
    return [
      ...performanceSuggestions,
      ...securitySuggestions,
      ...privacySuggestions,
      ...maintenanceSuggestions,
    ];
  }

  // Get suggestions by category
  static List<SystemSuggestion> getSuggestionsByCategory(String category) {
    switch (category) {
      case 'Performance':
        return performanceSuggestions;
      case 'Security':
        return securitySuggestions;
      case 'Privacy':
        return privacySuggestions;
      case 'Maintenance':
        return maintenanceSuggestions;
      default:
        return getAllSuggestions();
    }
  }
}
