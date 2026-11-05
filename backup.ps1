# ==========================================
# SCRIPT DI BACKUP AUTOMATICO SU GITHUB
# ==========================================

# 1. Ottieni data e ora attuali formattate
$dataOggi = Get-Date -Format "yyyy-MM-dd"
$oraAttuale = Get-Date -Format "HH:mm"
$nomeTag = "backup-$dataOggi"
$messaggioCommit = "Backup automatico del $dataOggi alle ore $oraAttuale"

Write-Host "Avvio procedura di backup automatico..." -ForegroundColor Cyan
Write-Host "Data: $dataOggi | Ora: $oraAttuale" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor DarkGray

# 2. Controlla se ci sono modifiche da salvare
$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "Non ci sono modifiche nuove da salvare. Il repository e' gia' aggiornato." -ForegroundColor Green
    exit 0
}

# 3. Aggiungi tutte le modifiche
Write-Host "1. Aggiunta di tutte le modifiche in corso..." -ForegroundColor Yellow
git add .

# 4. Esegui il commit con la data dinamica
Write-Host "2. Creazione del commit: $messaggioCommit" -ForegroundColor Yellow
git commit -m $messaggioCommit

# Verifica se il commit è andato a buon fine
if ($LASTEXITCODE -eq 0) {
    
    # 5. Push del codice sul branch principale
    Write-Host "3. Caricamento del codice su GitHub (origin/main)..." -ForegroundColor Yellow
    git push origin main

    # 6. Creazione del tag con la data
    Write-Host "4. Creazione del punto di ripristino (Tag): $nomeTag" -ForegroundColor Yellow
    git tag -a $nomeTag -m "Snapshot automatico del $dataOggi"

    # 7. Push del tag su GitHub
    Write-Host "5. Caricamento del Tag su GitHub..." -ForegroundColor Yellow
    git push origin $nomeTag

    Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "BACKUP COMPLETATO CON SUCCESSO!" -ForegroundColor Green
    Write-Host "Puoi verificarlo su: https://github.com/albertobianchi473-tech/dieta-app-source" -ForegroundColor Green

} else {
    Write-Host "Si e' verificato un problema durante il commit. Verifica lo stato di Git." -ForegroundColor Red
}

# Pausa finale semplice e sicura (evita errori di virgolette)
Read-Host 'Premi Invio per chiudere...'