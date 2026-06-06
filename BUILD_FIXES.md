# Resumo das Correções de Build do Flutter

## Problemas Identificados e Resolvidos

### 1. ✅ Conflito de Plugins Gradle
**Problema:** Plugin `dev.flutter.flutter-gradle-plugin` estava definido em dois lugares com versões diferentes.

**Solução:**
- Removido duplicação de plugins no `android/app/build.gradle.kts`
- Mantido apenas a definição correta no `android/settings.gradle.kts`

**Arquivo alterado:** `android/app/build.gradle.kts`
```kotlin
plugins {
    id("com.android.application") apply true
    id("kotlin-android") apply true
    id("dev.flutter.flutter-gradle-plugin") apply true
}
```

---

### 2. ✅ Kotlin Version Desatualizada
**Problema:** Kotlin 1.8.22 está desatualizado. Flutter requer versão 2.1.0+

**Solução:**
- Atualizado Kotlin de 1.8.22 para 2.1.0 no `android/settings.gradle.kts`

**Arquivo alterado:** `android/settings.gradle.kts`
```kotlin
id("org.jetbrains.kotlin.android") version "2.1.0" apply false
```

---

### 3. ✅ Erro de Null Casting no SigningConfig
**Problema:** `keystoreProperties` tentava fazer cast de valores null sem verificação.

**Solução:**
- Adicionada verificação `if (keystoreProperties.containsKey("keyAlias"))` antes de acessar os valores

**Arquivo alterado:** `android/app/build.gradle.kts`
```kotlin
signingConfigs {
    create("release") {
        if (keystoreProperties.containsKey("keyAlias")) {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
}
```

---

### 4. ✅ MainActivity Não Encontrada
**Problema:** ClassNotFoundException - Classe `com.portal.pdvlanchonetes.MainActivity` não estava no DEX.

**Solução:**
- Criada estrutura de diretórios correta: `android/app/src/main/kotlin/com/portal/pdvlanchonetes/`
- Criado arquivo `MainActivity.kt` com package correto:

**Arquivo criado:** `android/app/src/main/kotlin/com/portal/pdvlanchonetes/MainActivity.kt`
```kotlin
package com.portal.pdvlanchonetes

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

---

### 5. ✅ MultiDex Não Habilitado
**Problema:** Aplicação pode ter muitas classes, causando erro de DEX.

**Solução:**
- Adicionado `multiDexEnabled = true` no `defaultConfig`

**Arquivo alterado:** `android/app/build.gradle.kts`
```kotlin
defaultConfig {
    // ... outras configurações
    multiDexEnabled = true
}
```

---

## Arquivos Modificados

1. ✅ `android/app/build.gradle.kts` - Corrigidos plugins, signingConfig e adicionado multiDex
2. ✅ `android/settings.gradle.kts` - Atualizada versão do Kotlin
3. ✅ `android/app/src/main/kotlin/com/portal/pdvlanchonetes/MainActivity.kt` - Criado
4. ✅ `.vscode/settings.json` - Configurado cmd.exe como terminal padrão
5. ✅ `build_clean.bat` - Script de limpeza e rebuild

---

## Como Testar

Execute o script de limpeza e rebuild:
```bash
build_clean.bat
```

Ou manualmente:
```bash
flutter clean
flutter pub get
cd android && gradlew clean && cd ..
flutter run
```

---

## Observações Importantes

- A estrutura de pacotes agora corresponde ao `applicationId` definido no `build.gradle.kts`
- O arquivo antigo `android/app/src/main/kotlin/com/example/lanchonete/MainActivity.kt` pode ser removido
- O `key.properties` é opcional para debug builds

