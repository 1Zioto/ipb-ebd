# Guia de Testes de Carga e Desempenho — CONCÍLIA IPB

Este módulo contém a suíte de testes de estresse e concorrência para validar a resiliência do **CONCÍLIA IPB** sob demanda de **1.000 usuários simultâneos ativos**, em estrita conformidade com os requisitos do Prompt Mestre.

## 1. Diretriz de Custo Zero (Ambiente Local)
Para proteger a conta contra custos adicionais no Neon DB e na Vercel, todos os testes de carga são direcionados por padrão para o servidor backend local (`http://127.0.0.1:8000`).

## 2. Metas de Desempenho (SLA)
- **Usuários Virtuais (VUs):** Rampa progressiva de 100 → 250 → 500 → 1.000 usuários ativos.
- **Latência (p95):** Abaixo de 3.000ms (3 segundos).
- **Taxa de Erro HTTP:** Inferior a 1.0% (`rate < 0.01`).
- **Isolamento Multi-Igrejas:** **Zero vazamento** entre instituições (`cross_church_leakage_detected == 0`).
- **Integridade de Dados:** Sem duplicidade corrompida em cadastros públicos e transações financeiras.

## 3. Como Executar os Testes
### Passo 1: Iniciar o backend localmente
Em um terminal, inicie a API:
```bash
cd Aplicacao/ebd-api/ebd-api
php artisan serve --port=8000
```

### Passo 2: Executar o teste k6
Em outro terminal:
```powershell
cd Aplicacao/tests/load
.\run-load-test.ps1
```
Ou diretamente:
```bash
k6 run k6-concilia-1000-users.js
```

