-- =============================================
-- PROJETO SQL CLÍNICA  |  SQL Server 2019+
-- Arquivo: 14_triggers_auditoria.sql
-- Descrição: Auditoria JSON + proteção de dados
-- =============================================
USE clinica_db;
GO

-- Tabela de log centralizada
CREATE TABLE auditoria_log (
    log_id        BIGINT IDENTITY(1,1) PRIMARY KEY,
    tabela        VARCHAR(50)    NOT NULL,
    operacao      CHAR(6)        NOT NULL CHECK (operacao IN ('INSERT','UPDATE','DELETE')),
    registro_id   INT            NOT NULL,
    dado_anterior NVARCHAR(MAX),            -- JSON do estado anterior
    dado_novo     NVARCHAR(MAX),            -- JSON do novo estado
    usuario       VARCHAR(100)   DEFAULT SYSTEM_USER,
    host          VARCHAR(100)   DEFAULT HOST_NAME(),
    dt_operacao   DATETIME2      DEFAULT SYSDATETIME()
);
GO

-- ──────────────────────────────────────────
-- Trigger: auditoria completa em consultas
-- ──────────────────────────────────────────
CREATE OR ALTER TRIGGER trg_auditoria_consulta
ON consulta AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO auditoria_log (tabela, operacao, registro_id, dado_novo)
        SELECT 'consulta', 'INSERT', i.consulta_id,
            (SELECT i.consulta_id, i.paciente_id, i.medico_id,
                    i.dt_consulta, i.status, i.valor_cobrado
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
        FROM inserted i;
    END

    -- UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO auditoria_log (tabela, operacao, registro_id, dado_anterior, dado_novo)
        SELECT 'consulta', 'UPDATE', i.consulta_id,
            (SELECT d.consulta_id, d.paciente_id, d.medico_id,
                    d.dt_consulta, d.status, d.valor_cobrado
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            (SELECT i.consulta_id, i.paciente_id, i.medico_id,
                    i.dt_consulta, i.status, i.valor_cobrado
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
        FROM inserted i JOIN deleted d ON d.consulta_id = i.consulta_id;
    END

    -- DELETE
    IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO auditoria_log (tabela, operacao, registro_id, dado_anterior)
        SELECT 'consulta', 'DELETE', d.consulta_id,
            (SELECT d.consulta_id, d.paciente_id, d.medico_id,
                    d.dt_consulta, d.status, d.valor_cobrado
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
        FROM deleted d;
    END
END;
GO

-- ──────────────────────────────────────────
-- Trigger: protege exclusão de realizadas
-- ──────────────────────────────────────────
CREATE OR ALTER TRIGGER trg_protege_consulta_realizada
ON consulta INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM deleted WHERE status = 'realizada')
    BEGIN
        RAISERROR(
            'Consultas realizadas não podem ser excluídas. Use cancelamento ou inativação.',
            16, 1
        );
        RETURN;
    END

    DELETE c FROM consulta c JOIN deleted d ON d.consulta_id = c.consulta_id;
END;
GO

-- ──────────────────────────────────────────
-- Trigger: auditoria de alterações em pacientes
-- ──────────────────────────────────────────
CREATE OR ALTER TRIGGER trg_auditoria_paciente
ON paciente AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO auditoria_log (tabela, operacao, registro_id, dado_anterior, dado_novo)
    SELECT 'paciente', 'UPDATE', i.paciente_id,
        (SELECT d.paciente_id, d.nome, d.cpf, d.plano_id
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.paciente_id, i.nome, i.cpf, i.plano_id
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i JOIN deleted d ON d.paciente_id = i.paciente_id;
END;
GO

/*
========================================
Consultas úteis no log de auditoria:
========================================

-- Últimas 50 operações
SELECT TOP 50 * FROM auditoria_log ORDER BY dt_operacao DESC;

-- Todas as alterações em consultas hoje
SELECT * FROM auditoria_log
WHERE tabela = 'consulta' AND CAST(dt_operacao AS DATE) = CAST(GETDATE() AS DATE);

-- Histórico de um paciente específico
SELECT * FROM auditoria_log
WHERE tabela = 'paciente' AND registro_id = 1
ORDER BY dt_operacao;

-- Deletions (sempre suspeitas)
SELECT * FROM auditoria_log WHERE operacao = 'DELETE';
*/
