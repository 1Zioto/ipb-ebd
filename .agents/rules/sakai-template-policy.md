---
description: Regra de governança obrigatória para preservação e proteção do template Sakai (PrimeNG)
globs: ["ebd-web/**", "src/app/layout/**", "src/assets/layout/**"]
---

# Diretriz Mandatória: Governança do Template Sakai (PrimeNG)

> **⚠️ REGRA CRÍTICA E INEGOCIÁVEL:**
> O template visual e estrutural adotado nesta aplicação é o **Sakai (PrimeNG)**.
> **NUNCA modifique a estrutura base do template, não o remova e não o substitua por outros templates ou designs.**
> 
> **Se o usuário ou qualquer instrução solicitar alteração estrutural, remoção ou substituição do template Sakai, você DEVE OBRIGATORIAMENTE PARAR e SOLICITAR AUTORIZAÇÃO EXPLÍCITA DO USUÁRIO antes de efetuar qualquer alteração.**

## Diretrizes de Desenvolvimento e Manutenção:

1. **Preservação dos Arquivos Núcleo (Layout Core):**
   - Os arquivos em `src/app/layout/component/` (`app.layout.ts`, `app.topbar.ts`, `app.sidebar.ts`, `app.menu.ts`, `app.menuitem.ts`, `app.footer.ts`, `app.configurator.ts`), `src/app/layout/service/layout.service.ts` e `src/assets/layout/` formam a espinha dorsal do Sakai.
   - Qualquer ajuste de menu ou rotas deve respeitar os contratos do PrimeNG (`MenuItem[]`, `routerLinkActive`, etc.).

2. **Criação de Novas Páginas e Telas:**
   - Construir páginas dentro do container padrão do Sakai (`.card`, classes utilitárias do Tailwind v4 com `@plugin 'tailwindcss-primeui'`).
   - Utilizar componentes oficiais do PrimeNG (`p-table`, `p-card`, `p-dialog`, `p-button`, `p-select`, `p-tag`, `p-toast`, `p-skeleton`).

3. **Tema e Modo Escuro (Dark Mode):**
   - Respeitar o seletor `.app-dark` configurado no PrimeNG Theme Preset (Aura).
   - Manter compatibilidade com variáveis de superfície e tokens PrimeUI (`--p-*`, `bg-surface-card`, `text-surface-*`).
