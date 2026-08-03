# my boss app — iOS urgent build (no local Xcode)

> **Supplementary guide.** For day-to-day Android and local Flutter setup, use the canonical guide: [`docs/mobile/ANDROID_STUDIO.md`](../../mobile/ANDROID_STUDIO.md).

Apple **requires an Apple ID** to install on a physical iPhone. There is no bypass.

**Replace placeholder IPs** with your demo server LAN IP (`ipconfig getifaddr en0`) and tunnel host from `demo-public-url.txt`.

## Fastest path (~30–45 min total)

### You need ONE working Apple ID

- Borrow a colleague’s Apple ID for 1 hour, **OR**
- Create a new one at https://appleid.apple.com/account (use Gmail + phone SMS)

---

## Option A — Codemagic (fastest, no Xcode on your Mac)

1. Push this repo to GitHub (if not already).
2. Open https://codemagic.io → **Sign up with GitHub**.
3. **Add application** → select the **`myboss-mobile`** repository.
4. Choose **Flutter** workflow.
5. Project path: `myboss-mobile`
6. Build arguments (update LAN IP from `demo_server_host.dart`; add tunnel host from `demo-public-url.txt` when available):

   ```
   --dart-define=DEMO_MODE=true
   --dart-define=GATEWAY_ORIGIN=http://<YOUR_LAN_IP>:8090
   --dart-define=API_HOSTS=<YOUR_LAN_IP>,<tunnel-host>.trycloudflare.com
   ```

7. **iOS code signing** → sign in with **Apple ID** (free account works for device testing).
8. Connect iPhone via USB once so Codemagic can register the device, or add UDID manually.
9. Start build → download **.ipa** when done (~15–20 min).
10. Install via Codemagic link, or Xcode → Devices → drag IPA.

---

## Option B — GitHub Actions (unsigned build)

1. GitHub.com → your repo → **Actions** tab.
2. **iOS Demo Build** → **Run workflow**.
3. Wait ~10 min → download artifact `myboss-ios-unsigned`.
4. **Still need Apple ID** on a Mac with Xcode to sign and install on iPhone.

---

## Option C — Download Xcode without App Store

1. Safari → https://developer.apple.com/download/all
2. Sign in with Apple ID.
3. Download **Xcode .xip** → extract → move to Applications.
4. Terminal:

   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   brew install cocoapods
   cd ~/Desktop/myboss-mobile
   ./build-demo-ios.sh --ipa
   ```

---

## If demo is TODAY and no Apple ID works

Use **Android APK** (no Apple account):

```bash
cd myboss-mobile
./build-local-android.sh
# Output: build/android-dist/myboss-demo-<lan-ip>.apk
```

Login: `demo@orange.com` + OTP (auto-filled in demo mode).
