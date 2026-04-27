import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class AppUpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String htmlUrl;
  final String? downloadUrl;
  final String? changelog;
  final DateTime? publishedAt;

  bool get isUpdateAvailable {
    final cur = _parseVersion(currentVersion);
    final lat = _parseVersion(latestVersion);
    for (var i = 0; i < 3; i++) {
      if (lat[i] != cur[i]) return lat[i] > cur[i];
    }
    return false;
  }

  const AppUpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.htmlUrl,
    this.downloadUrl,
    this.changelog,
    this.publishedAt,
  });

  static List<int> _parseVersion(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'^v'), '');
    final parts = cleaned.split(RegExp(r'[.+-]'));
    final out = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null) break;
      out.add(n);
      if (out.length == 3) break;
    }
    while (out.length < 3) {
      out.add(0);
    }
    return out;
  }
}

/// Polls GitHub Releases API for the configured repo and returns whether
/// a newer release is available compared to the current package version.
class UpdateCheckerService {
  UpdateCheckerService._();
  static final UpdateCheckerService instance = UpdateCheckerService._();

  // Owner / repo can be overridden via --dart-define.
  static const String _repoOwner = String.fromEnvironment(
    'UPDATE_REPO_OWNER',
    defaultValue: 'ibnuholidai-tech',
  );
  static const String _repoName = String.fromEnvironment(
    'UPDATE_REPO_NAME',
    defaultValue: 'sekom_clenner',
  );
  static const Duration _timeout = Duration(seconds: 6);

  Future<AppUpdateInfo?> check({required String currentVersion}) async {
    final uri = Uri.parse(
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
    );
    try {
      final res = await http
          .get(uri, headers: {'Accept': 'application/vnd.github+json'})
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = (body['tag_name'] as String? ?? '').trim();
      if (tag.isEmpty) return null;

      final assets = (body['assets'] as List<dynamic>? ?? const []);
      String? exe;
      for (final a in assets.whereType<Map<String, dynamic>>()) {
        final name = (a['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.exe') ||
            name.endsWith('.msi') ||
            name.endsWith('.msix') ||
            name.endsWith('.zip')) {
          exe = a['browser_download_url'] as String?;
          break;
        }
      }

      return AppUpdateInfo(
        latestVersion: tag,
        currentVersion: currentVersion,
        htmlUrl:
            body['html_url'] as String? ??
            'https://github.com/$_repoOwner/$_repoName/releases',
        downloadUrl: exe,
        changelog: body['body'] as String?,
        publishedAt: DateTime.tryParse(body['published_at'] as String? ?? ''),
      );
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
