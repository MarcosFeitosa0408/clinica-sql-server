-- =============================================
-- PROJETO SQL CLÍNICA  |  SQL Server 2019+
-- Arquivo: 08_ranking_medicos.sql
-- Técnicas: PERCENT_RANK, NTILE, CTEs encadeadas
-- =============================================
USE clinica_db;
GO

WITH metricas AS (
    SELECT
        m.medico_id, m.nome AS medico, e.nome AS especialidade,
        DATEDIFF(YEAR, m.data_admissao, GETDATE()) AS anos_casa,
        COUNT(c.consulta_id)                            AS total_consultas,
        SUM(CASE WHEN c.status='realizada' THEN 1 ELSE 0 END) AS consultas_realizadas,
        SUM(CASE WHEN c.status='faltou'    THEN 1 ELSE 0 END) AS faltas,
        ISNULL(SUM(c.valor_cobrado),0)                  AS receita_total,
        COUNT(DISTINCT c.paciente_id)                   AS pacientes_unicos,
        COUNT(p.prescricao_id)                          AS total_prescricoes
    FROM medico m
    JOIN especialidade e ON e.especialidade_id = m.especialidade_id
    LEFT JOIN consulta   c ON c.medico_id    = m.medico_id
                           AND c.dt_consulta >= DATEADD(YEAR,-1,GETDATE())
    LEFT JOIN prescricao p ON p.consulta_id  = c.consulta_id
    WHERE m.ativo = 1
    GROUP BY m.medico_id, m.nome, e.nome, m.data_admissao
),
com_scores AS (
    SELECT *,
        ROUND(100.0*consultas_realizadas/NULLIF(total_consultas,0),2) AS taxa_comparecimento,
        ROUND(100*PERCENT_RANK() OVER (PARTITION BY especialidade ORDER BY receita_total),1)          AS percentil_receita,
        NTILE(4) OVER (PARTITION BY especialidade ORDER BY consultas_realizadas DESC) AS quartil
    FROM metricas
)
SELECT
    medico, especialidade, anos_casa,
    total_consultas, consultas_realizadas, faltas,
    FORMAT(receita_total,'N2') AS receita_RS,
    pacientes_unicos, total_prescricoes,
    taxa_comparecimento AS taxa_comparecimento_pct,
    percentil_receita, quartil,
    CASE quartil
        WHEN 1 THEN 'Top 25% — Excelente'
        WHEN 2 THEN 'Acima da média'
        WHEN 3 THEN 'Abaixo da média'
        WHEN 4 THEN 'Atenção necessária'
    END AS classificacao
FROM com_scores
ORDER BY especialidade, percentil_receita DESC;
