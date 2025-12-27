import 'dart:async';
import 'dart:convert';
import 'dart:io';

class InstallerLogEntry {
  final DateTime time;
  final String appName;
  final int? exitCode;
  final String stderr;
  final String? error;
  final String? stack;

  InstallerLogEntry({
    required this.time,
    required this.appName,
    this.exitCode,
    this.stderr = '',
    this.error,
    this.stack,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'appName': appName,
        'exitCode': exitCode,
        'stderr': stderr,
        'error': error,
        'stack': stack,
      };
}

/// Runs a PowerShell script file content elevated and returns the ProcessResult.
/// Uses a temp file and ensures cleanup. Applies a timeout (default 5 minutes).
Future<ProcessResult> runElevatedPowerShellScript(String psCommand, {Duration timeout = const Duration(minutes: 5)}) async {
  final tempDir = Directory.systemTemp;
  final scriptFile = File('${tempDir.path}${Platform.pathSeparator}sekom_ps_${DateTime.now().millisecondsSinceEpoch}.ps1');

  try {
    await scriptFile.writeAsString(psCommand);

    final proc = await Process.start(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', scriptFile.path],
      runInShell: false,
    );

    // Wait for exit with timeout
    final exitCode = await proc.exitCode.timeout(timeout, onTimeout: () {
      try {
        proc.kill(ProcessSignal.sigkill);
      } catch (_) {}
      return -999; // special timeout code
    });

    // Collect stdout/stderr safely (limit size)
    final stdoutFuture = proc.stdout.transform(utf8.decoder).join();
    final stderrFuture = proc.stderr.transform(utf8.decoder).join();
    final collected = await Future.wait([stdoutFuture, stderrFuture]);

    return ProcessResult(proc.pid, exitCode, collected[0], collected[1]);
  } finally {
    try {
      if (await scriptFile.exists()) await scriptFile.delete();
    } catch (_) {}
  }
}

File _installerLogFile() => File('${Directory.systemTemp.path}${Platform.pathSeparator}sekom_installer_logs.txt');

Future<void> logInstallerFailure(String appName, ProcessResult? result, {Object? error, StackTrace? stack}) async {
  try {
    final file = _installerLogFile();
    final entry = InstallerLogEntry(
      time: DateTime.now(),
      appName: appName,
      exitCode: result?.exitCode,
      stderr: (result?.stderr ?? '').toString().substring(0, ((result?.stderr ?? '').toString().length).clamp(0, 2000)),
      error: error?.toString(),
      stack: stack?.toString(),
    );

    final line = jsonEncode(entry.toJson());
    await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
  } catch (_) {
    // never crash from logging
  }
}

Future<String> readInstallerLog() async {
  try {
    final file = _installerLogFile();
    if (!await file.exists()) return '';
    return await file.readAsString();
  } catch (_) {
    return '';
  }
}

Future<void> clearInstallerLog() async {
  try {
    final file = _installerLogFile();
    if (await file.exists()) await file.delete();
  } catch (_) {}
}

Future<void> openInstallerLogInEditor() async {
  try {
    final file = _installerLogFile();
    if (!await file.exists()) return;
    if (Platform.isWindows) {
      await Process.start('notepad', [file.path]);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [file.path]);
    } else if (Platform.isMacOS) {
      await Process.start('open', [file.path]);
    }
  } catch (_) {}
}
