@echo off
REM Script para limpar e fazer rebuild do Flutter

echo =================================
echo Limpando cache do Flutter...
echo =================================
cd /d d:\PROJETOS\Lanchonete\pdv_lanchonete_gustavo\pdv_lanchonetes
flutter clean

echo.
echo =================================
echo Restaurando dependências...
echo =================================
flutter pub get

echo.
echo =================================
echo Limpando build do Android...
echo =================================
cd android
call gradlew clean
cd ..

echo.
echo =================================
echo Executando flutter run...
echo =================================
flutter run

pause
