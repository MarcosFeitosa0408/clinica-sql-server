-- =============================================
-- PROJETO SQL CLÍNICA  |  SQL Server 2019+
-- Arquivo: 02_dml_seed.sql
-- Descrição: Dados iniciais de exemplo
-- =============================================
USE clinica_db;
GO

-- Especialidades
INSERT INTO especialidade (nome, valor_consulta_base) VALUES
('Clínica Geral',   150.00),
('Cardiologia',     280.00),
('Ortopedia',       260.00),
('Dermatologia',    220.00),
('Psiquiatria',     300.00);

-- Planos de Saúde
INSERT INTO plano_saude (nome, tipo, cobertura_pct) VALUES
('Unimed Básico',    'basico',        60.00),
('Amil Plus',        'intermediario', 75.00),
('Bradesco Premium', 'premium',       90.00),
('Particular',       'basico',         0.00);

-- Médicos
INSERT INTO medico (nome, crm, especialidade_id, data_admissao) VALUES
('Dr. Rafael Almeida',  'CRM-SP 123456', 1, '2018-03-10'),
('Dra. Camila Torres',  'CRM-SP 234567', 2, '2019-07-01'),
('Dr. Marcelo Vieira',  'CRM-SP 345678', 3, '2020-01-15'),
('Dra. Fernanda Lima',  'CRM-SP 456789', 4, '2021-06-20'),
('Dr. Eduardo Souza',   'CRM-SP 567890', 5, '2017-11-05');

-- Pacientes
INSERT INTO paciente (nome, cpf, data_nasc, sexo, plano_id) VALUES
('Ana Paula Ramos',   '11122233344', '1985-04-12', 'F', 3),
('Carlos Mendes',     '22233344455', '1972-09-28', 'M', 2),
('Beatriz Oliveira',  '33344455566', '1990-01-05', 'F', 1),
('João Ferreira',     '44455566677', '1965-11-17', 'M', 4),
('Mariana Costa',     '55566677788', '2001-07-30', 'F', 3),
('Paulo Rodrigues',   '66677788899', '1958-03-22', 'M', 2),
('Luciana Martins',   '77788899900', '1995-12-10', 'F', 1),
('Ricardo Souza',     '88899900011', '1980-08-05', 'M', 4);

-- Medicamentos
INSERT INTO medicamento (nome_generico, classe, controlado) VALUES
('Losartana 50mg',     'Anti-hipertensivo', 0),
('Atorvastatina 20mg', 'Estatina',          0),
('Alprazolam 0.5mg',   'Ansiolítico',       1),
('Amoxicilina 500mg',  'Antibiótico',       0),
('Fluoxetina 20mg',    'Antidepressivo',    1),
('Metformina 850mg',   'Antidiabético',     0),
('Omeprazol 20mg',     'Antiulceroso',      0);

-- Tipos de Exame
INSERT INTO tipo_exame (nome, valor_base) VALUES
('Hemograma Completo',     45.00),
('Glicemia em Jejum',      25.00),
('Eletrocardiograma',     120.00),
('Raio-X Tórax',           80.00),
('Ressonância Magnética', 450.00);

-- Consultas (amostra representativa)
INSERT INTO consulta (paciente_id, medico_id, dt_consulta, status, valor_cobrado) VALUES
(1, 2, '2024-01-10 09:00', 'realizada', 280.00),
(2, 2, '2024-01-15 10:30', 'realizada', 280.00),
(3, 1, '2024-01-20 14:00', 'realizada', 150.00),
(1, 2, '2024-02-12 09:00', 'realizada', 280.00),
(4, 3, '2024-02-18 11:00', 'faltou',    260.00),
(5, 4, '2024-02-25 15:30', 'realizada', 220.00),
(2, 5, '2024-03-05 08:30', 'realizada', 300.00),
(6, 2, '2024-03-12 09:00', 'cancelada', 280.00),
(7, 1, '2024-03-20 16:00', 'realizada', 150.00),
(1, 2, '2024-04-08 09:00', 'realizada', 280.00),
(3, 4, '2024-04-15 14:30', 'realizada', 220.00),
(8, 3, '2024-04-22 11:00', 'realizada', 260.00),
(4, 1, '2024-05-06 09:30', 'realizada', 150.00),
(5, 5, '2024-05-14 10:00', 'realizada', 300.00),
(2, 2, '2024-06-03 09:00', 'faltou',    280.00);

-- Prescrições
INSERT INTO prescricao (consulta_id, med_id, dosagem, duracao_dias, instrucoes) VALUES
(1, 1, '50mg 1x/dia',   30, 'Tomar pela manhã em jejum'),
(1, 2, '20mg 1x/dia',   90, 'Tomar à noite'),
(2, 1, '50mg 1x/dia',   60, 'Monitorar pressão semanalmente'),
(3, 4, '500mg 3x/dia',   7, 'Tomar com alimentos'),
(5, 3, '0.5mg 2x/dia',  30, 'Não dirigir após uso'),
(7, 5, '20mg 1x/dia',   60, 'Tomar pela manhã'),
(9, 7, '20mg 1x/dia',   30, 'Tomar 30min antes do café');

-- Exames
INSERT INTO exame (consulta_id, tipo_exame_id, dt_realizacao, resultado, status) VALUES
(1, 1, '2024-01-12', 'Hemograma normal. Sem alterações.', 'realizado'),
(1, 3, '2024-01-12', 'Ritmo sinusal. Sem alterações.', 'realizado'),
(3, 1, '2024-01-22', 'Hemograma normal.', 'realizado'),
(4, 2, '2024-02-14', 'Glicemia: 98 mg/dL (normal)', 'realizado'),
(10, 3, NULL, NULL, 'pendente'),
(12, 4, '2024-04-24', 'Sem consolidações pulmonares.', 'realizado');
GO
