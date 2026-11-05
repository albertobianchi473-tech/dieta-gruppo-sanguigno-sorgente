@echo off
setlocal enabledelayedexpansion
color 0B

echo ============================================
echo   PULIZIA GIT E BACKUP SU GITHUB (Flutter)
echo ============================================
echo.

REM 1. Verifica se siamo in una repo Git
git rev-parse --is-inside-work-tree >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERRORE] Questa cartella non e un repository Git!
    echo Esegui questo script nella cartella principale del progetto.
    pause
    exit /b 1
)

echo [1/5] Verifica e aggiornamento del file .gitignore...
if not exist .gitignore (
    echo build/ >> .gitignore
    echo .dart_tool/ >> .gitignore
    echo .flutter-plugins >> .gitignore
    echo .flutter-plugins-dependencies >> .gitignore
    echo *.log >> .gitignore
) else (
    findstr /C:"build/" .gitignore >nul || echo build/ >> .gitignore
    findstr /C:".dart_tool/" .gitignore >nul || echo .dart_tool/ >> .gitignore
)
echo        - Fatto.

echo [2/5] Rimozione delle cartelle pesanti dalla memoria di Git...
echo        (I file rimarranno sul tuo PC, verranno solo "dimenticati" da Git)
git rm -r --cached build/ >nul 2>&1
git rm -r --cached .dart_tool/ >nul 2>&1
echo        - Fatto.

echo [3/5] Preparazione dei file per il commit...
git add .gitignore
git add .
echo        - Fatto.

echo [4/5] Creazione del commit di pulizia...
git commit -m "Fix: rimossi file di build pesanti e aggiornato .gitignore"
echo        - Fatto.

echo [5/5] Caricamento su GitHub in corso...
echo        (Potrebbe richiedere alcuni minuti, attendi...)
echo.

git push origin main

REM 6. Controllo REALE dell'esito del comando git push
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo   BACKUP COMPLETATO CON SUCCESSO! 
    echo ============================================
) else (
    echo.
    echo ============================================
    echo   ATTENZIONE: CARICAMENTO FALLITO!
    echo   Leggi gli errori qui sopra.
    echo   Se vedi ancora "Large files detected", significa che i file 
    echo   pesanti sono in un commit VECCHIO, non nell'ultimo.
    echo ============================================
)

echo.
pause