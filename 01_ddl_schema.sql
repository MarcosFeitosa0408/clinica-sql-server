-- =============================================
-- PROJETO SQL CLÍNICA  |  SQL Server 2019+
-- Arquivo: 01_ddl_schema.sql
-- Descrição: Criação do banco e das 9 tabelas
-- =============================================

CREATE DATABASE clinica_db;
GO
USE clinica_db;
GO

-- ──────────────────────────────────────────
-- 1. Planos de Saúde
-- ──────────────────────────────────────────
CREATE TABLE plano_saude (
    plano_id      INT IDENTITY(1,1) PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    tipo          VARCHAR(30)  NOT NULL   -- 'basico','intermediario','premium'
                  CHECK (tipo IN ('basico','intermediario','premium')),
    cobertura_pct DECIMAL(5,2) NOT NULL
                  CHECK (cobertura_pct BETWEEN 0 AND 100),
    ativo         BIT          DEFAULT 1
);

-- ──────────────────────────────────────────
-- 2. Especialidades médicas
-- ──────────────────────────────────────────
CREATE TABLE especialidade (
    especialidade_id    INT IDENTITY(1,1) PRIMARY KEY,
    nome                VARCHAR(80)    NOT NULL UNIQUE,
    valor_consulta_base DECIMAL(10,2)  NOT NULL
);

-- ──────────────────────────────────────────
-- 3. Médicos
-- ──────────────────────────────────────────
CREATE TABLE medico (
    medico_id        INT IDENTITY(1,1) PRIMARY KEY,
    nome             VARCHAR(120) NOT NULL,
    crm              VARCHAR(20)  NOT NULL UNIQUE,
    especialidade_id INT          NOT NULL REFERENCES especialidade(especialidade_id),
    data_admissao    DATE         NOT NULL,
    ativo            BIT          DEFAULT 1
);

-- ──────────────────────────────────────────
-- 4. Pacientes
-- ──────────────────────────────────────────
CREATE TABLE paciente (
    paciente_id   INT IDENTITY(1,1) PRIMARY KEY,
    nome          VARCHAR(120) NOT NULL,
    cpf           CHAR(11)     NOT NULL UNIQUE,
    data_nasc     DATE         NOT NULL,
    sexo          CHAR(1)      CHECK (sexo IN ('M','F','O')),
    plano_id      INT          REFERENCES plano_saude(plano_id),
    data_cadastro DATE         DEFAULT CAST(GETDATE() AS DATE)
);

-- ──────────────────────────────────────────
-- 5. Consultas
-- ──────────────────────────────────────────
CREATE TABLE consulta (
    consulta_id   INT IDENTITY(1,1) PRIMARY KEY,
    paciente_id   INT            NOT NULL REFERENCES paciente(paciente_id),
    medico_id     INT            NOT NULL REFERENCES medico(medico_id),
    dt_consulta   DATETIME2      NOT NULL,
    status        VARCHAR(20)    NOT NULL
                  CHECK (status IN ('agendada','realizada','cancelada','faltou')),
    valor_cobrado DECIMAL(10,2),
    observacoes   NVARCHAR(500)
);

-- ──────────────────────────────────────────
-- 6. Medicamentos
-- ──────────────────────────────────────────
CREATE TABLE medicamento (
    med_id        INT IDENTITY(1,1) PRIMARY KEY,
    nome_generico VARCHAR(100) NOT NULL,
    classe        VARCHAR(60),
    controlado    BIT          DEFAULT 0
);

-- ──────────────────────────────────────────
-- 7. Prescrições
-- ──────────────────────────────────────────
CREATE TABLE prescricao (
    prescricao_id INT IDENTITY(1,1) PRIMARY KEY,
    consulta_id   INT NOT NULL REFERENCES consulta(consulta_id),
    med_id        INT NOT NULL REFERENCES medicamento(med_id),
    dosagem       VARCHAR(50),
    duracao_dias  INT,
    instrucoes    VARCHAR(200)
);

-- ──────────────────────────────────────────
-- 8. Tipos de Exame
-- ──────────────────────────────────────────
CREATE TABLE tipo_exame (
    tipo_exame_id INT IDENTITY(1,1) PRIMARY KEY,
    nome          VARCHAR(80)   NOT NULL,
    valor_base    DECIMAL(10,2) NOT NULL
);

-- ──────────────────────────────────────────
-- 9. Exames solicitados
-- ──────────────────────────────────────────
CREATE TABLE exame (
    exame_id      INT IDENTITY(1,1) PRIMARY KEY,
    consulta_id   INT           NOT NULL REFERENCES consulta(consulta_id),
    tipo_exame_id INT           NOT NULL REFERENCES tipo_exame(tipo_exame_id),
    dt_realizacao DATE,
    resultado     NVARCHAR(1000),
    status        VARCHAR(20)   DEFAULT 'pendente'
                  CHECK (status IN ('pendente','realizado','cancelado'))
);
GO
