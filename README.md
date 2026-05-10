# 🏥 Clínica SQL Server — Projeto Analítico Profissional

![SQL Server](https://img.shields.io/badge/SQL%20Server-2019%2B-CC2927?style=flat-square&logo=microsoftsqlserver&logoColor=white)
![Status](https://img.shields.io/badge/status-completo-2ea44f?style=flat-square)
![Licença](https://img.shields.io/badge/licença-MIT-blue?style=flat-square)

Projeto completo de modelagem e análise de dados para clínicas médicas usando **SQL Server 2019+**. Abrange desde o schema relacional normalizado até queries analíticas avançadas com Window Functions, CTEs, Stored Procedures e Triggers de auditoria.

---

## 📐 Arquitetura do Banco

```
clinica_db
│
├── 📋 Cadastros
│   ├── especialidade        — especialidades médicas e valor base
│   ├── plano_saude          — planos com percentual de cobertura
│   ├── medico               — cadastro de médicos e CRM
│   └── paciente             — pacientes vinculados a planos
│
├── 🗓 Operacional
│   ├── consulta             — agendamentos e atendimentos
│   ├── tipo_exame           — catálogo de exames
│   ├── exame                — exames solicitados por consulta
│   ├── medicamento          — catálogo com flag de controlado
│   └── prescricao           — prescrições por consulta
│
└── 🔒 Auditoria
    └── auditoria_log        — log centralizado de todas as operações
```

---

## 📁 Estrutura do Repositório

```
clinica-sql-server/
│
├── README.md
├── docs/
│   └── diagrama-er.md           — Diagrama entidade-relacionamento
│
├── schema/
│   └── 01_ddl_schema.sql        — Criação das 9 tabelas
│
├── data/
│   └── 02_dml_seed.sql          — Dados iniciais de exemplo
│
├── indexes/
│   └── 03_indexes.sql           — Índices de performance e Columnstore
│
├── views/
│   └── 04_views.sql             — 5 views analíticas encapsuladas
│
├── queries/
│   ├── 05_ocupacao_agenda.sql   — Taxa de comparecimento + média móvel
│   ├── 06_prescricoes.sql       — Ranking de medicamentos + controlados
│   ├── 07_faturamento.sql       — Receita, YoY, YTD por plano
│   ├── 08_ranking_medicos.sql   — Performance com PERCENT_RANK e NTILE
│   └── 09_retencao_churn.sql    — Cohort analysis + churn risk
│
├── procedures/
│   ├── 10_usp_faturamento.sql   — Relatório de faturamento parametrizado
│   ├── 11_usp_agenda.sql        — Agenda diária do médico
│   ├── 12_usp_performance.sql   — Dashboard de performance médica
│   └── 13_usp_churn.sql         — Alerta de churn de pacientes
│
└── triggers/
    └── 14_triggers_auditoria.sql — Auditoria com JSON + proteção de dados
```

---

## 🚀 Como executar

### Pré-requisitos
- SQL Server 2019 ou superior (Developer / Express / Standard)
- SQL Server Management Studio (SSMS) ou Azure Data Studio

### Passo a passo

```bash
# 1. Clone o repositório
git clone https://github.com/seu-usuario/clinica-sql-server.git
cd clinica-sql-server

# 2. Execute os scripts na ordem numérica no SSMS:
#    schema → data → indexes → views → queries → procedures → triggers
```

Ou execute tudo de uma vez via `sqlcmd`:

```bash
sqlcmd -S localhost -E -i schema/01_ddl_schema.sql
sqlcmd -S localhost -E -d clinica_db -i data/02_dml_seed.sql
sqlcmd -S localhost -E -d clinica_db -i indexes/03_indexes.sql
sqlcmd -S localhost -E -d clinica_db -i views/04_views.sql
sqlcmd -S localhost -E -d clinica_db -i procedures/10_usp_faturamento.sql
sqlcmd -S localhost -E -d clinica_db -i procedures/11_usp_agenda.sql
sqlcmd -S localhost -E -d clinica_db -i procedures/12_usp_performance.sql
sqlcmd -S localhost -E -d clinica_db -i procedures/13_usp_churn.sql
sqlcmd -S localhost -E -d clinica_db -i triggers/14_triggers_auditoria.sql
```

---

## 📊 Queries e Técnicas Demonstradas

| Arquivo | Técnica Principal | Objetivo |
|---|---|---|
| `05_ocupacao_agenda.sql` | `ROWS BETWEEN`, `RANK()` | Taxa de absenteísmo + média móvel 3 meses |
| `06_prescricoes.sql` | `DENSE_RANK`, `PERCENT_RANK` | Top medicamentos + alertas de controlados |
| `07_faturamento.sql` | `LAG()`, `SUM OVER UNBOUNDED PRECEDING` | Crescimento YoY e acumulado YTD |
| `08_ranking_medicos.sql` | `PERCENT_RANK()`, `NTILE(4)` | Score de performance por especialidade |
| `09_retencao_churn.sql` | `LEAD()`, `MAX OVER PARTITION` | Cohort analysis + risco de churn |

---

## ⚙️ Stored Procedures

```sql
-- Faturamento por período e plano
EXEC usp_relatorio_faturamento '2024-01-01', '2024-12-31', NULL, 'MES';

-- Agenda do médico (hoje por padrão)
EXEC usp_agenda_medico @medico_id = 2;

-- Performance com ranking por especialidade
EXEC usp_performance_medicos @especialidade_id = NULL, @meses = 12;

-- Pacientes em risco de churn
EXEC usp_alerta_churn_pacientes @dias_sem_consulta = 90;
```

---

## 🔒 Auditoria

Todas as operações de INSERT, UPDATE e DELETE nas tabelas críticas são registradas na `auditoria_log` com:

- Estado anterior e novo em **JSON**
- Usuário do SQL Server (`SYSTEM_USER`)
- Host de origem (`HOST_NAME()`)
- Timestamp preciso (`SYSDATETIME()`)

Consultar o log:

```sql
SELECT TOP 50 *
FROM auditoria_log
WHERE tabela = 'consulta'
ORDER BY dt_operacao DESC;
```

---

## 🧠 Conceitos abordados

- Modelagem relacional normalizada (3FN)
- Window Functions: `RANK`, `DENSE_RANK`, `NTILE`, `PERCENT_RANK`, `LAG`, `LEAD`
- CTEs simples e encadeadas
- Índices compostos, filtrados e Columnstore
- Views reutilizáveis como camada de abstração
- Stored Procedures com validação de parâmetros e `RAISERROR`
- Triggers `AFTER` e `INSTEAD OF` com `FOR JSON PATH`
- Análise de cohort e churn (retenção de pacientes)

---

## 📄 Licença

MIT — livre para uso, estudo e adaptação.

---

> Projeto desenvolvido como portfólio de análise de dados em SQL Server aplicado ao setor de saúde.
