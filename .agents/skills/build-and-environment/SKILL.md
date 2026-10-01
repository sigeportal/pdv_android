---
name: build-and-environment
description: >-
  Instruções de build, compilação Android, Gradle KTS, compatibilidade Kotlin 2.1.0,
  MultiDex e rotinas de solução de erros de ambiente no PDV.
---

# Build e Ambiente Android (PDV Lanchonete)

Este documento registra as configurações críticas de build do Flutter/Android e o checklist para evitar regressões de compilação.

---

## 🛠️ Especificações do Ambiente Android

- **Application ID**: `com.portal.pdvlanchonetes`
- **Kotlin Version**: `2.1.0` (definido em `android/settings.gradle.kts`)
- **Gradle Script**: Kotlin DSL (`build.gradle.kts` e `settings.gradle.kts`)
- **MultiDex**: Habilitado (`multiDexEnabled = true` no `defaultConfig`) para suportar a quantidade de classes do SDK PayGo e pacotes externos.
- **Estrutura do MainActivity**:
  - Caminho: `android/app/src/main/kotlin/com/portal/pdvlanchonetes/MainActivity.kt`
  - Pacote: `package com.portal.pdvlanchonetes`

---

## 📋 Checklist de Configurações Críticas

1. **Evitar Conflito de Plugins Gradle**:
   - `dev.flutter.flutter-gradle-plugin` deve estar declarado de forma limpa sem duplicação entre `settings.gradle.kts` e `app/build.gradle.kts`.
2. **SigningConfig com Verificação de Null**:
   - O `keystoreProperties` no `build.gradle.kts` sempre verifica `containsKey("keyAlias")` antes de fazer cast para string, permitindo builds em modo debug mesmo sem keystore de release.

---

## 🧹 Script de Limpeza e Rebuild

Para reconstruir o projeto do zero de forma limpa:
```bash
# Executando o script automatizado:
build_clean.bat

# Ou manualmente:
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```
