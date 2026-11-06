# ==============================================================================
# Script de Execução de Testes de Carga (1.000 Usuários) - CONCÍLIA IPB
# ==============================================================================
# Este script inicia o servidor Laravel localmente (se necessário) e executa
# a suite k6 de alta performance sem gerar custos no banco de dados Neon/Vercel.
# ==============================================================================

param (
    [string]$TargetUrl = "http://127.0.0.1:8000/api/v1",
    [switch]$StartLocalServer
)

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " CONCÍLIA IPB — Teste de Carga e Estresse Local (1.000 Usuários)" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Destino do Teste: $TargetUrl" -ForegroundColor Yellow

# Verificar se o k6 está instalado
$k6Installed = Get-Command k6 -ErrorAction SilentlyContinue
if (-not $k6Installed) {
    Write-Host "[AVISO] k6 não foi detectado no PATH do Windows." -ForegroundColor Yellow
    Write-Host "Para instalar o k6 no Windows, execute: choco install k6 ou winget install k6" -ForegroundColor Gray
    Write-Host "Você também pode baixar o executável oficial em https://k6.io/docs/get-started/installation/" -ForegroundColor Gray
    exit 1
}

# Executar a bateria k6
$scriptPath = Join-Path $PSScriptRoot "k6-concilia-1000-users.js"
Write-Host "Iniciando simulação de 1.000 usuários ativos..." -ForegroundColor Green
k6 run --env TARGET_URL=$TargetUrl $scriptPath
