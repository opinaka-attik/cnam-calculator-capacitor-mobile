#!/usr/bin/env bash
# ==============================================================
# build-android-from-src.sh
# Compile l'APK Android depuis les sources Kotlin de android-src/
#
# A utiliser apres avoir modifie ou enrichi le code Kotlin :
#   android-src/app/src/main/java/fr/cnam/calculator/MainActivity.kt
#
# Prerequis : avoir execute ./build-android.sh au moins une fois
# ==============================================================
set -euo pipefail

ANDROID_SRC_DIR="./android-src"
ARTIFACTS_DIR="./artifacts"

echo ""
echo "==================================================="
echo "  CNAM Calculator - Build APK depuis sources Kotlin"
echo "==================================================="
echo ""

# Verification : android-src/ doit exister
if [ ! -d "${ANDROID_SRC_DIR}/app/src/main" ]; then
    echo "ERREUR : ${ANDROID_SRC_DIR}/ introuvable ou incomplet."
    echo ""
    echo "Lancez d'abord le build initial :"
    echo "  ./build-android.sh"
    exit 1
fi

mkdir -p "${ARTIFACTS_DIR}"

echo "Sources Kotlin detectees :"
echo "  ${ANDROID_SRC_DIR}/app/src/main/java/fr/cnam/calculator/"
ls "${ANDROID_SRC_DIR}/app/src/main/java/fr/cnam/calculator/"
echo ""

echo "[1/2] Construction de l'image Docker..."
docker compose -f docker-compose.android.from-src.yml build android-from-src

echo ""
echo "[2/2] Compilation de l'APK depuis vos sources Kotlin..."
docker compose -f docker-compose.android.from-src.yml run --rm android-from-src

echo ""
if [ -f "${ARTIFACTS_DIR}/cnam-calculator-debug.apk" ]; then
    APK_SIZE=$(du -sh "${ARTIFACTS_DIR}/cnam-calculator-debug.apk" | cut -f1)
    echo "  APK genere : ${ARTIFACTS_DIR}/cnam-calculator-debug.apk (${APK_SIZE})"
else
    echo "  ERREUR : APK non trouve dans ${ARTIFACTS_DIR}/"
    exit 1
fi

echo ""
echo "Pour installer sur un appareil Android :"
echo "  adb install ${ARTIFACTS_DIR}/cnam-calculator-debug.apk"
echo ""
