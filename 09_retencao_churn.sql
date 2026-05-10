-- =============================================
-- PROJETO SQL CLÍNICA  |  SQL Server 2019+
-- Arquivo: 09_retencao_churn.sql
-- Técnicas: LEAD, MAX OVER PARTITION, Cohort Analysis
-- =============================================
USE clinica_db;
GO

WITH primeira_consulta AS (
    SELECT paciente_id,
        MIN(dt_consulta)           AS dt_primeira,
        FORMAT(MIN(dt_consulta),'yyyy-MM') AS cohort_mes
    FROM consulta WHERE status = 'realizada'
    GROUP BY paciente_id
),
historico AS (
    SELECT
        c.paciente_id, p.nome AS paciente, fc.cohort_mes,
        c.dt_consulta, c.status,
        DATEDIFF(MONTH, fc.dt_primeira, c.dt_consulta) AS mes_desde_inicio,
        LEAD(c.dt_consulta) OVER (PARTITION BY c.paciente_id ORDER BY c.dt_consulta) AS proxima_consulta,
        MAX(c.dt_consulta)  OVER (PARTITION BY c.paciente_id)                        AS ultima_consulta
    FROM consulta c
    JOIN paciente          p  ON p.paciente_id  = c.paciente_id
    JOIN primeira_consulta fc ON fc.paciente_id = c.paciente_id
    WHERE c.status = 'realizada'
),
retencao_cohort AS (
    SELECT cohort_mes, mes_desde_inicio,
        COUNT(DISTINCT paciente_id) AS pacientes_ativos
    FROM historico
    GROUP BY cohort_mes, mes_desde_inicio
),
churn_risk AS (
    SELECT DISTINCT
        paciente_id, paciente, cohort_mes, ultima_consulta,
        DATEDIFF(DAY, ultima_consulta, GETDATE()) AS dias_sem_consulta,
        CASE
            WHEN DATEDIFF(DAY, ultima_consulta, GETDATE()) > 180 THEN 'CRITICO — +180 dias'
            WHEN DATEDIFF(DAY, ultima_consulta, GETDATE()) > 90  THEN 'ALERTA — +90 dias'
            ELSE 'MONITORAR'
        END AS nivel_risco
    FROM historico
)
-- Tabela de cohort
SELECT 'cohort' AS tipo, cohort_mes, CAST(mes_desde_inicio AS VARCHAR) AS detalhe,
       CAST(pacientes_ativos AS VARCHAR) AS valor
FROM retencao_cohort

UNION ALL

-- Pacientes em risco
SELECT 'churn_risk', paciente, nivel_risco,
       CAST(dias_sem_consulta AS VARCHAR) + ' dias'
FROM churn_risk
WHERE nivel_risco != 'MONITORAR'
ORDER BY tipo, cohort_mes;
