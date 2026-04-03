create table if not exists public.stg_pessoas (
    id_staging bigserial primary key,
    nome varchar(200),
    cpf varchar(20),
    data_nascimento timestamp,
    email varchar(200),
    telefone varchar(30),
    sexo varchar(10),
    orgao varchar(200),
    matricula varchar(50),
    cargo varchar(200),
    data_admissao timestamp,
    dt_carga timestamp,
    status_processamento varchar(30),
    dt_processamento timestamp,
    motivo_erro_processamento varchar(255),
    id_execucao bigint,
	matricula_duplicada varchar(100),
	cpf_duplicado varchar(100)
);

create table if not exists public.tb_pessoas (
    id_pessoa bigserial primary key,
    nome varchar(200),
    cpf varchar(20),
    data_nascimento timestamp,
    email varchar(200),
    telefone varchar(30),
    sexo varchar(10),
    orgao varchar(200),
    matricula varchar(50),
    cargo varchar(200),
    data_admissao timestamp,
    dt_inclusao timestamp
);

create table if not exists public.etl_pessoas_erros (
    id_erro bigserial primary key,
    nome varchar(200),
    cpf varchar(20),
    data_nascimento timestamp,
    email varchar(200),
    telefone varchar(30),
    sexo varchar(10),
    orgao varchar(200),
    matricula varchar(50),
    cargo varchar(200),
    data_admissao timestamp,
    motivo_erro varchar(255),
    dt_erro timestamp
);

create table if not exists public.etl_metricas_execucao (
    id_execucao bigint primary key,
    nome_processo varchar(150),
    dt_inicio timestamp,
    dt_fim timestamp,
    qtd_pendentes integer,
    qtd_processados_execucao integer,
    qtd_validos_execucao integer,
    qtd_invalidos_execucao integer,
    qtd_validos_total integer,
    qtd_invalidos_total integer,
    status_execucao varchar(30),
    mensagem_erro varchar(500),
    id_execucao_processo bigint,
    id_execucao_stage bigint
);