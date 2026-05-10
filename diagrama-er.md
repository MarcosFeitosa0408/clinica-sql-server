# Diagrama Entidade-Relacionamento — Clínica SQL Server

## Representação textual do modelo

```
┌─────────────────┐       ┌──────────────────┐
│  especialidade  │──────<│      medico       │
│─────────────────│       │──────────────────│
│ especialidade_id│       │ medico_id (PK)   │
│ nome            │       │ nome             │
│ valor_consulta_ │       │ crm (UNIQUE)     │
│   base          │       │ especialidade_id │
└─────────────────┘       │ data_admissao    │
                          │ ativo            │
                          └────────┬─────────┘
                                   │
                          ┌────────┴─────────┐
┌──────────────────┐      │     consulta      │      ┌─────────────────┐
│   plano_saude    │      │──────────────────│      │    paciente     │
│──────────────────│      │ consulta_id (PK) │      │─────────────────│
│ plano_id (PK)   │      │ paciente_id (FK) │──────│ paciente_id(PK) │
│ nome            │──────│ medico_id (FK)   │      │ nome            │
│ tipo            │      │ dt_consulta      │      │ cpf (UNIQUE)    │
│ cobertura_pct   │      │ status           │      │ data_nasc       │
│ ativo           │      │ valor_cobrado    │      │ sexo            │
└─────────────────┘      │ observacoes      │      │ plano_id (FK)   │
                         └──────┬───────────┘      │ data_cadastro   │
                                │                  └─────────────────┘
               ┌────────────────┼──────────────────┐
               │                │                  │
    ┌──────────┴───┐   ┌────────┴──────┐  ┌───────┴──────────┐
    │  prescricao  │   │     exame     │  │  auditoria_log   │
    │──────────────│   │───────────────│  │──────────────────│
    │ prescricao_id│   │ exame_id (PK) │  │ log_id (PK)      │
    │ consulta_id  │   │ consulta_id   │  │ tabela           │
    │ med_id (FK)  │   │ tipo_exame_id │  │ operacao         │
    │ dosagem      │   │ dt_realizacao │  │ registro_id      │
    │ duracao_dias │   │ resultado     │  │ dado_anterior    │
    │ instrucoes   │   │ status        │  │ dado_novo        │
    └──────┬───────┘   └──────┬────────┘  │ usuario          │
           │                  │           │ host             │
  ┌────────┴───────┐  ┌───────┴────────┐  │ dt_operacao      │
  │  medicamento   │  │  tipo_exame    │  └──────────────────┘
  │────────────────│  │────────────────│
  │ med_id (PK)    │  │ tipo_exame_id  │
  │ nome_generico  │  │ nome           │
  │ classe         │  │ valor_base     │
  │ controlado     │  └────────────────┘
  └────────────────┘
```

## Cardinalidades

| Relacionamento | Cardinalidade |
|---|---|
| especialidade → medico | 1 : N |
| plano_saude → paciente | 1 : N |
| paciente → consulta | 1 : N |
| medico → consulta | 1 : N |
| consulta → prescricao | 1 : N |
| consulta → exame | 1 : N |
| medicamento → prescricao | 1 : N |
| tipo_exame → exame | 1 : N |

## Regras de negócio implementadas

- `status` da consulta aceita apenas: `agendada`, `realizada`, `cancelada`, `faltou`
- `sexo` do paciente aceita apenas: `M`, `F`, `O`
- Consultas com `status = 'realizada'` **não podem ser excluídas** (Trigger INSTEAD OF DELETE)
- Toda alteração em `consulta` e `paciente` gera registro em `auditoria_log`
- `crm` do médico é único no sistema
- `cpf` do paciente é único no sistema
