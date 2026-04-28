import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/update_checker_service.dart';

/// One-shot async lookup of "is there a newer GitHub release than the
/// version baked into this app".
///
/// Errors and timeouts resolve to `null` so the UI can choose to show
/// nothing instead of a banner.
final updateStatusProvider = FutureProvider<AppUpdateInfo?>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return await UpdateCheckerService.instance.check(
      currentVersion: info.version,
    );
  } catch (_) {
    return null;
  }
});
