#!/usr/bin/env sh
# ==============================================================
# convert-to-kotlin.sh
# Remplace MainActivity.java par MainActivity.kt dans le projet
# Android généré par Capacitor
# ==============================================================
set -e

PACKAGE_DIR="android/app/src/main/java/fr/cnam/calculator"

echo "[kotlin] Suppression de MainActivity.java..."
rm -f "${PACKAGE_DIR}/MainActivity.java"

echo "[kotlin] Création de MainActivity.kt..."
cat > "${PACKAGE_DIR}/MainActivity.kt" << 'KOTLIN'
package fr.cnam.calculator

import com.getcapacitor.BridgeActivity

/**
 * MainActivity en Kotlin.
 * Hérite de BridgeActivity (Capacitor) qui gère la WebView.
 *
 * Enrichissement possible ici :
 *   - Enregistrer des plugins : registerPlugin(MonPlugin::class.java)
 *   - Accéder aux APIs Android natives
 */
class MainActivity : BridgeActivity()
KOTLIN

echo "[kotlin] Ajout du plugin Kotlin dans android/build.gradle..."
# Ajoute kotlin-gradle-plugin dans les classpath du build.gradle racine
sed -i "s|classpath 'com.android.tools.build:gradle|classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.23'\n        classpath 'com.android.tools.build:gradle|" android/build.gradle

echo "[kotlin] Activation du plugin kotlin-android dans app/build.gradle..."
# Ajoute apply plugin kotlin-android juste apres apply plugin android
sed -i "/apply plugin: 'com.android.application'/a apply plugin: 'kotlin-android'" android/app/build.gradle

echo "[kotlin] Ajout de kotlin-stdlib dans les dependances app..."
# Ajoute la stdlib Kotlin dans dependencies {}
sed -i "/^dependencies {/a\    implementation 'org.jetbrains.kotlin:kotlin-stdlib:1.9.23'" android/app/build.gradle

echo "[kotlin] Conversion terminee !"
echo "  => ${PACKAGE_DIR}/MainActivity.kt"
