---
description: Diretriz mandatória sobre terminologia da Igreja Presbiteriana do Brasil (IPB) - Proibição do termo "Canônico"
globs: ["**/*"]
---

# Diretriz Mandatória: Terminologia Oficial IPB (Proibição do Termo "Canônico")

> **⚠️ REGRA CRÍTICA E INEGOCIÁVEL PARA TODAS AS IAs:**
> **É EXPRESSAMENTE PROIBIDO utilizar as palavras "Canônico", "Canônica", "Canônicos", "Canônicas" ou "Direito Canônico" em qualquer lugar do sistema ou em conversas com o usuário.**
>
> Essa proibição aplica-se a:
> 1. Textos de interface de usuário (títulos, subtítulos, botões, modais, cabeçalhos de tabela, cards, tags, badges, tooltips, opções de select e mensagens).
> 2. Documentos, relatórios, atas, planilhas geradas (CSV/Excel) e relatórios em PDF.
> 3. Respostas, resumos, planos e explicações dadas pela IA ao usuário.
> 4. Comentários de código e documentação.

---

## Equivalências e Terminologia Correta da IPB:

Substitua sempre os termos proibidos pelos conceitos oficiais do **Manual Presbiteriano (Constituição e Código de Disciplina da IPB)**:

| ❌ TERMO PROIBIDO | ✅ TERMO OFICIAL IPB A UTILIZAR |
| :--- | :--- |
| *Rol Canônico* | **Rol de Membros** |
| *Status Canônico* | **Condição Eclesiástica** ou **Situação de Membresia** |
| *Composição Canônica* | **Composição da Membresia** |
| *Dados Canônicos* | **Dados Eclesiásticos** ou **Dados do Rol** |
| *Recepção Canônica* | **Recepção de Membros** |
| *Aviso Canônico* | **Diretriz Presbiteriana** ou **Aviso Pastoral** |
| *Processo Canônico* | **Processo Disciplinar** ou **Jurisdição Pastoral** |
| *Base Canônica / Catálogo Canônico* | **Base Oficial da IPB** ou **Rol Oficial da Igreja** |
| *Atributos Canônicos* | **Atributos Cadastrais e Eclesiásticos** |

---

## Observações Técnicas sobre o Banco de Dados Legado:
- Colunas internas pré-existentes de banco de dados nomeadas `canonical_status` (como na tabela `people`) podem ser mantidas no código SQL/ORM por compatibilidade reversa de migrações legadas, **porém os rótulos apresentados ao usuário ou nas APIs SEMPRE devem ser formatados como "Condição Eclesiástica", "Situação" ou "Membro Comungante / Não Comungante"**.
