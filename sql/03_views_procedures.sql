-- =====================================================================
--  SISTEMA HOSPITALAR - 03_views_procedures.sql
--  Views (consultas prontas) e procedures (regras de negócio)
-- =====================================================================

USE hospital;

-- =====================================================================
-- VIEWS
-- =====================================================================

-- ---------------------------------------------------------------------
-- Agenda completa: consulta + paciente + médico + especialidade + convênio
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_agenda_consultas AS
SELECT
    c.id_consulta,
    c.data_hora,
    c.status,
    p.nome                           AS paciente,
    m.nome                           AS medico,
    e.nome                           AS especialidade,
    COALESCE(cv.nome, 'Particular')  AS convenio,
    c.motivo,
    c.diagnostico,
    c.valor
FROM consultas c
JOIN pacientes      p  ON p.id_paciente      = c.id_paciente
JOIN medicos        m  ON m.id_medico        = c.id_medico
JOIN especialidades e  ON e.id_especialidade = m.id_especialidade
LEFT JOIN convenios cv ON cv.id_convenio     = p.id_convenio;

-- ---------------------------------------------------------------------
-- Pacientes internados agora (sem alta), com dias e custo parcial
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_pacientes_internados AS
SELECT
    i.id_internacao,
    p.nome                                              AS paciente,
    q.numero                                            AS quarto,
    q.tipo                                              AS tipo_quarto,
    m.nome                                              AS medico_responsavel,
    i.data_entrada,
    i.data_alta_prevista,
    GREATEST(DATEDIFF(NOW(), i.data_entrada), 1)        AS dias_internado,
    GREATEST(DATEDIFF(NOW(), i.data_entrada), 1)
        * q.valor_diaria                                AS custo_parcial,
    i.motivo
FROM internacoes i
JOIN pacientes p ON p.id_paciente = i.id_paciente
JOIN medicos   m ON m.id_medico   = i.id_medico
JOIN quartos   q ON q.id_quarto   = i.id_quarto
WHERE i.data_alta IS NULL;

-- ---------------------------------------------------------------------
-- Ocupação dos quartos (vagas livres)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_ocupacao_quartos AS
SELECT
    q.numero,
    q.tipo,
    q.capacidade,
    COUNT(i.id_internacao)                 AS ocupados,
    q.capacidade - COUNT(i.id_internacao)  AS vagas_livres
FROM quartos q
LEFT JOIN internacoes i
       ON i.id_quarto = q.id_quarto
      AND i.data_alta IS NULL
GROUP BY q.id_quarto, q.numero, q.tipo, q.capacidade;

-- ---------------------------------------------------------------------
-- Faturamento mensal de consultas realizadas
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_faturamento_mensal AS
SELECT
    DATE_FORMAT(data_hora, '%Y-%m')  AS mes,
    COUNT(*)                         AS consultas_realizadas,
    SUM(valor)                       AS faturamento
FROM consultas
WHERE status = 'REALIZADA'
GROUP BY DATE_FORMAT(data_hora, '%Y-%m');

-- ---------------------------------------------------------------------
-- Exames ainda aguardando resultado
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_exames_pendentes AS
SELECT
    ex.id_exame,
    p.nome          AS paciente,
    te.nome         AS exame,
    te.preparo,
    ex.data_pedido,
    DATEDIFF(CURDATE(), ex.data_pedido) AS dias_aguardando
FROM exames ex
JOIN tipos_exame te ON te.id_tipo_exame = ex.id_tipo_exame
JOIN consultas   c  ON c.id_consulta    = ex.id_consulta
JOIN pacientes   p  ON p.id_paciente    = c.id_paciente
WHERE ex.status = 'SOLICITADO';


-- =====================================================================
-- PROCEDURES
-- Obs.: o DELIMITER funciona no terminal do MySQL e no MySQL Workbench.
-- =====================================================================

DROP PROCEDURE IF EXISTS sp_agendar_consulta;
DROP PROCEDURE IF EXISTS sp_internar_paciente;
DROP PROCEDURE IF EXISTS sp_dar_alta;

DELIMITER $$

-- ---------------------------------------------------------------------
-- Agenda uma consulta já calculando o valor com o desconto do convênio
-- Uso: CALL sp_agendar_consulta(id_paciente, id_medico, 'AAAA-MM-DD HH:MM:SS', 'motivo');
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_agendar_consulta (
    IN p_id_paciente INT,
    IN p_id_medico   INT,
    IN p_data_hora   DATETIME,
    IN p_motivo      VARCHAR(255)
)
BEGIN
    DECLARE v_valor_base DECIMAL(10,2);
    DECLARE v_desconto   DECIMAL(5,2) DEFAULT 0;

    IF p_data_hora <= NOW() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A consulta precisa ser agendada para uma data futura.';
    END IF;

    -- valor da especialidade do médico (só médicos ativos)
    SELECT e.valor_consulta INTO v_valor_base
    FROM medicos m
    JOIN especialidades e ON e.id_especialidade = m.id_especialidade
    WHERE m.id_medico = p_id_medico AND m.ativo = TRUE;

    IF v_valor_base IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Médico não encontrado ou inativo.';
    END IF;

    -- desconto do convênio do paciente (0 se for particular)
    SELECT COALESCE(cv.desconto_pct, 0) INTO v_desconto
    FROM pacientes p
    LEFT JOIN convenios cv ON cv.id_convenio = p.id_convenio AND cv.ativo = TRUE
    WHERE p.id_paciente = p_id_paciente;

    INSERT INTO consultas (id_paciente, id_medico, data_hora, status, motivo, valor)
    VALUES (p_id_paciente, p_id_medico, p_data_hora, 'AGENDADA', p_motivo,
            ROUND(v_valor_base * (1 - v_desconto / 100), 2));

    SELECT LAST_INSERT_ID() AS id_consulta_criada;
END $$

-- ---------------------------------------------------------------------
-- Interna um paciente, verificando se há vaga no quarto
-- Uso: CALL sp_internar_paciente(id_paciente, id_medico, id_quarto, 'AAAA-MM-DD', 'motivo');
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_internar_paciente (
    IN p_id_paciente   INT,
    IN p_id_medico     INT,
    IN p_id_quarto     INT,
    IN p_alta_prevista DATE,
    IN p_motivo        VARCHAR(255)
)
BEGIN
    DECLARE v_capacidade INT;
    DECLARE v_ocupados   INT;

    -- paciente já internado?
    IF EXISTS (SELECT 1 FROM internacoes
               WHERE id_paciente = p_id_paciente AND data_alta IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Paciente já está internado.';
    END IF;

    SELECT capacidade INTO v_capacidade
    FROM quartos WHERE id_quarto = p_id_quarto;

    SELECT COUNT(*) INTO v_ocupados
    FROM internacoes
    WHERE id_quarto = p_id_quarto AND data_alta IS NULL;

    IF v_capacidade IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quarto não encontrado.';
    ELSEIF v_ocupados >= v_capacidade THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quarto sem vagas.';
    END IF;

    INSERT INTO internacoes (id_paciente, id_medico, id_quarto, data_entrada, data_alta_prevista, motivo)
    VALUES (p_id_paciente, p_id_medico, p_id_quarto, NOW(), p_alta_prevista, p_motivo);

    SELECT LAST_INSERT_ID() AS id_internacao_criada;
END $$

-- ---------------------------------------------------------------------
-- Dá alta a um paciente e mostra o custo total da internação
-- Uso: CALL sp_dar_alta(id_internacao);
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_dar_alta (
    IN p_id_internacao INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM internacoes
                   WHERE id_internacao = p_id_internacao AND data_alta IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Internação não encontrada ou paciente já teve alta.';
    END IF;

    UPDATE internacoes
    SET data_alta = NOW()
    WHERE id_internacao = p_id_internacao;

    SELECT
        p.nome                                         AS paciente,
        i.data_entrada,
        i.data_alta,
        GREATEST(DATEDIFF(i.data_alta, i.data_entrada), 1)                  AS diarias,
        GREATEST(DATEDIFF(i.data_alta, i.data_entrada), 1) * q.valor_diaria AS custo_total
    FROM internacoes i
    JOIN pacientes p ON p.id_paciente = i.id_paciente
    JOIN quartos   q ON q.id_quarto   = i.id_quarto
    WHERE i.id_internacao = p_id_internacao;
END $$

DELIMITER ;
