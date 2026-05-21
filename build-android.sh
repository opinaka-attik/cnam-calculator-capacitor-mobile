#!/usr/bin/env bash
# ==============================================================
# build-android.sh
# Génère l'APK Android via Docker — aucune installation locale requise
# Prérequis : Docker >= 24 et Docker Compose >= 2
# ==============================================================
set -euo pipefail

ARTIFACTS_DIR="./artifacts"

echo ""
echo "================================================"
echo "  CNAM Calculator - Build Android APK (Docker) "
echo "================================================"
echo ""

mkdir -p "${ARTIFACTS_DIR}"

echo "[1/3] Construction de l'image Docker multi-stage..."
echo "      (1ère exécution : ~10-15 min — téléchargement SDK Android)"
echo ""
docker compose -f docker-compose.android.yml build android-builder

echo ""
echo "[2/3] Lancement du build et extraction de l'APK..."
echo ""
docker compose -f docker-compose.android.yml run --rm android-builder

echo ""
echo "[3/3] Vérification..."
if [ -f "${ARTIFACTS_DIR}/cnam-calculator-debug.apk" ]; then
    APK_SIZE=$(du -sh "${ARTIFACTS_DIR}/cnam-calculator-debug.apk" | cut -f1)
    echo ""
    echo "  ✅ APK généré avec succès !"
    echo "  Chemin : ${ARTIFACTS_DIR}/cnam-calculator-debug.apk"
    echo "  Taille : ${APK_SIZE}"
    echo ""
    echo "Pour installer via ADB (appareil branché en USB) :"
    echo "  adb install ${ARTIFACTS_DIR}/cnam-calculator-debug.apk"
    echo ""
else
    echo "  ❌ ERREUR : APK non trouvé dans ${ARTIFACTS_DIR}/"
    echo "  Consultez les logs ci-dessus."
    exit 1
fi
