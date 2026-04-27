# Android Emulator + ws-scrcpy

This stack runs an Android emulator (Play Store image) and exposes browser control through ws-scrcpy.

## Services
- `android-emulator`: uses `halimqarroum/docker-android:api-33-playstore`.
- `ws-scrcpy`: browser UI on port `8233`, connected to emulator ADB over Docker network.

## Paths (persistent, under /home)
- Emulator data: `/home/docker-projects/android-emulator/data`
- ADB keys: `/home/docker-projects/android-emulator/keys`

## Start
```bash
cd /home/docker-projects/android-emulator
docker compose up -d
```

## Access (local/LAN only)
- Browser (server): `http://localhost:8233`
- Browser (LAN devices): `http://<device-ip>:8233`
- ADB (host only): `adb connect 127.0.0.1:5555`

> Public exposure (Cloudflare tunnel + Caddy) was intentionally skipped. If you change your mind, follow `SERVICE_ADDITION_CHECKLIST.md`.

## iOS usage
- Connect the iOS device to the same LAN as the server, then open `http://<device-ip>:8233` in Safari.
- Optional: add the page to Home Screen for app-like launch.
- If touch controls are laggy, lower emulator resolution/density or memory in `.env`.

## Play Store
- Log in from the emulator UI with your Google account.
- Install apps directly inside emulator.

## Optional APK export
After you install an app in the emulator, export its APK/splits:

```bash
cd /home/docker-projects/android-emulator
./scripts/export-apk.sh com.example.app
```

- Default export directory: `/home/docker-projects/android-emulator/apk-exports/<package.name>/`
- Split APK apps produce multiple files (base + config splits).

## Notes
- Requires KVM (`/dev/kvm`) and enough resources (8 GB RAM recommended).
- First boot can take several minutes.
