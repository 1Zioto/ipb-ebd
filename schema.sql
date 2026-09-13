-- =====================================================================
-- Sistema de Gestão da EBD — Schema PostgreSQL
-- Gerado a partir do documento de arquitetura (Laravel + Angular)
-- Convenções: id bigint identity; timestamptz; soft delete (deleted_at);
-- enums via CHECK; timestamps geridos pela aplicação (Eloquent).
-- Statements separados pelo marcador de linha:  --##
-- =====================================================================

--##
-- ---------------------------------------------------------------------
-- PEOPLE (entidade central)
-- ---------------------------------------------------------------------
CREATE TABLE people (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name         VARCHAR(180) NOT NULL,
    birth_date        DATE,
    is_active         BOOLEAN NOT NULL DEFAULT TRUE,
    can_teach         BOOLEAN NOT NULL DEFAULT FALSE,
    can_superintend   BOOLEAN NOT NULL DEFAULT FALSE,
    notes             TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at        TIMESTAMPTZ
)
--##
CREATE INDEX idx_people_active     ON people (is_active) WHERE deleted_at IS NULL
--##
CREATE INDEX idx_people_can_teach  ON people (can_teach) WHERE deleted_at IS NULL
--##
CREATE INDEX idx_people_birth_mmdd ON people ((EXTRACT(MONTH FROM birth_date)), (EXTRACT(DAY FROM birth_date)))
--##
-- ---------------------------------------------------------------------
-- ROLES / PERMISSIONS (RBAC)
-- ---------------------------------------------------------------------
CREATE TABLE roles (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(80) NOT NULL,
    slug        VARCHAR(80) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
)
--##
CREATE TABLE permissions (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(120) NOT NULL,
    slug       VARCHAR(120) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
)
--##
-- ---------------------------------------------------------------------
-- USERS (credencial de acesso; opcionalmente ligada a uma pessoa)
-- ---------------------------------------------------------------------
CREATE TABLE users (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    person_id     BIGINT REFERENCES people (id) ON DELETE SET NULL,
    name          VARCHAR(180) NOT NULL,
    username      VARCHAR(80)  NOT NULL UNIQUE,
    email         VARCHAR(180) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at    TIMESTAMPTZ
)
--##
CREATE INDEX idx_users_person ON users (person_id)
--##
CREATE TABLE user_roles (
    user_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role_id BIGINT NOT NULL REFERENCES roles (id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
)
--##
CREATE TABLE role_permissions (
    role_id       BIGINT NOT NULL REFERENCES roles (id) ON DELETE CASCADE,
    permission_id BIGINT NOT NULL REFERENCES permissions (id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
)
--##
-- ---------------------------------------------------------------------
-- CLASSES e vínculos
-- ---------------------------------------------------------------------
CREATE TABLE classes (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          VARCHAR(120) NOT NULL,
    description   VARCHAR(255),
    age_range     VARCHAR(60),
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at    TIMESTAMPTZ
)
--##
CREATE INDEX idx_classes_order ON classes (display_order) WHERE deleted_at IS NULL
--##
-- Matrícula aluno<->classe com vigência (histórico preservado)
CREATE TABLE class_students (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    class_id      BIGINT NOT NULL REFERENCES classes (id),
    person_id     BIGINT NOT NULL REFERENCES people (id),
    enrolled_at   DATE NOT NULL DEFAULT CURRENT_DATE,
    unenrolled_at DATE,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
)
--##
CREATE INDEX idx_class_students_class  ON class_students (class_id)  WHERE is_active
--##
CREATE INDEX idx_class_students_person ON class_students (person_id)
--##
-- No máximo uma matrícula ATIVA por pessoa+classe (não trava histórico)
CREATE UNIQUE INDEX uq_class_student_active
    ON class_students (class_id, person_id) WHERE is_active
--##
-- Professores habilitados/vinculados a uma classe (N:N)
CREATE TABLE class_teachers (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    class_id   BIGINT NOT NULL REFERENCES classes (id),
    person_id  BIGINT NOT NULL REFERENCES people (id),
    is_active  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (class_id, person_id)
)
--##
-- ---------------------------------------------------------------------
-- CALENDÁRIO / ENCONTROS (o "dia" da EBD)
-- ---------------------------------------------------------------------
CREATE TABLE ebd_events (
    id                           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_date                   DATE NOT NULL,
    type                         VARCHAR(20) NOT NULL DEFAULT 'regular'
                                   CHECK (type IN ('regular','especial','evento','outro')),
    status                       VARCHAR(20) NOT NULL DEFAULT 'pendente'
                                   CHECK (status IN ('pendente','em_andamento','finalizada','cancelada')),
    is_auto_generated            BOOLEAN NOT NULL DEFAULT FALSE,
    superintendent_person_id     BIGINT REFERENCES people (id),
    superintendent_name_snapshot VARCHAR(180),
    notes                        TEXT,
    created_by                   BIGINT REFERENCES users (id),
    created_at                   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (event_date, type)
)
--##
CREATE INDEX idx_ebd_events_date ON ebd_events (event_date)
--##
-- ---------------------------------------------------------------------
-- CHAMADA (sessão de uma classe dentro de um encontro)
-- ---------------------------------------------------------------------
CREATE TABLE attendance_sessions (
    id                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ebd_event_id          BIGINT NOT NULL REFERENCES ebd_events (id) ON DELETE CASCADE,
    class_id              BIGINT NOT NULL REFERENCES classes (id),
    status                VARCHAR(20) NOT NULL DEFAULT 'pendente'
                            CHECK (status IN ('pendente','em_andamento','finalizada',
                                              'cancelada','classe_unificada','nao_realizada','evento_especial')),
    status_reason         VARCHAR(255),
    teacher_person_id     BIGINT REFERENCES people (id),
    teacher_name_snapshot VARCHAR(180),
    class_name_snapshot   VARCHAR(120),
    material_mode         VARCHAR(12) NOT NULL DEFAULT 'individual'
                            CHECK (material_mode IN ('individual','agregado')),
    bibles_total          INTEGER CHECK (bibles_total   IS NULL OR bibles_total   >= 0),
    magazines_total       INTEGER CHECK (magazines_total IS NULL OR magazines_total >= 0),
    merged_into_class_id  BIGINT REFERENCES classes (id),
    created_by            BIGINT REFERENCES users (id),
    finalized_by          BIGINT REFERENCES users (id),
    finalized_at          TIMESTAMPTZ,
    updated_by            BIGINT REFERENCES users (id),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (ebd_event_id, class_id)
)
--##
CREATE INDEX idx_sessions_event ON attendance_sessions (ebd_event_id)
--##
CREATE INDEX idx_sessions_class ON attendance_sessions (class_id)
--##
-- Presença por aluno (com snapshot de nome)
CREATE TABLE attendance_records (
    id                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    attendance_session_id BIGINT NOT NULL REFERENCES attendance_sessions (id) ON DELETE CASCADE,
    person_id             BIGINT NOT NULL REFERENCES people (id),
    person_name_snapshot  VARCHAR(180) NOT NULL,
    present               BOOLEAN NOT NULL DEFAULT FALSE,
    brought_bible         BOOLEAN,
    brought_magazine      BOOLEAN,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (attendance_session_id, person_id)
)
--##
CREATE INDEX idx_records_person ON attendance_records (person_id)
--##
-- ---------------------------------------------------------------------
-- ESCALAS (previsão)
-- ---------------------------------------------------------------------
CREATE TABLE teacher_schedules (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ebd_event_id       BIGINT NOT NULL REFERENCES ebd_events (id) ON DELETE CASCADE,
    class_id           BIGINT NOT NULL REFERENCES classes (id),
    scheduled_person_id BIGINT NOT NULL REFERENCES people (id),
    notes              VARCHAR(255),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (ebd_event_id, class_id)
)
--##
CREATE TABLE superintendent_schedules (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ebd_event_id       BIGINT NOT NULL REFERENCES ebd_events (id) ON DELETE CASCADE,
    scheduled_person_id BIGINT NOT NULL REFERENCES people (id),
    notes              VARCHAR(255),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (ebd_event_id)
)
--##
-- ---------------------------------------------------------------------
-- AUDITORIA / CONFIG / AVISOS
-- ---------------------------------------------------------------------
CREATE TABLE audit_logs (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT REFERENCES users (id),
    action      VARCHAR(80) NOT NULL,
    entity_type VARCHAR(80),
    entity_id   BIGINT,
    old_values  JSONB,
    new_values  JSONB,
    ip          VARCHAR(64),
    user_agent  VARCHAR(255),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
)
--##
CREATE INDEX idx_audit_entity ON audit_logs (entity_type, entity_id)
--##
CREATE INDEX idx_audit_user   ON audit_logs (user_id)
--##
CREATE INDEX idx_audit_created ON audit_logs (created_at)
--##
CREATE TABLE settings (
    key        VARCHAR(120) PRIMARY KEY,
    value      JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
)
--##
CREATE TABLE announcements (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title      VARCHAR(180) NOT NULL,
    body       TEXT,
    starts_at  DATE,
    ends_at    DATE,
    is_active  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
)
