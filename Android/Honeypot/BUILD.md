# Build-Anleitung - Imker Tagebuch APK

## Voraussetzungen

- Flutter SDK 3.24.5+ installiert
- Android SDK mit API Level 34
- Android Studio oder Android Command Line Tools

## Bekanntes Problem: Gradle Build Error

Aktuell gibt es ein bekanntes Problem mit dem `record` Plugin und Flutter Gradle Properties. Falls der Build fehlschlägt mit:

```
Could not get unknown property 'flutter' for extension 'android'
```

### Lösung:

1. **Öffne**: `android/local.properties`
2. **Stelle sicher, dass folgende Zeilen vorhanden sind**:
   ```
   flutter.compileSdkVersion=34
   flutter.targetSdkVersion=34
   flutter.minSdkVersion=21
   flutter.ndkVersion=25.1.8937393
   ```

3. **Alternative**: Nutze Android Studio zum Bauen (funktioniert zuverlässiger)

## Build-Befehle

### Debug-APK (zum Testen)
```bash
flutter build apk --debug
```

### Release-APK (für Produktion)
```bash
flutter build apk --release
```

### APK-Speicherort
Die fertige APK findest du unter:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Schnelle Installation auf Handy

### Via ADB (Android Debug Bridge)
```bash
# APK auf Handy installieren
adb install build/app/outputs/flutter-apk/app-release.apk

# Mehrere Geräte? Wähle eins:
adb devices
adb -s DEVICE_ID install build/app/outputs/flutter-apk/app-release.apk
```

### Manuell
1. Kopiere `app-release.apk` auf dein Handy
2. Öffne die Datei auf dem Handy
3. Erlaube "Installation aus unbekannten Quellen"
4. Installiere die App

## Alternative: Android Studio Build

Falls der Flutter Build nicht funktioniert:

1. Öffne das Projekt in Android Studio
2. **File** → **Open** → Wähle `android/` Ordner
3. Warte bis Gradle Sync fertig ist
4. **Build** → **Build Bundle(s) / APK(s)** → **Build APK(s)**
5. APK findest du in `android/app/build/outputs/apk/release/`

## Troubleshooting

### "Developer Mode" Fehler auf Windows
```powershell
# Öffne Entwicklereinstellungen
start ms-settings:developers

# Aktiviere "Developer Mode"
```

### Gradle Daemon Fehler
```bash
# Gradle Cache löschen
cd android
./gradlew clean

# Zurück zum Projekt-Root
cd ..
flutter clean
flutter pub get
```

### Android SDK nicht gefunden
Stelle sicher, dass `ANDROID_HOME` gesetzt ist:
```bash
# Windows PowerShell
$env:ANDROID_HOME = "C:\Users\DEIN_NAME\AppData\Local\Android\Sdk"

# Linux/Mac
export ANDROID_HOME=$HOME/Android/Sdk
```

## Performance-Optimierungen für Release

Die Release-APK ist bereits optimiert mit:
- Code Obfuscation
- Tree Shaking (unused code removal)
- Minified Libraries
- Optimized Assets

Größe: ~50-60 MB (je nach Android SDK)

## Signierung (Optional für Play Store)

Für den Google Play Store Upload:

1. Erstelle Keystore:
```bash
keytool -genkey -v -keystore imker-tagebuch.jks -keyalg RSA -keysize 2048 -validity 10000 -alias imker
```

2. Erstelle `android/key.properties`:
```
storePassword=DEIN_PASSWORD
keyPassword=DEIN_PASSWORD
keyAlias=imker
storeFile=../imker-tagebuch.jks
```

3. Passe `android/app/build.gradle` an (Signierung aktivieren)

4. Build:
```bash
flutter build apk --release
```

---

**Support**: Bei Problemen erstelle ein Issue mit:
- Flutter Version (`flutter --version`)
- Fehlermeldung
- OS (Windows/Linux/Mac)
