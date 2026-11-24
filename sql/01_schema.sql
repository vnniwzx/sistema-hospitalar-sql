-- =====================================================================
--  SISTEMA HOSPITALAR - 01_schema.sql
--  Criação do banco de dados, tabelas, chaves e índices
--  SGBD: MySQL 8.0+ (compatível com MariaDB 10.5+)
-- =====================================================================

DROP DATABASE IF EXISTS hospital;
CREATE DATABASE hospital
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE hospital;

-- ---------------------------------------------------------------------
-- 1. CONVÊNIOS (planos de saúde)
-- ---------------------------------------------------------------------
CREATE TABLE convenios (
    id_convenio     INT AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(100)  NOT NULL,
    cnpj            CHAR(14)      NOT NULL,
    telefone        VARCHAR(20),
    desconto_pct    DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
    ativo           BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_convenio_cnpj UNIQUE (cnpj),
    CONSTRAINT ck_convenio_desconto CHECK (desconto_pct BETWEEN 0 AND 100)
);

-- ---------------------------------------------------------------------
-- 2. PACIENTES
-- ---------------------------------------------------------------------
CREATE TABLE pacientes (
    id_paciente     INT AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(120)  NOT NULL,
    cpf             CHAR(11)      NOT NULL,
    data_nascimento DATE          NOT NULL,
    sexo            CHAR(1)       NOT NULL,
    telefone        VARCHAR(20),
    email           VARCHAR(120),
    endereco        VARCHAR(200),
    tipo_sanguineo  VARCHAR(3),
    id_convenio     INT           NULL,          -- NULL = particular
    numero_carteira VARCHAR(30)   NULL,
    criado_em       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_paciente_cpf UNIQUE (cpf),
    CONSTRAINT ck_paciente_sexo CHECK (sexo IN ('M', 'F', 'O')),
    CONSTRAINT ck_paciente_sangue CHECK (
        tipo_sanguineo IS NULL OR
        tipo_sanguineo IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')
    ),
    CONSTRAINT fk_paciente_convenio FOREIGN KEY (id_convenio)
        REFERENCES convenios (id_convenio)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- ---------------------------------------------------------------------
-- 3. ESPECIALIDADES
-- ---------------------------------------------------------------------
CREATE TABLE especialidades (
    id_especialidade INT AUTO_INCREMENT PRIMARY KEY,
    nome             VARCHAR(80)   NOT NULL,
    valor_consulta   DECIMAL(10,2) NOT NULL,

    CONSTRAINT uq_especialidade_nome UNIQUE (nome),
    CONSTRAINT ck_especialidade_valor CHECK (valor_consulta > 0)
);

-- ---------------------------------------------------------------------
-- 4. MÉDICOS
-- ---------------------------------------------------------------------
CREATE TABLE medicos (
    id_medico        INT AUTO_INCREMENT PRIMARY KEY,
    nome             VARCHAR(120) NOT NULL,
    crm              VARCHAR(15)  NOT NULL,      -- ex.: 123456/SP
    id_especialidade INT          NOT NULL,
    telefone         VARCHAR(20),
    email            VARCHAR(120),
    ativo            BOOLEAN      NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_medico_crm UNIQUE (crm),
    CONSTRAINT fk_medico_especialidade FOREIGN KEY (id_especialidade)
        REFERENCES especialidades (id_especialidade)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- 5. CONSULTAS
-- ---------------------------------------------------------------------
CREATE TABLE consultas (
    id_consulta  INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente  INT           NOT NULL,
    id_medico    INT           NOT NULL,
    data_hora    DATETIME      NOT NULL,
    status       VARCHAR(12)   NOT NULL DEFAULT 'AGENDADA',
    motivo       VARCHAR(255),
    diagnostico  VARCHAR(255),
    valor        DECIMAL(10,2) NOT NULL,

    CONSTRAINT ck_consulta_status CHECK (
        status IN ('AGENDADA', 'REALIZADA', 'CANCELADA', 'FALTOU')
    ),
    CONSTRAINT ck_consulta_valor CHECK (valor >= 0),
    -- um médico não pode ter duas consultas no mesmo horário
    CONSTRAINT uq_consulta_medico_horario UNIQUE (id_medico, data_hora),
    CONSTRAINT fk_consulta_paciente FOREIGN KEY (id_paciente)
        REFERENCES pacientes (id_paciente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_consulta_medico FOREIGN KEY (id_medico)
        REFERENCES medicos (id_medico)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- 6. MEDICAMENTOS
-- ---------------------------------------------------------------------
CREATE TABLE medicamentos (
    id_medicamento INT AUTO_INCREMENT PRIMARY KEY,
    nome           VARCHAR(100) NOT NULL,
    principio_ativo VARCHAR(100),
    apresentacao   VARCHAR(60),                  -- ex.: comprimido 500mg
    estoque        INT          NOT NULL DEFAULT 0,

    CONSTRAINT uq_medicamento UNIQUE (nome, apresentacao),
    CONSTRAINT ck_medicamento_estoque CHECK (estoque >= 0)
);

-- ---------------------------------------------------------------------
-- 7. PRESCRIÇÕES (receitas geradas numa consulta)
-- ---------------------------------------------------------------------
CREATE TABLE prescricoes (
    id_prescricao  INT AUTO_INCREMENT PRIMARY KEY,
    id_consulta    INT          NOT NULL,
    id_medicamento INT          NOT NULL,
    dosagem        VARCHAR(60)  NOT NULL,        -- ex.: 1 comprimido
    frequencia     VARCHAR(60)  NOT NULL,        -- ex.: de 8 em 8 horas
    duracao_dias   INT          NOT NULL,

    CONSTRAINT ck_prescricao_duracao CHECK (duracao_dias > 0),
    CONSTRAINT fk_prescricao_consulta FOREIGN KEY (id_consulta)
        REFERENCES consultas (id_consulta)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_prescricao_medicamento FOREIGN KEY (id_medicamento)
        REFERENCES medicamentos (id_medicamento)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- 8. TIPOS DE EXAME (catálogo)
-- ---------------------------------------------------------------------
CREATE TABLE tipos_exame (
    id_tipo_exame INT AUTO_INCREMENT PRIMARY KEY,
    nome          VARCHAR(100)  NOT NULL,
    preparo       VARCHAR(255),                  -- ex.: jejum de 8h
    valor         DECIMAL(10,2) NOT NULL,

    CONSTRAINT uq_tipo_exame_nome UNIQUE (nome),
    CONSTRAINT ck_tipo_exame_valor CHECK (valor > 0)
);

-- ---------------------------------------------------------------------
-- 9. EXAMES (exames pedidos numa consulta)
-- ---------------------------------------------------------------------
CREATE TABLE exames (
    id_exame       INT AUTO_INCREMENT PRIMARY KEY,
    id_consulta    INT          NOT NULL,
    id_tipo_exame  INT          NOT NULL,
    data_pedido    DATE         NOT NULL,
    data_resultado DATE         NULL,
    resultado      VARCHAR(255) NULL,
    status         VARCHAR(12)  NOT NULL DEFAULT 'SOLICITADO',

    CONSTRAINT ck_exame_status CHECK (
        status IN ('SOLICITADO', 'REALIZADO', 'CANCELADO')
    ),
    CONSTRAINT ck_exame_datas CHECK (
        data_resultado IS NULL OR data_resultado >= data_pedido
    ),
    CONSTRAINT fk_exame_consulta FOREIGN KEY (id_consulta)
        REFERENCES consultas (id_consulta)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_exame_tipo FOREIGN KEY (id_tipo_exame)
        REFERENCES tipos_exame (id_tipo_exame)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- 10. QUARTOS
-- ---------------------------------------------------------------------
CREATE TABLE quartos (
    id_quarto     INT AUTO_INCREMENT PRIMARY KEY,
    numero        VARCHAR(10)   NOT NULL,
    tipo          VARCHAR(15)   NOT NULL,
    capacidade    INT           NOT NULL,
    valor_diaria  DECIMAL(10,2) NOT NULL,

    CONSTRAINT uq_quarto_numero UNIQUE (numero),
    CONSTRAINT ck_quarto_tipo CHECK (tipo IN ('ENFERMARIA', 'APARTAMENTO', 'UTI')),
    CONSTRAINT ck_quarto_capacidade CHECK (capacidade > 0),
    CONSTRAINT ck_quarto_diaria CHECK (valor_diaria > 0)
);

-- ---------------------------------------------------------------------
-- 11. INTERNAÇÕES
-- ---------------------------------------------------------------------
CREATE TABLE internacoes (
    id_internacao     INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente       INT          NOT NULL,
    id_medico         INT          NOT NULL,     -- médico responsável
    id_quarto         INT          NOT NULL,
    data_entrada      DATETIME     NOT NULL,
    data_alta_prevista DATE        NULL,
    data_alta         DATETIME     NULL,         -- NULL = ainda internado
    motivo            VARCHAR(255) NOT NULL,

    CONSTRAINT ck_internacao_alta CHECK (
        data_alta IS NULL OR data_alta >= data_entrada
    ),
    CONSTRAINT fk_internacao_paciente FOREIGN KEY (id_paciente)
        REFERENCES pacientes (id_paciente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_internacao_medico FOREIGN KEY (id_medico)
        REFERENCES medicos (id_medico)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_internacao_quarto FOREIGN KEY (id_quarto)
        REFERENCES quartos (id_quarto)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- ÍNDICES (aceleram as buscas mais comuns)
-- ---------------------------------------------------------------------
CREATE INDEX idx_paciente_nome      ON pacientes (nome);
CREATE INDEX idx_medico_nome        ON medicos (nome);
CREATE INDEX idx_consulta_data      ON consultas (data_hora);
CREATE INDEX idx_consulta_status    ON consultas (status);
CREATE INDEX idx_exame_status       ON exames (status);
CREATE INDEX idx_internacao_alta    ON internacoes (data_alta);
