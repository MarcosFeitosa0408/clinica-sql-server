-- =============================================
-- PROJETO SQL CLÍNICA  |  SQL Server 2019+
-- Arquivo: 07_faturamento.sql
-- Técnicas: LAG, SUM OVER UNBOUNDED PRECEDING (YTD)
-- =============================================
USE clinica_db;
GO

WITH fat_mensal AS (
    SELECT
        YEAR(c.dt_consulta)          AS ano,
        MONTH(c.dt_consulta)         AS mes,
        FORMAT(c.dt_consulta,'yyyy-MM') AS mes_ano,
        ps.nome AS plano, ps.tipo AS tipo_plano, ps.cobertura_pct,
        COUNT(c.consulta_id)                          AS consultas_realizadas,
        SUM(c.valor_cobrado)                          AS receita_bruta,
        SUM(c.valor_cobrado * ps.cobertura_pct/100)   AS valor_coberto_plano,
        SUM(c.valor_cobrado * (1 - ps.cobertura_pct/100)) AS copagamento_paciente
    FROM consulta c
    JOIN paciente      p  ON p.paciente_id = c.paciente_id
    LEFT JOIN plano_saude ps ON ps.plano_id = p.plano_id
    WHERE c.status = 'realizada'
    GROUP BY
        YEAR(c.dt_consulta), MONTH(c.dt_consulta),
        FORMAT(c.dt_consulta,'yyyy-MM'),
        ps.nome, ps.tipo, ps.cobertura_pct
),
com_yoy AS (
    SELECT *,
        LAG(receita_bruta, 12) OVER (
            PARTITION BY plano ORDER BY ano, mes
        ) AS receita_mesmo_mes_ano_ant,
        SUM(receita_bruta) OVER (
            PARTITION BY plano, ano
            ORDER BY mes ROWS UNBOUNDED PRECEDING
        ) AS receita_ytd
    FROM fat_mensal
)
SELECT
    mes_ano, plano, tipo_plano, consultas_realizadas,
    FORMAT(receita_bruta,           'N2') AS receita_bruta_RS,
    FORMAT(valor_coberto_plano,     'N2') AS coberto_plano_RS,
    FORMAT(copagamento_paciente,    'N2') AS copagamento_RS,
    FORMAT(receita_ytd,             'N2') AS ytd_RS,
    FORMAT(receita_mesmo_mes_ano_ant,'N2') AS receita_ano_ant_RS,
    ROUND(100.0*(receita_bruta - receita_mesmo_mes_ano_ant)
               /NULLIF(receita_mesmo_mes_ano_ant,0), 2) AS crescimento_yoy_pct
FROM com_yoy
ORDER BY plano, ano, mes;
