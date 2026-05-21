# CNAM Calculator — Android (Capacitor + Docker)

Conversion de l'application web CNAM Calculator en **APK Android natif** via [Capacitor](https://capacitorjs.com/), le tout buildé **entièrement dans Docker**.

> Aucune installation d'Android Studio, JDK, SDK Android ou Node.js n'est requise sur la machine hôte. **Docker suffit.**

## Structure du projet

```
cnam-calculator-capacitor-mobile/
├── public/                        # Sources web embarquées dans l'APK
│   ├── index.html                 # Interface calculatrice
│   ├── script.js                  # Logique + appel API backend
│   ├── style.css                  # Styles
│   └── config.js                  # URL du backend (ex: Render)
├── capacitor.config.json          # Configuration Capacitor (appId, webDir)
├── Dockerfile.android             # Pipeline multi-stage : Node → SDK Android → APK
├── docker-compose.android.yml     # Orchestre le build + extraction APK
├── build-android.sh               # Script helper (lance le build en 1 commande)
└── artifacts/                     # APK généré (créé après le build)
    └── cnam-calculator-debug.apk
```

## Prérequis

| Outil | Version minimale |
|-------|------------------|
| Docker | ≥ 24.x |
| Docker Compose | ≥ 2.x |
| Connexion internet | Requise au 1er build |

## Configurer l'URL du backend

Éditer `public/config.js` avec l'URL de votre API :

```javascript
window.APP_CONFIG = {
    BACKEND_URL: "https://votre-api.onrender.com"
};
```

## Générer l'APK Android

```bash
# Méthode 1 — Script helper (recommandée)
chmod +x build-android.sh
./build-android.sh
```

```bash
# Méthode 2 — Docker Compose directement
mkdir -p artifacts
docker compose -f docker-compose.android.yml run --rm android-builder
```

L'APK est déposé dans **`./artifacts/cnam-calculator-debug.apk`**.

> **1er build** : ~10-15 min (téléchargement du SDK Android ~800 MB)  
> **Builds suivants** : ~3-5 min (layers Docker mis en cache)

## Installer l'APK sur un appareil Android

```bash
# Via ADB (USB, débogage USB activé sur l'appareil)
adb install artifacts/cnam-calculator-debug.apk

# Ou transférer le fichier .apk par câble USB / email / Drive
```

## Comment ça marche — Pipeline multi-stage

```
Dockerfile.android
│
├── STAGE 1 — node:20-bookworm-slim
│   ├── npm install @capacitor/core @capacitor/cli @capacitor/android
│   ├── npx cap add android      → génère android/ (projet Gradle natif)
│   └── npx cap sync android     → copie public/ dans les assets Android
│
├── STAGE 2 — eclipse-temurin:17-jdk-jammy
│   ├── wget commandlinetools-linux (Android SDK)
│   ├── sdkmanager : platform-tools + platforms;android-34 + build-tools;34.0.0
│   ├── COPY --from=stage1 android/  +  node_modules/@capacitor/
│   └── ./gradlew assembleDebug      → compile l'APK
│
└── STAGE 3 — alpine:3.19
    └── COPY app-debug.apk → /output/
        CMD : cp /output/*.apk /artifacts/   (volume monté)
```

## Build Release (APK signé)

Pour distribuer sur le Play Store :

1. Créez un keystore :
```bash
keytool -genkey -v -keystore my-release-key.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias my-key-alias
```
2. Configurez `android/app/build.gradle` avec les infos de signature
3. Dans `Dockerfile.android`, remplacez `assembleDebug` par `assembleRelease`

## Origine

Basé sur [cnam-calculator-ui-web](https://github.com/opinaka-attik/cnam-calculator-ui-web) — application web statique convertie en app Android native via Capacitor.
