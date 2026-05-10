# =============================================
# GUIA: Como publicar este projeto no GitHub
# =============================================

## 1. Pré-requisitos

- Git instalado (https://git-scm.com)
- Conta no GitHub (https://github.com)
- GitHub CLI opcional (https://cli.github.com)

---

## 2. Inicializar o repositório local

```bash
# Entre na pasta do projeto
cd clinica-sql-server

# Inicie o git
git init

# Adicione todos os arquivos
git add .

# Primeiro commit
git commit -m "feat: projeto SQL Server clínica médica completo"
```

---

## 3. Criar o repositório no GitHub

### Opção A — Pelo site
1. Acesse https://github.com/new
2. Nome: `clinica-sql-server`
3. Descrição: `Projeto analítico SQL Server para clínicas médicas — schema, queries avançadas, procedures e auditoria`
4. Visibilidade: **Public** (para portfólio)
5. NÃO marque "Add a README" (já temos um)
6. Clique em **Create repository**

### Opção B — Via GitHub CLI
```bash
gh repo create clinica-sql-server --public --description "Projeto SQL Server para clínicas médicas"
```

---

## 4. Conectar e enviar

```bash
# Conecte ao repositório remoto (substitua SEU-USUARIO)
git remote add origin https://github.com/SEU-USUARIO/clinica-sql-server.git

# Renomeie a branch para main (padrão GitHub)
git branch -M main

# Envie o código
git push -u origin main
```

---

## 5. Deixar o projeto com cara profissional

### Topics (tags de busca no GitHub)
No repositório → ⚙ Settings → Topics, adicione:
```
sql-server  sql  data-analysis  healthcare  window-functions  stored-procedures  t-sql  portfolio
```

### Ativar GitHub Pages para o README aparecer bonito
Não é necessário — o README.md já renderiza automaticamente na página inicial do repositório.

### Adicionar uma licença
```bash
# Crie o arquivo LICENSE com o conteúdo MIT
# Ou no GitHub: Add file → Create new file → LICENSE → Choose a template → MIT
```

---

## 6. Commits futuros (boas práticas)

```bash
# Sempre use mensagens descritivas com prefixo semântico:
git commit -m "feat: adiciona SP de relatório de sinistralidade"
git commit -m "fix: corrige cálculo de copagamento na view"
git commit -m "docs: atualiza diagrama ER com tabela de auditoria"
git commit -m "perf: adiciona índice filtrado em consulta realizada"
```

---

## 7. Estrutura final no GitHub

O repositório ficará assim:
```
github.com/SEU-USUARIO/clinica-sql-server
├── 📄 README.md          ← apresentação automática
├── 📁 docs/              ← diagrama ER
├── 📁 schema/            ← DDL das tabelas
├── 📁 data/              ← dados de exemplo
├── 📁 indexes/           ← performance
├── 📁 views/             ← camada de leitura
├── 📁 queries/           ← análises avançadas
├── 📁 procedures/        ← stored procedures
└── 📁 triggers/          ← auditoria
```
