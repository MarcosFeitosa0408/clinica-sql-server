-- =============================================
-- PROJETO SQL CLÍNICA  |  SQL Server 2019+
-- Arquivos: 10-13 — Stored Procedures
-- =============================================
USE clinica_db;
GO

-- ══════════════════════════════════════════
-- SP 1: Relatório de faturamento por período
-- ══════════════════════════════════════════
CREATE OR ALTER PROCEDURE usp_relatorio_faturamento
    @dt_inicio  DATE        = NULL,
    @dt_fim     DATE        = NULL,
    @plano_id   INT         = NULL,   -- NULL = todos os planos
    @agrupar    VARCHAR(10) = 'MES'   -- 'MES' | 'DIA' | 'ANO'
AS
BEGIN
    SET NOCOUNT ON;

    SET @dt_inicio = ISNULL(@dt_inicio, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1));
    SET @dt_fim    = ISNULL(@dt_fim,    CAST(GETDATE() AS DATE));

    IF @dt_inicio > @dt_fim
    BEGIN
        RAISERROR('Data inicial não pode ser maior que a data final.', 16, 1);
        RETURN;
    END

    WITH base AS (
        SELECT
            CASE @agrupar
                WHEN 'DIA' THEN CONVERT(VARCHAR, CAST(dt_consulta AS DATE), 23)
                WHEN 'ANO' THEN CAST(YEAR(dt_consulta) AS VARCHAR)
                ELSE mes_ano
            END AS periodo,
            plano, tipo_plano, cobertura_pct,
            valor_cobrado, valor_coberto, copagamento, paciente_id
        FROM vw_consultas_completas
        WHERE status = 'realizada'
          AND CAST(dt_consulta AS DATE) BETWEEN @dt_inicio AND @dt_fim
          AND (@plano_id IS NULL OR paciente_id IN (
                SELECT paciente_id FROM paciente WHERE plano_id = @plano_id))
    )
    SELECT
        periodo, plano, tipo_plano, cobertura_pct,
        COUNT(*)                      AS consultas,
        COUNT(DISTINCT paciente_id)   AS pacientes_unicos,
        ROUND(SUM(valor_cobrado), 2)  AS receita_bruta,
        ROUND(SUM(valor_coberto), 2)  AS coberto_plano,
        ROUND(SUM(copagamento),   2)  AS copagamento,
        ROUND(AVG(valor_cobrado), 2)  AS ticket_medio
    FROM base
    GROUP BY periodo, plano, tipo_plano, cobertura_pct
    ORDER BY periodo, receita_bruta DESC;
END;
GO

-- ══════════════════════════════════════════
-- SP 2: Agenda diária do médico
-- ══════════════════════════════════════════
CREATE OR ALTER PROCEDURE usp_agenda_medico
    @medico_id  INT,
    @data       DATE = NULL   -- NULL = hoje
AS
BEGIN
    SET NOCOUNT ON;
    SET @data = ISNULL(@data, CAST(GETDATE() AS DATE));

    IF NOT EXISTS (SELECT 1 FROM medico WHERE medico_id = @medico_id AND ativo = 1)
    BEGIN
        RAISERROR('Médico não encontrado ou inativo.', 16, 1); RETURN;
    END

    SELECT
        FORMAT(c.dt_consulta, 'HH:mm')          AS horario,
        c.consulta_id,
        p.nome                                   AS paciente,
        p.cpf,
        DATEDIFF(YEAR,p.data_nasc,GETDATE())     AS idade,
        p.sexo,
        ISNULL(ps.nome,'Particular')             AS plano,
        c.status, c.valor_cobrado, c.observacoes,
        (   SELECT COUNT(*) FROM consulta x
            WHERE x.paciente_id = c.paciente_id
              AND x.status = 'realizada'
              AND x.medico_id = @medico_id
        ) AS consultas_anteriores_medico,
        (   SELECT TOP 1 med.nome_generico
            FROM prescricao pr
            JOIN consulta    cx  ON cx.consulta_id = pr.consulta_id
            JOIN medicamento med ON med.med_id     = pr.med_id
            WHERE cx.paciente_id = c.paciente_id
            ORDER BY cx.dt_consulta DESC
        ) AS ultimo_medicamento
    FROM consulta c
    JOIN paciente      p  ON p.paciente_id = c.paciente_id
    LEFT JOIN plano_saude ps ON ps.plano_id = p.plano_id
    WHERE c.medico_id = @medico_id
      AND CAST(c.dt_consulta AS DATE) = @data
    ORDER BY c.dt_consulta;
END;
GO

-- ══════════════════════════════════════════
-- SP 3: Dashboard de performance médica
-- ══════════════════════════════════════════
CREATE OR ALTER PROCEDURE usp_performance_medicos
    @especialidade_id  INT = NULL,
    @meses             INT = 12
AS
BEGIN
    SET NOCOUNT ON;

    WITH metricas AS (
        SELECT
            medico_id, medico, crm, especialidade,
            total_agendadas, realizadas, faltas, canceladas,
            taxa_comparecimento_pct, receita_total, pacientes_unicos,
            PERCENT_RANK() OVER (PARTITION BY especialidade ORDER BY receita_total)           AS pct_receita,
            PERCENT_RANK() OVER (PARTITION BY especialidade ORDER BY realizadas)              AS pct_consultas,
            PERCENT_RANK() OVER (PARTITION BY especialidade ORDER BY taxa_comparecimento_pct) AS pct_comparecimento,
            NTILE(4)        OVER (PARTITION BY especialidade ORDER BY realizadas DESC)        AS quartil
        FROM vw_medicos_performance
        WHERE (@especialidade_id IS NULL
               OR especialidade IN (
                   SELECT nome FROM especialidade WHERE especialidade_id = @especialidade_id))
    )
    SELECT
        medico, crm, especialidade,
        total_agendadas, realizadas, faltas,
        taxa_comparecimento_pct,
        FORMAT(receita_total,'N2')         AS receita_RS,
        pacientes_unicos,
        ROUND(pct_receita*100,1)           AS percentil_receita,
        ROUND(pct_consultas*100,1)         AS percentil_consultas,
        ROUND(pct_comparecimento*100,1)    AS percentil_comparecimento,
        quartil,
        CASE quartil
            WHEN 1 THEN 'Top 25% — Excelente'
            WHEN 2 THEN 'Acima da média'
            WHEN 3 THEN 'Abaixo da média'
            WHEN 4 THEN 'Atenção necessária'
        END AS classificacao
    FROM metricas
    ORDER BY especialidade, pct_receita DESC;
END;
GO

-- ══════════════════════════════════════════
-- SP 4: Alerta de churn de pacientes
-- ══════════════════════════════════════════
CREATE OR ALTER PROCEDURE usp_alerta_churn_pacientes
    @dias_sem_consulta  INT = 90,
    @plano_id           INT = NULL,
    @especialidade_id   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    WITH ultima_visita AS (
        SELECT
            p.paciente_id, p.nome AS paciente, p.cpf,
            ISNULL(ps.nome,'Particular') AS plano, ISNULL(ps.tipo,'basico') AS tipo_plano,
            MAX(c.dt_consulta)   AS ultima_consulta,
            COUNT(c.consulta_id) AS total_consultas_historico,
            SUM(c.valor_cobrado) AS valor_total_historico,
            (   SELECT TOP 1 m2.nome
                FROM consulta c2
                JOIN medico m2 ON m2.medico_id = c2.medico_id
                WHERE c2.paciente_id = p.paciente_id AND c2.status = 'realizada'
                GROUP BY m2.nome ORDER BY COUNT(*) DESC
            ) AS medico_preferido
        FROM paciente     p
        LEFT JOIN plano_saude ps ON ps.plano_id   = p.plano_id
        LEFT JOIN consulta    c  ON c.paciente_id = p.paciente_id
                                 AND c.status = 'realizada'
        WHERE (@plano_id IS NULL OR p.plano_id = @plano_id)
        GROUP BY p.paciente_id, p.nome, p.cpf, ps.nome, ps.tipo
    )
    SELECT
        paciente, cpf, plano, tipo_plano,
        FORMAT(ultima_consulta,'dd/MM/yyyy')     AS ultima_consulta,
        DATEDIFF(DAY,ultima_consulta,GETDATE())  AS dias_inativo,
        total_consultas_historico,
        FORMAT(valor_total_historico,'N2')       AS valor_historico_RS,
        medico_preferido,
        CASE
            WHEN DATEDIFF(DAY,ultima_consulta,GETDATE()) > 180 THEN 'CRITICO — +180 dias'
            WHEN DATEDIFF(DAY,ultima_consulta,GETDATE()) > 90  THEN 'ALERTA — +90 dias'
            ELSE 'MONITORAR'
        END AS nivel_risco
    FROM ultima_visita
    WHERE DATEDIFF(DAY, ultima_consulta, GETDATE()) >= @dias_sem_consulta
       OR ultima_consulta IS NULL
    ORDER BY dias_inativo DESC;
END;
GO

/*
========================================
Exemplos de execução:
========================================

-- Faturamento
EXEC usp_relatorio_faturamento;
EXEC usp_relatorio_faturamento '2024-01-01', '2024-12-31', NULL, 'MES';
EXEC usp_relatorio_faturamento '2025-01-01', '2025-06-30', 2, 'DIA';

-- Agenda
EXEC usp_agenda_medico @medico_id = 2;
EXEC usp_agenda_medico @medico_id = 2, @data = '2025-06-01';

-- Performance
EXEC usp_performance_medicos;
EXEC usp_performance_medicos @especialidade_id = 2, @meses = 6;

-- Churn
EXEC usp_alerta_churn_pacientes;
EXEC usp_alerta_churn_pacientes @dias_sem_consulta = 60, @plano_id = 3;
*/
