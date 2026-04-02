--create database teste_etl_pessoas; criando banco

--criando as tabelas:
create table if not exists stg_pessoas (
    id_staging bigserial primary key,
    nome varchar(200),
    cpf varchar(20),
    data_nascimento varchar(30),
    email varchar(200),
    telefone varchar(50),
    sexo varchar(20),
    orgao varchar(50),
    matricula varchar(50),
    cargo varchar(100),
    data_admissao varchar(30),
    dt_carga timestamp default current_timestamp
);


select current_database(), current_schema();
create table if not exists tb_pessoas (
    id_pessoa bigserial primary key,
    nome varchar(200) not null,
    cpf varchar(11) not null,
    data_nascimento date not null,
    email varchar(200),
    telefone varchar(20),
    sexo varchar(1),
    orgao varchar(50) not null,
    matricula varchar(50) not null,
    cargo varchar(100),
    data_admissao date not null,
    dt_inclusao timestamp default current_timestamp
);

create table if not exists etl_pessoas_erros (
    id_erro bigserial primary key,
    nome varchar(200),
    cpf varchar(20),
    data_nascimento varchar(30),
    email varchar(200),
    telefone varchar(50),
    sexo varchar(20),
    orgao varchar(50),
    matricula varchar(50),
    cargo varchar(100),
    data_admissao varchar(30),
    motivo_erro varchar(500) not null,
    dt_erro timestamp default current_timestamp
);

create table if not exists etl_metricas_execucao (
    id_execucao bigserial primary key,
    nome_processo varchar(100) not null,
    dt_inicio timestamp not null,
    dt_fim timestamp,
    qtd_lidos integer default 0,
    qtd_validos integer default 0,
    qtd_invalidos integer default 0,
    status_execucao varchar(30),
    mensagem_erro varchar(1000)
);

select count(*) from stg_pessoas;

select current_database(), current_schema();

select * from public.etl_metricas_execucao;

select count(*) from public.tb_pessoas;
select count(*) from public.etl_pessoas_erros;

select * from public.stg_pessoas;
alter table public.stg_pessoas
add column if not exists status_processamento varchar(20);

alter table public.stg_pessoas
add column if not exists dt_processamento timestamp;

alter table public.stg_pessoas
add column if not exists motivo_erro_processamento varchar(500);


/*update public.stg_pessoas
set status_processamento = null,
    dt_processamento = null,
    motivo_erro_processamento = null;*/