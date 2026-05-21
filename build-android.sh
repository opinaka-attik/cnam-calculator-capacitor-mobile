#!/usr/bin/env bash
# ==============================================================
# build-android.sh
# Génère l'APK Android via Docker — aucune installation locale requise
# Prérequis : Docker >= 24 et Docker Compose >= 2
#
# Après exécution :
#   ./artifacts/cnam-calculator-debug.apk  ← APK à installer
#   ./android-src/                         ← Code source Android/Kotlin
# ==============================================================
set -euo pipefail

ARTIFACTS_DIR="./artifacts"
ANDROID_SRC_DIR="./android-src"

echo ""
echo "================================================"
echo "  CNAM Calculator - Build Android APK (Docker) "
echo "================================================"
echo ""

# Création des dossiers de sortie
mkdir -p "${ARTIFACTS_DIR}"
mkdir -p "${ANDROID_SRC_DIR}"

echo "[1/3] Construction de l'image Docker multi-stage..."
echo "      (1ère exécution : ~10-15 min — téléchargement SDK Android)"
echo ""
docker compose -f docker-compose.android.yml build android-builder

echo ""
echo "[2/3] Lancement du build, export APK + sources Android..."
echo ""
docker compose -f docker-compose.android.yml run --rm android-builder

echo ""
echo "[3/3] Vérification..."

if [ -f "${ARTIFACTS_DIR}/cnam-calculator-debug.apk" ]; then
    APK_SIZE=$(du -sh "${ARTIFACTS_DIR}/cnam-calculator-debug.apk" | cut -f1)
    echo ""
    echo "  ✅ APK généré :"
    echo "     ${ARTIFACTS_DIR}/cnam-calculator-debug.apk (${APK_SIZE})"
else
    echo "  ❌ ERREUR : APK non trouvé dans ${ARTIFACTS_DIR}/"
    exit 1
fi

if [ -d "${ANDROID_SRC_DIR}/app/src/main" ]; then
    echo ""
    echo "  ✅ Sources Android/Kotlin exportées :"
    echo "     ${ANDROID_SRC_DIR}/app/src/main/java/fr/cnam/calculator/MainActivity.kt"
    echo "     ${ANDROID_SRC_DIR}/app/src/main/AndroidManifest.xml"
    echo "     ${ANDROID_SRC_DIR}/app/src/main/res/"
fi

echo ""
echo "Pour installer sur un appareil Android (ADB) :"
echo "  adb install ${ARTIFACTS_DIR}/cnam-calculator-debug.apk"
echo ""
echo "Pour enrichir le code natif Kotlin :"
echo "  Modifier : ${ANDROID_SRC_DIR}/app/src/main/java/fr/cnam/calculator/MainActivity.kt"
echo "  Puis relancer : ./build-android.sh"
echo ""
