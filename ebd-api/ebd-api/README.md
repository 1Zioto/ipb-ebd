# EBD API — Backend (Laravel 13)

Backend do Sistema de Gestão da Escola Bíblica Dominical. API REST, autenticação por token (Sanctum), autorização por papéis/permissões (RBAC) validada no servidor. PostgreSQL.

## Fase 1 (esta entrega)
- Autenticação usuário/senha (Sanctum), hash bcrypt.
- Pessoas (CRUD, idade calculada, aniversariantes hoje/semana, soft delete/inativação).
- Papéis e permissões (RBAC): Programador, Pastor, Superintendência, Professor.
- Autorização no backend (middleware `permission:` + Policies + `Gate::before` para Programador).
- Auditoria de ações (`audit_logs`).
- Schema completo (17 tabelas) já migrado — pronto para as próximas fases (classes, escalas, chamada, relatórios).

## Requisitos
- PHP 8.2+ · Composer · PostgreSQL 14+

## Instalação
```bash
composer install
cp .env.example .env        # (o .env já vem configurado para o Neon)
php artisan key:generate
```

## Banco de dados
O banco Neon **já foi provisionado** (17 tabelas + seed) nesta sessão. Duas opções:

1. **Usar como está** (recomendado): não rode `migrate` — as tabelas já existem. Apenas conecte.
2. **Recriar do zero** (dev): `php artisan migrate:fresh --seed` recria tudo e semeia papéis/permissões/admin.

> As migrations reproduzem exatamente o `schema.sql` entregue. Escolha uma das duas fontes (SQL aplicado OU migrations), não as duas na mesma base.

Config de conexão fica no `.env` (`DB_*`). A porta padrão do Postgres é 5432 — funciona na sua infraestrutura.

## Rodando
```bash
php artisan serve
```

## Usuário inicial
- usuário: `admin`  ·  senha: `EbdAdmin@2026` (defina `ADMIN_PASSWORD` no `.env` antes de semear para mudar) — **troque após o primeiro acesso**.

## Endpoints (v1)
| Método | Rota | Permissão | Descrição |
|---|---|---|---|
| POST | `/api/v1/auth/login` | pública | login → token |
| GET | `/api/v1/auth/me` | autenticado | usuário + papéis + permissões |
| POST | `/api/v1/auth/logout` | autenticado | encerra token |
| GET | `/api/v1/people` | person.view | lista (filtros: search, is_active, can_teach) |
| GET | `/api/v1/people/birthdays?scope=today\|week` | person.view | aniversariantes |
| GET | `/api/v1/people/{id}` | person.view | detalhe |
| POST | `/api/v1/people` | person.manage | criar |
| PUT/PATCH | `/api/v1/people/{id}` | person.manage | atualizar |
| DELETE | `/api/v1/people/{id}` | person.manage | inativar (soft delete) |

Autenticação: header `Authorization: Bearer <token>`.

## Estrutura (camadas)
- `app/Http/Controllers/Api` — controllers finos.
- `app/Http/Requests` — validação de entrada.
- `app/Http/Resources` — serialização JSON.
- `app/Policies` + `app/Http/Middleware/EnsurePermission` — autorização.
- `app/Support/Permissions.php` — catálogo central de permissões e matriz de papéis.
- `app/Support/Audit.php` — trilha de auditoria.
- `app/Models` — Eloquent (Person, User, Role, Permission, ClassRoom, ClassStudent, ClassTeacher, EbdEvent, AttendanceSession, AttendanceRecord, TeacherSchedule, SuperintendentSchedule, AuditLog, Setting, Announcement).

## Próximas fases
Fase 2 classes/vínculos · Fase 3 calendário (geração idempotente) · Fase 4 escalas · Fase 5 chamada · Fase 6 dashboard/painel · Fase 7 relatórios · Fase 8 auditoria avançada. Ver `EBD_Arquitetura_e_Plano.md`.
