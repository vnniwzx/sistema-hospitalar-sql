-- =====================================================================
--  SISTEMA HOSPITALAR - 02_dados.sql
--  Dados fictícios para teste (nomes, CPFs e CNPJs são inventados)
-- =====================================================================

USE hospital;

-- ---------------------------------------------------------------------
-- Convênios
-- ---------------------------------------------------------------------
INSERT INTO convenios (nome, cnpj, telefone, desconto_pct) VALUES
('Saúde Total',   '11222333000144', '(11) 4002-1000', 30.00),
('VidaMais',      '22333444000155', '(11) 4002-2000', 20.00),
('Bem Estar Plus','33444555000166', '(11) 4002-3000', 40.00);

-- ---------------------------------------------------------------------
-- Pacientes (id_convenio NULL = atendimento particular)
-- ---------------------------------------------------------------------
INSERT INTO pacientes
(nome, cpf, data_nascimento, sexo, telefone, email, endereco, tipo_sanguineo, id_convenio, numero_carteira) VALUES
('Ana Beatriz Souza',      '12345678901', '1995-03-14', 'F', '(11) 98888-0001', 'ana.souza@email.com',     'Rua das Flores, 120 - São Paulo/SP',    'O+',  1, 'ST-000101'),
('Carlos Eduardo Lima',    '23456789012', '1968-07-22', 'M', '(11) 98888-0002', 'carlos.lima@email.com',   'Av. Paulista, 900 - São Paulo/SP',      'A+',  NULL, NULL),
('Fernanda Oliveira',      '34567890123', '1990-11-02', 'F', '(11) 98888-0003', 'fernanda.o@email.com',    'Rua Augusta, 455 - São Paulo/SP',       'B+',  2, 'VM-552301'),
('João Pedro Santos',      '45678901234', '2001-05-30', 'M', '(11) 98888-0004', 'joao.santos@email.com',   'Rua Vergueiro, 1500 - São Paulo/SP',    'O-',  1, 'ST-000245'),
('Mariana Costa',          '56789012345', '1985-09-18', 'F', '(11) 98888-0005', 'mariana.costa@email.com', 'Rua Haddock Lobo, 77 - São Paulo/SP',   'AB+', 3, 'BE-778812'),
('Lucas Almeida',          '67890123456', '1999-01-09', 'M', '(11) 98888-0006', 'lucas.almeida@email.com', 'Rua da Consolação, 310 - São Paulo/SP', 'A-',  NULL, NULL),
('Juliana Pereira',        '78901234567', '1978-12-25', 'F', '(11) 98888-0007', 'juliana.p@email.com',     'Av. Ibirapuera, 2100 - São Paulo/SP',   'O+',  2, 'VM-552944'),
('Rafael Gomes',           '89012345678', '1992-04-11', 'M', '(11) 98888-0008', 'rafael.gomes@email.com',  'Rua Oscar Freire, 50 - São Paulo/SP',   'B-',  3, 'BE-779030'),
('Beatriz Rocha',          '90123456789', '2018-08-03', 'F', '(11) 98888-0009', 'resp.beatriz@email.com',  'Rua Tutoia, 88 - São Paulo/SP',         'A+',  1, 'ST-000390'),
('Pedro Henrique Martins', '01234567890', '2020-02-17', 'M', '(11) 98888-0010', 'resp.pedro@email.com',    'Rua Domingos de Morais, 640 - SP',      'O+',  2, 'VM-553120');

-- ---------------------------------------------------------------------
-- Especialidades
-- ---------------------------------------------------------------------
INSERT INTO especialidades (nome, valor_consulta) VALUES
('Clínica Geral', 200.00),
('Cardiologia',   350.00),
('Pediatria',     250.00),
('Ortopedia',     300.00),
('Dermatologia',  280.00),
('Neurologia',    400.00);

-- ---------------------------------------------------------------------
-- Médicos
-- ---------------------------------------------------------------------
INSERT INTO medicos (nome, crm, id_especialidade, telefone, email) VALUES
('Dr. Roberto Silva',     '102030/SP', 1, '(11) 97777-0001', 'roberto.silva@hospital.com'),
('Dra. Camila Ferreira',  '203040/SP', 2, '(11) 97777-0002', 'camila.ferreira@hospital.com'),
('Dr. André Moreira',     '304050/SP', 3, '(11) 97777-0003', 'andre.moreira@hospital.com'),
('Dra. Patrícia Mendes',  '405060/SP', 4, '(11) 97777-0004', 'patricia.mendes@hospital.com'),
('Dr. Gustavo Ribeiro',   '506070/SP', 5, '(11) 97777-0005', 'gustavo.ribeiro@hospital.com'),
('Dra. Renata Carvalho',  '607080/SP', 6, '(11) 97777-0006', 'renata.carvalho@hospital.com'),
('Dr. Felipe Nunes',      '708090/SP', 1, '(11) 97777-0007', 'felipe.nunes@hospital.com'),
('Dra. Larissa Barros',   '809010/SP', 2, '(11) 97777-0008', 'larissa.barros@hospital.com');

-- ---------------------------------------------------------------------
-- Consultas
-- valor = valor da especialidade - desconto do convênio
-- ---------------------------------------------------------------------
INSERT INTO consultas (id_paciente, id_medico, data_hora, status, motivo, diagnostico, valor) VALUES
(1,  1, '2026-10-05 08:00:00', 'REALIZADA', 'Febre e dor de garganta',    'Faringite bacteriana',   140.00),
(2,  2, '2026-10-06 09:00:00', 'REALIZADA', 'Dor no peito',               'Hipertensão arterial',   350.00),
(3,  5, '2026-10-08 10:30:00', 'REALIZADA', 'Manchas na pele',            'Dermatite de contato',   224.00),
(4,  4, '2026-10-10 14:00:00', 'REALIZADA', 'Dor no joelho após corrida', 'Tendinite patelar',      210.00),
(9,  3, '2026-10-12 09:00:00', 'REALIZADA', 'Tosse persistente',          'Bronquite',              175.00),
(5,  6, '2026-10-15 15:00:00', 'REALIZADA', 'Enxaqueca frequente',        'Enxaqueca crônica',      240.00),
(6,  1, '2026-10-20 08:30:00', 'FALTOU',    'Check-up',                   NULL,                     200.00),
(7,  2, '2026-10-22 11:00:00', 'REALIZADA', 'Palpitações',                'Arritmia leve',          280.00),
(8,  7, '2026-11-03 13:00:00', 'REALIZADA', 'Dor abdominal e vômitos',    'Gastroenterite',         120.00),
(10, 3, '2026-11-05 10:00:00', 'REALIZADA', 'Consulta de rotina',         'Criança saudável',       200.00),
(2,  8, '2026-11-10 16:00:00', 'REALIZADA', 'Retorno - hipertensão',      'Hipertensão controlada', 350.00),
(1,  5, '2026-11-12 09:30:00', 'CANCELADA', 'Acne',                       NULL,                     196.00),
(4,  4, '2026-11-18 14:00:00', 'REALIZADA', 'Retorno - joelho',           'Tendinite em melhora',   210.00),
(3,  1, '2026-12-01 08:00:00', 'AGENDADA',  'Check-up anual',             NULL,                     160.00),
(5,  6, '2026-12-02 15:00:00', 'AGENDADA',  'Retorno - enxaqueca',        NULL,                     240.00),
(6,  2, '2026-12-03 10:00:00', 'AGENDADA',  'Avaliação cardiológica',     NULL,                     350.00),
(7,  8, '2026-12-04 11:00:00', 'AGENDADA',  'Retorno - arritmia',         NULL,                     280.00),
(8,  7, '2026-12-05 13:30:00', 'AGENDADA',  'Retorno - gastroenterite',   NULL,                     120.00);

-- ---------------------------------------------------------------------
-- Medicamentos
-- ---------------------------------------------------------------------
INSERT INTO medicamentos (nome, principio_ativo, apresentacao, estoque) VALUES
('Amoxicilina',  'Amoxicilina',               'Cápsula 500mg',     300),
('Losartana',    'Losartana potássica',       'Comprimido 50mg',   500),
('Dipirona',     'Dipirona sódica',           'Comprimido 500mg',  800),
('Ibuprofeno',   'Ibuprofeno',                'Comprimido 600mg',  400),
('Omeprazol',    'Omeprazol',                 'Cápsula 20mg',      350),
('Propranolol',  'Cloridrato de propranolol', 'Comprimido 40mg',   200),
('Dexametasona', 'Acetato de dexametasona',   'Creme 0,1%',         25),
('Salbutamol',   'Sulfato de salbutamol',     'Aerossol 100mcg',    15);

-- ---------------------------------------------------------------------
-- Prescrições
-- ---------------------------------------------------------------------
INSERT INTO prescricoes (id_consulta, id_medicamento, dosagem, frequencia, duracao_dias) VALUES
(1,  1, '1 cápsula',          'De 8 em 8 horas',          7),
(1,  3, '1 comprimido',       'De 6 em 6 horas se febre', 3),
(2,  2, '1 comprimido',       '1 vez ao dia',            30),
(3,  7, 'Camada fina',        '2 vezes ao dia',          10),
(4,  4, '1 comprimido',       'De 8 em 8 horas',          5),
(5,  8, '2 jatos',            'De 6 em 6 horas',          7),
(6,  6, '1 comprimido',       '2 vezes ao dia',          30),
(8,  6, '1 comprimido',       '1 vez ao dia',            30),
(9,  5, '1 cápsula em jejum', '1 vez ao dia',            30),
(11, 2, '1 comprimido',       '1 vez ao dia',            60);

-- ---------------------------------------------------------------------
-- Tipos de exame
-- ---------------------------------------------------------------------
INSERT INTO tipos_exame (nome, preparo, valor) VALUES
('Hemograma completo',    'Jejum não obrigatório',                  45.00),
('Glicemia em jejum',     'Jejum de 8 horas',                       25.00),
('Eletrocardiograma',     'Sem preparo',                            80.00),
('Raio-X',                'Retirar objetos metálicos',             120.00),
('Ressonância magnética', 'Retirar objetos metálicos; jejum de 4h', 900.00),
('Ecocardiograma',        'Sem preparo',                           350.00);

-- ---------------------------------------------------------------------
-- Exames pedidos
-- ---------------------------------------------------------------------
INSERT INTO exames (id_consulta, id_tipo_exame, data_pedido, data_resultado, resultado, status) VALUES
(1,  1, '2026-10-05', '2026-10-06', 'Leucocitose leve',                      'REALIZADO'),
(2,  3, '2026-10-06', '2026-10-06', 'Sem alterações significativas',         'REALIZADO'),
(2,  2, '2026-10-06', '2026-10-07', '98 mg/dL - normal',                     'REALIZADO'),
(4,  4, '2026-10-10', '2026-10-11', 'Sem fraturas',                          'REALIZADO'),
(6,  5, '2026-10-15', '2026-10-25', 'Sem lesões estruturais',                'REALIZADO'),
(8,  3, '2026-10-22', '2026-10-22', 'Extrassístoles ventriculares isoladas', 'REALIZADO'),
(8,  6, '2026-10-22', NULL,         NULL,                                    'SOLICITADO'),
(9,  1, '2026-11-03', '2026-11-04', 'Dentro da normalidade',                 'REALIZADO'),
(11, 2, '2026-11-10', NULL,         NULL,                                    'SOLICITADO'),
(13, 5, '2026-11-18', NULL,         NULL,                                    'SOLICITADO');

-- ---------------------------------------------------------------------
-- Quartos
-- ---------------------------------------------------------------------
INSERT INTO quartos (numero, tipo, capacidade, valor_diaria) VALUES
('101', 'ENFERMARIA',  4,  250.00),
('102', 'ENFERMARIA',  4,  250.00),
('201', 'APARTAMENTO', 1,  600.00),
('202', 'APARTAMENTO', 1,  600.00),
('301', 'UTI',         1, 2500.00),
('302', 'UTI',         1, 2500.00);

-- ---------------------------------------------------------------------
-- Internações (data_alta NULL = paciente ainda internado)
-- ---------------------------------------------------------------------
INSERT INTO internacoes (id_paciente, id_medico, id_quarto, data_entrada, data_alta_prevista, data_alta, motivo) VALUES
(2, 2, 3, '2026-10-06 12:00:00', '2026-10-09', '2026-10-09 10:00:00', 'Crise hipertensiva'),
(8, 7, 1, '2026-11-03 18:00:00', '2026-11-05', '2026-11-05 09:00:00', 'Desidratação por gastroenterite'),
(5, 6, 4, '2026-11-20 08:00:00', '2026-11-27', NULL,                  'Investigação de enxaqueca refratária'),
(7, 8, 5, '2026-11-22 22:30:00', '2026-11-30', NULL,                  'Arritmia com instabilidade');
