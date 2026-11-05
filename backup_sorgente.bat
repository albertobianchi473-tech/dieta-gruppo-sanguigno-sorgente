@echo off
chcp 65001 >nul
title Backup Progetto su GitHub

echo ============================================
echo   Backup Codice Sorgente Dieta Gruppo Sanguigno
echo ============================================
echo.

REM Vai nella cartella del progetto
cd /d "%~dp0"

REM Verifica che esista pubspec.yaml (per sicurezza)
if not exist "pubspec.yaml" (
    echo ERRORE: pubspec.yaml non trovato!
    echo Assicurati di aver messo questo file .bat nella cartella del progetto.
    pause
    exit /b 1
)

echo [1/6] Verifico che .gitignore esista...
if not exist ".gitignore" (
    echo .gitignore non trovato, lo creo...
    (
        echo .dart_tool/
        echo .packages
        echo build/
        echo .flutter-plugins
        echo .flutter-plugins-dependencies
        echo .idea/
        echo .vscode/
        echo *.iml
        echo .DS_Store
    ) > .gitignore
    echo .gitignore creato con successo.
) else (
    echo .gitignore gia esistente.
)
echo.

echo [2/6] Inizializzo Git...
if not exist ".git" (
    git init
    git branch -M main
    echo Git inizializzato.
) else (
    echo Git gia inizializzato.
)
echo.

echo [3/6] Pulisco la memoria di Git da vecchie cartelle build (se presenti)...
git rm -r --cached build/ >nul 2>&1
git rm -r --cached .dart_tool/ >nul 2>&1
echo Pulizia completata (i file restano sul tuo PC, vengono solo rimossi da Git).
echo.

echo [4/6] Aggiungo i file (escludendo quelli nel .gitignore)...
git add .
echo File aggiunti.
echo.

echo [5/6] Creo il commit...
git commit -m "Backup automatico codice sorgente - %date% %time%"
echo.

echo [6/6] Collego il repository remoto e carico su GitHub...
git remote set-url origin https://github.com/albertobianchi473-tech/dieta-gruppo-sanguigno-sorgente.git 2>nul
if errorlevel 1 (
    git remote add origin https://github.com/albertobianchi473-tech/dieta-gruppo-sanguigno-sorgente.git
)

git push -u origin main --force
echo.

echo ============================================
echo   BACKUP COMPLETATO CON SUCCESSO!
echo   Il tuo codice e' al sicuro su GitHub.
echo ============================================
pause