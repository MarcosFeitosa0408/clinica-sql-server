-- =============================================
-- PROJETO SQL CLÍNICA  |  SQL Server 2019+
-- Arquivo: 03_indexes.sql
-- Descrição: Índices de performance e Columnstore
-- =============================================
USE clinica_db;
GO

-- Filtro principal: período + status (usado na maioria das queries)
CREATE INDEX IX_consulta_dt_status
    ON consulta (dt_consulta, status)
    INCLUDE (medico_id, paciente_id, valor_cobrado);

-- JOIN médico + data para relatórios de ocupação
CREATE INDEX IX_consulta_medico_dt
    ON consulta (medico_id, dt_consulta)
    INCLUDE (status, valor_cobrado, paciente_id);

-- Índice filtrado: apenas consultas realizadas
CREATE INDEX IX_consulta_realizada
    ON consulta (paciente_id, dt_consulta)
    INCLUDE (medico_id, valor_cobrado)
    WHERE status = 'realizada';

-- Lookup rápido de paciente por CPF
CREATE UNIQUE INDEX UIX_paciente_cpf
    ON paciente (cpf)
    INCLUDE (nome, plano_id, data_nasc);

-- JOIN prescrição → consulta → medicamento
CREATE INDEX IX_prescricao_consulta_med
    ON prescricao (consulta_id, med_id)
    INCLUDE (dosagem, duracao_dias);

-- Columnstore para GROUP BY e agregações analíticas pesadas
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCS_consulta_analitico
    ON consulta (paciente_id, medico_id, dt_consulta, status, valor_cobrado);

-- Manter estatísticas atualizadas
UPDATE STATISTICS consulta   WITH FULLSCAN;
UPDATE STATISTICS prescricao WITH FULLSCAN;
GO
