# CNAM Calculator — Android (Capacitor + Docker)

Conversion de l'application web CNAM Calculator en **APK Android natif** via [Capacitor](https://capacitorjs.com/), le tout buildé **entièrement dans Docker**.

> Aucune installation d'Android Studio, JDK, SDK Android ou Node.js n'est requise sur la machine hôte. **Docker suffit.**

---

## Structure du projet

```
cnam-calculator-capacitor-mobile/
│
├── public/                              # Sources web embarquées dans l'APK
│   ├── index.html                       # Interface calculatrice
│   ├── script.js                        # Logique + appel API backend
│   ├── style.css                        # Styles
│   └── config.js                        # URL du backend (Render, etc.)
│
├── capacitor.config.json                # Config Capacitor (appId, webDir)
│
├── scripts/
│   └── convert-to-kotlin.sh             # Convertit MainActivity.java -> .kt
│
├──  PIPELINE 1 — Build initial
│   ├── Dockerfile.android               # Multi-stage : Node -> SDK -> APK
│   ├── docker-compose.android.yml       # Orchestre le build initial
│   └── build-android.sh                 # Lance le pipeline initial
│
├──  PIPELINE 2 — Build depuis sources Kotlin
│   ├── Dockerfile.android.from-src      # Multi-stage : sync web -> SDK -> APK
│   ├── docker-compose.android.from-src.yml
│   └── build-android-from-src.sh        # Lance le pipeline d'enrichissement
│
├── artifacts/                           # APK généré (créé après le build)
│   └── cnam-calculator-debug.apk
│
└── android-src/                         # Sources Android/Kotlin exportées
    └── app/src/main/
        ├── java/fr/cnam/calculator/
        │   └── MainActivity.kt          # ← Fichier principal à enrichir
        ├── AndroidManifest.xml          # Permissions de l'app
        └── res/                         # Icônes, splash screen, strings
```

---

## Prérequis

| Outil | Version minimale |
|-------|------------------|
| Docker | ≥ 24.x |
| Docker Compose | ≥ 2.x |
| Connexion internet | Requise au 1er build |

---

## Configurer l'URL du backend

Éditer `public/config.js` avec l'URL de votre API :

```javascript
window.APP_CONFIG = {
    BACKEND_URL: "https://votre-api.onrender.com"
};
```

---

## Pipeline 1 — Build initial

Génère le projet Android depuis zéro, convertit `MainActivity` en Kotlin,
compile l'APK et exporte les sources dans `android-src/`.

```bash
chmod +x build-android.sh
./build-android.sh
```

**Résultat :**

```
artifacts/cnam-calculator-debug.apk   ← APK prêt à installer
android-src/                          ← Sources Kotlin à enrichir
```

> **1er build** : ~10-15 min (téléchargement SDK Android ~800 MB)  
> **Builds suivants** : ~3-5 min (layers Docker mis en cache)

---

## Pipeline 2 — Build depuis les sources Kotlin

Utiliser après avoir modifié `android-src/` (ajout de plugins, code natif, etc.).
Le code Kotlin est préservé, seuls les assets web sont resynchronisés.

```bash
# 1. Modifier le code Kotlin
code android-src/app/src/main/java/fr/cnam/calculator/MainActivity.kt

# 2. Compiler avec vos modifications
chmod +x build-android-from-src.sh
./build-android-from-src.sh
```

**Résultat :**

```
artifacts/cnam-calculator-debug.apk   ← APK avec vos modifications Kotlin
```

> Le dossier `android-src/` doit exister (lancer `build-android.sh` en 1er).

---

## Installer l'APK sur un appareil Android

```bash
# Via ADB (USB, débogage USB activé sur l'appareil)
adb install artifacts/cnam-calculator-debug.apk

# Ou transférer le fichier .apk par câble USB / email / Google Drive
```

---

## Enrichir le code natif Kotlin

Capacitor génère un vrai projet Android natif. Vous pouvez l'enrichir de plusieurs façons :

### Fichier principal : `MainActivity.kt`

```kotlin
package fr.cnam.calculator

import com.getcapacitor.BridgeActivity
import android.os.Bundle
import android.view.WindowManager

class MainActivity : BridgeActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // Enregistrer vos plugins personnalisés
        registerPlugin(MonPlugin::class.java)
        super.onCreate(savedInstanceState)

        // Exemple : garder l'écran allumé
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
```

### Plugins Capacitor officiels

Ajouter dans `android-src/app/build.gradle` puis resynchroniser :

```bash
# Exemples de plugins disponibles
npm install @capacitor/camera          # Caméra
npm install @capacitor/geolocation     # GPS
npm install @capacitor/push-notifications  # Notifications push
npm install @capacitor/filesystem      # Accès fichiers
npm install @capacitor/haptics         # Vibrations
```

### Permissions Android

Éditer `android-src/app/src/main/AndroidManifest.xml` :

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

## Comment ça marche — Pipelines multi-stage

### Pipeline 1 (build initial)

```
Dockerfile.android
│
├── STAGE 1 — node:20-bookworm-slim
│   ├── npm install @capacitor/core @capacitor/cli @capacitor/android
│   ├── npx cap add android        → génère android/ (projet Gradle)
│   ├── npx cap sync android       → copie public/ dans les assets
│   └── convert-to-kotlin.sh       → MainActivity.java -> .kt
│
├── STAGE 2 — eclipse-temurin:17-jdk-jammy
│   ├── Android SDK (cmdline-tools, platform-tools, android-34)
│   └── ./gradlew assembleDebug    → compile l'APK
│
└── STAGE 3 — alpine:3.19
    ├── Export APK       → /artifacts/
    └── Export sources   → /android-src/
```

### Pipeline 2 (build depuis sources Kotlin)

```
Dockerfile.android.from-src
│
├── STAGE 1 — node:20-bookworm-slim
│   ├── COPY android-src/          → récupère VOS sources Kotlin
│   └── npx cap sync android       → resynchronise uniquement public/
│
├── STAGE 2 — eclipse-temurin:17-jdk-jammy
│   └── ./gradlew assembleDebug    → compile avec vos modifications
│
└── STAGE 3 — alpine:3.19
    └── Export APK       → /artifacts/
```

---

## Build Release (APK signé)

Pour distribuer sur le Play Store :

1. Créer un keystore :

```bash
keytool -genkey -v -keystore my-release-key.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias my-key-alias
```

2. Configurer `android-src/app/build.gradle` avec les infos de signature
3. Dans `Dockerfile.android.from-src`, remplacer `assembleDebug` par `assembleRelease`
4. Relancer `./build-android-from-src.sh`

---

## Origine

Basé sur [cnam-calculator-ui-web](https://github.com/opinaka-attik/cnam-calculator-ui-web) — application web statique convertie en app Android native via Capacitor.
