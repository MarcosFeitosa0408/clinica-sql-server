-- =============================================
-- PROJETO SQL CLÍNICA  |  SQL Server 2019+
-- Arquivo: 05_ocupacao_agenda.sql
-- Técnicas: CTE, RANK, AVG OVER (média móvel)
-- =============================================
USE clinica_db;
GO

WITH base AS (
    SELECT
        m.nome                                          AS medico,
        e.nome                                          AS especialidade,
        FORMAT(c.dt_consulta, 'yyyy-MM')               AS mes_ano,
        COUNT(*)                                        AS total_consultas,
        SUM(CASE WHEN c.status = 'realizada'  THEN 1 ELSE 0 END) AS realizadas,
        SUM(CASE WHEN c.status = 'faltou'     THEN 1 ELSE 0 END) AS faltas,
        SUM(CASE WHEN c.status = 'cancelada'  THEN 1 ELSE 0 END) AS canceladas
    FROM consulta c
    INNER JOIN medico        m ON m.medico_id      = c.medico_id
    INNER JOIN especialidade e ON e.especialidade_id = m.especialidade_id
    WHERE c.dt_consulta >= DATEADD(MONTH, -12, GETDATE())
    GROUP BY m.nome, e.nome, FORMAT(c.dt_consulta, 'yyyy-MM')
),
com_taxas AS (
    SELECT *,
        ROUND(100.0 * realizadas / NULLIF(total_consultas, 0), 2) AS taxa_comparecimento_pct,
        ROUND(100.0 * faltas     / NULLIF(total_consultas, 0), 2) AS taxa_absenteismo_pct
    FROM base
)
SELECT
    medico, especialidade, mes_ano,
    total_consultas, realizadas, faltas, canceladas,
    taxa_comparecimento_pct,
    taxa_absenteismo_pct,
    -- Média móvel de 3 meses (absenteísmo)
    ROUND(AVG(taxa_absenteismo_pct) OVER (
        PARTITION BY medico
        ORDER BY mes_ano
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS media_movel_absenteismo_3m,
    -- Ranking de ocupação no mês entre médicos da mesma especialidade
    RANK() OVER (
        PARTITION BY especialidade, mes_ano
        ORDER BY taxa_comparecimento_pct DESC
    ) AS rank_comparecimento
FROM com_taxas
ORDER BY medico, mes_ano;
