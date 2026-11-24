-- =====================================================================
--  SISTEMA HOSPITALAR - 04_consultas.sql
--  Exemplos de consultas (do básico ao avançado)
--  Rode uma de cada vez para ver os resultados.
-- =====================================================================

USE hospital;

-- ---------------------------------------------------------------------
-- 1. SELECT simples: todos os pacientes em ordem alfabética
-- ---------------------------------------------------------------------
SELECT id_paciente, nome, cpf, telefone
FROM pacientes
ORDER BY nome;

-- ---------------------------------------------------------------------
-- 2. Calculando a idade dos pacientes
-- ---------------------------------------------------------------------
SELECT
    nome,
    data_nascimento,
    TIMESTAMPDIFF(YEAR, data_nascimento, CURDATE()) AS idade
FROM pacientes
ORDER BY idade DESC;

-- ---------------------------------------------------------------------
-- 3. CASE: classificando pacientes por faixa etária
-- ---------------------------------------------------------------------
SELECT
    nome,
    TIMESTAMPDIFF(YEAR, data_nascimento, CURDATE()) AS idade,
    CASE
        WHEN TIMESTAMPDIFF(YEAR, data_nascimento, CURDATE()) < 12 THEN 'Criança'
        WHEN TIMESTAMPDIFF(YEAR, data_nascimento, CURDATE()) < 18 THEN 'Adolescente'
        WHEN TIMESTAMPDIFF(YEAR, data_nascimento, CURDATE()) < 60 THEN 'Adulto'
        ELSE 'Idoso'
    END AS faixa_etaria
FROM pacientes;

-- ---------------------------------------------------------------------
-- 4. INNER JOIN: médicos com suas especialidades
-- ---------------------------------------------------------------------
SELECT m.nome AS medico, m.crm, e.nome AS especialidade, e.valor_consulta
FROM medicos m
INNER JOIN especialidades e ON e.id_especialidade = m.id_especialidade
ORDER BY e.nome, m.nome;

-- ---------------------------------------------------------------------
-- 5. LEFT JOIN: pacientes e seus convênios (inclui particulares)
-- ---------------------------------------------------------------------
SELECT
    p.nome,
    COALESCE(c.nome, 'Particular') AS convenio,
    p.numero_carteira
FROM pacientes p
LEFT JOIN convenios c ON c.id_convenio = p.id_convenio
ORDER BY convenio, p.nome;

-- ---------------------------------------------------------------------
-- 6. Usando a VIEW: próximas consultas agendadas
-- ---------------------------------------------------------------------
SELECT data_hora, paciente, medico, especialidade, convenio
FROM vw_agenda_consultas
WHERE status = 'AGENDADA'
ORDER BY data_hora;

-- ---------------------------------------------------------------------
-- 7. Histórico completo de um paciente (consultas + diagnósticos)
-- ---------------------------------------------------------------------
SELECT data_hora, medico, especialidade, status, diagnostico, valor
FROM vw_agenda_consultas
WHERE paciente = 'Carlos Eduardo Lima'
ORDER BY data_hora;

-- ---------------------------------------------------------------------
-- 8. GROUP BY: quantidade de consultas por status
-- ---------------------------------------------------------------------
SELECT status, COUNT(*) AS quantidade
FROM consultas
GROUP BY status
ORDER BY quantidade DESC;

-- ---------------------------------------------------------------------
-- 9. GROUP BY + HAVING: médicos com 2 ou mais consultas realizadas
-- ---------------------------------------------------------------------
SELECT
    m.nome            AS medico,
    COUNT(*)          AS consultas_realizadas,
    SUM(c.valor)      AS total_faturado
FROM consultas c
JOIN medicos m ON m.id_medico = c.id_medico
WHERE c.status = 'REALIZADA'
GROUP BY m.id_medico, m.nome
HAVING COUNT(*) >= 2
ORDER BY total_faturado DESC;

-- ---------------------------------------------------------------------
-- 10. Faturamento por especialidade
-- ---------------------------------------------------------------------
SELECT
    e.nome                     AS especialidade,
    COUNT(c.id_consulta)       AS consultas,
    COALESCE(SUM(c.valor), 0)  AS faturamento
FROM especialidades e
LEFT JOIN medicos   m ON m.id_especialidade = e.id_especialidade
LEFT JOIN consultas c ON c.id_medico = m.id_medico AND c.status = 'REALIZADA'
GROUP BY e.id_especialidade, e.nome
ORDER BY faturamento DESC;

-- ---------------------------------------------------------------------
-- 11. Faturamento mensal (VIEW)
-- ---------------------------------------------------------------------
SELECT * FROM vw_faturamento_mensal ORDER BY mes;

-- ---------------------------------------------------------------------
-- 12. Receita de uma consulta (prescrições)
-- ---------------------------------------------------------------------
SELECT
    p.nome            AS paciente,
    m.nome            AS medico,
    med.nome          AS medicamento,
    med.apresentacao,
    pr.dosagem,
    pr.frequencia,
    pr.duracao_dias
FROM prescricoes pr
JOIN consultas    c   ON c.id_consulta      = pr.id_consulta
JOIN pacientes    p   ON p.id_paciente      = c.id_paciente
JOIN medicos      m   ON m.id_medico        = c.id_medico
JOIN medicamentos med ON med.id_medicamento = pr.id_medicamento
WHERE c.id_consulta = 1;

-- ---------------------------------------------------------------------
-- 13. Medicamentos mais prescritos
-- ---------------------------------------------------------------------
SELECT med.nome, COUNT(*) AS vezes_prescrito
FROM prescricoes pr
JOIN medicamentos med ON med.id_medicamento = pr.id_medicamento
GROUP BY med.id_medicamento, med.nome
ORDER BY vezes_prescrito DESC;

-- ---------------------------------------------------------------------
-- 14. Medicamentos com estoque baixo (menos de 50 unidades)
-- ---------------------------------------------------------------------
SELECT nome, apresentacao, estoque
FROM medicamentos
WHERE estoque < 50
ORDER BY estoque;

-- ---------------------------------------------------------------------
-- 15. Exames aguardando resultado (VIEW)
-- ---------------------------------------------------------------------
SELECT * FROM vw_exames_pendentes ORDER BY dias_aguardando DESC;

-- ---------------------------------------------------------------------
-- 16. Pacientes internados agora (VIEW)
-- ---------------------------------------------------------------------
SELECT paciente, quarto, tipo_quarto, medico_responsavel, dias_internado, custo_parcial
FROM vw_pacientes_internados;

-- ---------------------------------------------------------------------
-- 17. Ocupação dos quartos (VIEW)
-- ---------------------------------------------------------------------
SELECT * FROM vw_ocupacao_quartos ORDER BY tipo, numero;

-- ---------------------------------------------------------------------
-- 18. Subconsulta: pacientes que NUNCA faltaram nem cancelaram
-- ---------------------------------------------------------------------
SELECT nome
FROM pacientes
WHERE id_paciente NOT IN (
    SELECT id_paciente
    FROM consultas
    WHERE status IN ('FALTOU', 'CANCELADA')
)
ORDER BY nome;

-- ---------------------------------------------------------------------
-- 19. Subconsulta: consultas com valor acima da média
-- ---------------------------------------------------------------------
SELECT id_consulta, paciente, especialidade, valor
FROM vw_agenda_consultas
WHERE valor > (SELECT AVG(valor) FROM consultas)
ORDER BY valor DESC;

-- ---------------------------------------------------------------------
-- 20. Custo total de internações já encerradas
-- ---------------------------------------------------------------------
SELECT
    p.nome                                                AS paciente,
    q.numero                                              AS quarto,
    GREATEST(DATEDIFF(i.data_alta, i.data_entrada), 1)    AS diarias,
    GREATEST(DATEDIFF(i.data_alta, i.data_entrada), 1)
        * q.valor_diaria                                  AS custo_total
FROM internacoes i
JOIN pacientes p ON p.id_paciente = i.id_paciente
JOIN quartos   q ON q.id_quarto   = i.id_quarto
WHERE i.data_alta IS NOT NULL;


-- =====================================================================
-- OPERAÇÕES (INSERT / UPDATE / DELETE / PROCEDURES)
-- Estão dentro de uma TRANSAÇÃO com ROLLBACK no final, então você pode
-- rodar à vontade: nada fica salvo. Troque ROLLBACK por COMMIT para salvar.
-- =====================================================================

START TRANSACTION;

-- Cadastrar um novo paciente
INSERT INTO pacientes (nome, cpf, data_nascimento, sexo, telefone, id_convenio, numero_carteira)
VALUES ('Paciente Teste', '99999999999', '2000-01-01', 'M', '(11) 90000-0000', 1, 'ST-999999');

-- Agendar consulta pela procedure (o valor com desconto é calculado sozinho)
CALL sp_agendar_consulta(LAST_INSERT_ID(), 2, '2030-01-10 09:00:00', 'Avaliação de rotina');

-- Marcar uma consulta como realizada e registrar o diagnóstico
UPDATE consultas
SET status = 'REALIZADA', diagnostico = 'Sem alterações'
WHERE id_consulta = 14;

-- Lançar resultado de um exame
UPDATE exames
SET status = 'REALIZADO', data_resultado = CURDATE(), resultado = 'Normal'
WHERE id_exame = 9;

-- Dar alta a um paciente internado (mostra o custo total)
CALL sp_dar_alta(3);

-- Cancelar uma consulta agendada
UPDATE consultas SET status = 'CANCELADA' WHERE id_consulta = 18;

-- Excluir um exame pedido por engano
DELETE FROM exames WHERE id_exame = 10;

ROLLBACK;  -- desfaz tudo acima
