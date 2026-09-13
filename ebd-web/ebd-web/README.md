# EBD Web — Frontend (Angular 21)

SPA do Sistema de Gestão da EBD. Uma base de código com **duas experiências**:
desktop (sidebar) e mobile (barra inferior, botões grandes), detectadas por viewport.
Consome a API Laravel (Sanctum, token Bearer).

## Fase 1 (esta entrega)
- Login usuário/senha (token guardado no navegador).
- Interceptor HTTP (Bearer + tratamento de 401 → volta ao login).
- Guards de rota (autenticação + permissão), espelhando o RBAC do backend.
- Shell responsivo: sidebar no desktop, bottom-nav no mobile.
- Tela de Pessoas: listar, buscar, criar, editar, inativar — com idade calculada e
  respeito às permissões (botões de gestão só aparecem com `person.manage`).

> Zoneless (Angular 21, sem zone.js). Reatividade via **signals**.

## Requisitos
- Node 20+ · npm

## Instalação e execução
```bash
npm install
npm start          # ng serve -> http://localhost:4200
```

## Configuração da API
Edite `src/environments/environment.ts`:
```ts
apiUrl: 'http://localhost:8000/api/v1'   // URL da sua API Laravel
```
Em produção: `src/environments/environment.prod.ts` (padrão `/api/v1`).

## Build
```bash
npm run build      # saída em dist/ebd-web/browser
```

## Estrutura
- `src/app/core/` — auth.service, people.service, auth.interceptor, auth.guard, responsive.service, models.
- `src/app/layout/shell` — casca responsiva (sidebar desktop / bottom-nav mobile).
- `src/app/pages/login` — tela de login.
- `src/app/pages/people` — lista + modal de criação/edição.
- `src/app/app.routes.ts` — rotas com lazy loading e guards.

## Login inicial
usuário `admin` · senha `EbdAdmin@2026` (troque no backend após o primeiro acesso).

## Próximas fases (telas)
Dashboard, painel do superintendente, chamada (foco mobile), classes, escalas, relatórios.
A casca já está pronta para receber novos itens de menu por permissão (basta adicionar em `layout/shell.ts`).
