-- =============================================
-- PROJETO SQL CLÍNICA  |  SQL Server 2019+
-- Arquivo: 06_prescricoes.sql
-- Técnicas: CTE, DENSE_RANK, PERCENT_RANK
-- =============================================
USE clinica_db;
GO

WITH prescricoes_base AS (
    SELECT
        med.nome_generico, med.classe, med.controlado,
        esp.nome AS especialidade, m.nome AS medico,
        YEAR(c.dt_consulta) AS ano, MONTH(c.dt_consulta) AS mes,
        COUNT(*) AS qtd_prescricoes
    FROM prescricao p
    JOIN consulta     c   ON c.consulta_id      = p.consulta_id
    JOIN medicamento  med ON med.med_id         = p.med_id
    JOIN medico       m   ON m.medico_id        = c.medico_id
    JOIN especialidade esp ON esp.especialidade_id = m.especialidade_id
    GROUP BY
        med.nome_generico, med.classe, med.controlado,
        esp.nome, m.nome, YEAR(c.dt_consulta), MONTH(c.dt_consulta)
),
ranking_med AS (
    SELECT *,
        DENSE_RANK() OVER (
            PARTITION BY especialidade, ano, mes
            ORDER BY qtd_prescricoes DESC
        ) AS rank_especialidade,
        SUM(qtd_prescricoes) OVER (
            PARTITION BY nome_generico, ano, mes
        ) AS total_geral_medicamento
    FROM prescricoes_base
)
SELECT
    nome_generico, classe,
    CASE WHEN controlado = 1 THEN 'CONTROLADO' ELSE 'Livre' END AS tipo_prescricao,
    especialidade, medico, ano, mes,
    qtd_prescricoes, total_geral_medicamento, rank_especialidade,
    ROUND(100.0 * qtd_prescricoes / NULLIF(total_geral_medicamento, 0), 2) AS pct_medico_sobre_total
FROM ranking_med
WHERE rank_especialidade <= 5
ORDER BY especialidade, mes, rank_especialidade;
