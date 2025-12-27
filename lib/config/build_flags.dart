// Build flags for release behavior without removing any features.
//
// Usage to enable auto-elevate on specific builds:
//   flutter build windows --release --dart-define=AUTO_ELEVATE=true
//
// By default, auto-elevate is disabled to reduce AV/SmartScreen heuristics.
// All admin-required features will still work via on-demand elevation.

const bool kAutoElevate = bool.fromEnvironment('AUTO_ELEVATE', defaultValue: false);
