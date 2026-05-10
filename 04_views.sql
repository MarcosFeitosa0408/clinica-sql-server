-- =============================================
-- PROJETO SQL CLÍNICA  |  SQL Server 2019+
-- Arquivo: 04_views.sql
-- Descrição: 5 views analíticas encapsuladas
-- =============================================
USE clinica_db;
GO

-- 1. Join central reutilizável por todas as queries
CREATE OR ALTER VIEW vw_consultas_completas AS
SELECT
    c.consulta_id, c.dt_consulta, c.status, c.valor_cobrado,
    p.paciente_id, p.nome AS paciente, p.cpf,
    DATEDIFF(YEAR, p.data_nasc, GETDATE()) AS idade_paciente, p.sexo,
    ps.nome AS plano, ps.tipo AS tipo_plano, ps.cobertura_pct,
    ROUND(c.valor_cobrado * ps.cobertura_pct/100, 2)       AS valor_coberto,
    ROUND(c.valor_cobrado * (1 - ps.cobertura_pct/100), 2) AS copagamento,
    m.medico_id, m.nome AS medico, m.crm,
    e.nome AS especialidade, e.valor_consulta_base,
    FORMAT(c.dt_consulta, 'yyyy-MM') AS mes_ano,
    YEAR(c.dt_consulta)  AS ano,
    MONTH(c.dt_consulta) AS mes,
    DATENAME(WEEKDAY, c.dt_consulta) AS dia_semana
FROM consulta c
JOIN paciente       p  ON p.paciente_id     = c.paciente_id
JOIN medico         m  ON m.medico_id       = c.medico_id
JOIN especialidade  e  ON e.especialidade_id = m.especialidade_id
LEFT JOIN plano_saude ps ON ps.plano_id     = p.plano_id;
GO

-- 2. Faturamento agregado por mês e plano
CREATE OR ALTER VIEW vw_faturamento_mensal AS
SELECT
    mes_ano, ano, mes, plano, tipo_plano, cobertura_pct,
    COUNT(*)           AS consultas,
    SUM(valor_cobrado) AS receita_bruta,
    SUM(valor_coberto) AS coberto_plano,
    SUM(copagamento)   AS copagamento_total
FROM vw_consultas_completas
WHERE status = 'realizada'
GROUP BY mes_ano, ano, mes, plano, tipo_plano, cobertura_pct;
GO

-- 3. Performance de médicos (últimos 12 meses)
CREATE OR ALTER VIEW vw_medicos_performance AS
SELECT
    medico_id, medico, crm, especialidade,
    COUNT(*) AS total_agendadas,
    SUM(CASE WHEN status='realizada' THEN 1 ELSE 0 END) AS realizadas,
    SUM(CASE WHEN status='faltou'    THEN 1 ELSE 0 END) AS faltas,
    SUM(CASE WHEN status='cancelada' THEN 1 ELSE 0 END) AS canceladas,
    ROUND(100.0*SUM(CASE WHEN status='realizada' THEN 1 ELSE 0 END)
          /NULLIF(COUNT(*),0),2) AS taxa_comparecimento_pct,
    ISNULL(SUM(valor_cobrado),0) AS receita_total,
    COUNT(DISTINCT paciente_id)  AS pacientes_unicos
FROM vw_consultas_completas
WHERE dt_consulta >= DATEADD(YEAR,-1,GETDATE())
GROUP BY medico_id, medico, crm, especialidade;
GO

-- 4. Sinistralidade por plano
CREATE OR ALTER VIEW vw_sinistralidade_plano AS
SELECT
    plano, tipo_plano, cobertura_pct, mes_ano,
    receita_bruta,
    coberto_plano AS sinistro_total,
    ROUND(100.0*coberto_plano/NULLIF(receita_bruta,0),2) AS sinistralidade_pct
FROM vw_faturamento_mensal;
GO

-- 5. Medicamentos mais prescritos (últimos 6 meses)
CREATE OR ALTER VIEW vw_prescricoes_resumo AS
SELECT
    med.nome_generico, med.classe,
    CASE WHEN med.controlado=1 THEN 'Controlado' ELSE 'Livre' END AS tipo,
    esp.nome AS especialidade,
    COUNT(p.prescricao_id)        AS total_prescricoes,
    COUNT(DISTINCT c.paciente_id) AS pacientes_distintos
FROM prescricao    p
JOIN consulta      c   ON c.consulta_id      = p.consulta_id
JOIN medicamento   med ON med.med_id         = p.med_id
JOIN medico        m   ON m.medico_id        = c.medico_id
JOIN especialidade esp ON esp.especialidade_id = m.especialidade_id
WHERE c.dt_consulta >= DATEADD(MONTH,-6,GETDATE())
  AND c.status = 'realizada'
GROUP BY med.nome_generico, med.classe, med.controlado, esp.nome;
GO
