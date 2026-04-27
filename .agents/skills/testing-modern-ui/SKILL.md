# Smoke-testing the modern sidebar UI on Linux

The app targets Windows but its Flutter UI shell can be smoke-tested on the Devin Linux desktop. Use this when validating layout, navigation, theme, or any pure-Dart screen logic. Backend system calls are Windows-only and are *expected* to log errors on Linux; the UI must keep working anyway.

## When to use
- Validating any change to `lib/screens/modern_main_screen.dart`, `lib/screens/modern/**`, `lib/widgets/modern/**`, or `lib/theme/app_theme.dart`.
- Verifying that a tab still renders and that destructive actions still show their confirmation dialog.
- **Do NOT** use this to validate Windows-specific backend behaviour (defender check, browser cleaning, recycle bin, ms-settings: URIs, powershell calls, advapi32 lookups). Those need a real Windows host.

## Build deps (one-time per VM)
```bash
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  cmake ninja-build clang pkg-config lld \
  libgtk-3-dev libblkid-dev liblzma-dev libsecret-1-dev \
  libjsoncpp-dev libnotify-dev libayatana-appindicator3-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-libav \
  wmctrl xdotool
```

Flutter SDK is provisioned by `.devin/environment.yaml` (`/home/ubuntu/flutter/bin` on PATH) and Linux desktop is enabled there.

## Build & run
```bash
cd /home/ubuntu/repos/sekom_clenner
flutter pub get
mkdir -p build/native_assets/linux           # Flutter sometimes forgets to scaffold this dir; cmake_install needs it
flutter build linux --debug                  # output: build/linux/x64/debug/bundle/sekom_clenner
DISPLAY=:0 nohup ./build/linux/x64/debug/bundle/sekom_clenner > /tmp/sekom_clenner.log 2>&1 &
sleep 4
DISPLAY=:0 wmctrl -r "Sekom Cleaner" -b add,maximized_vert,maximized_horz
```

If cmake errors with `file INSTALL cannot copy file ... to /usr/local/...`, wipe the build dir and retry — the `CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT` cache gets stuck after a partial build:
```bash
rm -rf build && mkdir -p build/native_assets/linux && flutter build linux --debug
```

## What to expect in the log (and ignore)
On Linux, `SystemService` will spit harmless errors like:
- `ProcessException: No such file or directory  Command: powershell ...`
- `Failed to load dynamic library 'advapi32.dll'`
- `Atk-CRITICAL **: atk_socket_embed: assertion 'plug_id != NULL' failed`
- `dbind-WARNING ... AT-SPI: Error retrieving accessibility bus address`

None of these should crash the app. If a tab fails to render or the app exits, that is a real bug.

## Smoke checklist (post any UI change)
1. App boots, sidebar visible on **left** with 7 destinations + `by Ibnu` footer.
2. Click footer chevron — sidebar collapses to icon rail; click again — expands.
3. Click each of the 7 destinations. Right pane swaps; no red error overlay.
4. System Cleaner: click 2-3 browser pills + 2-3 folder pills — they toggle independently.
5. Reset tab: click any destructive button — confirmation dialog with **Batal / Lanjutkan** appears.
6. Status bar at bottom is present and shows contextual text on every tab.

Record the run with annotations and attach to the message back to the user — see general testing skill for the recording protocol.

## Cleanup
```bash
pkill -f sekom_clenner
```

## Devin Secrets Needed
None for Linux smoke testing. Windows end-to-end testing would require a Windows host or VM (out of scope for Devin Linux runners).
