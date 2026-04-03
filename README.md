# ETL de Pessoas com Pentaho PDI

## Objetivo

Este projeto implementa um processo ETL para carga, tratamento, validação e monitoramento de dados de pessoas a partir de arquivos CSV, utilizando Pentaho Data Integration (PDI) e PostgreSQL.

A solução realiza:

- leitura de arquivos CSV de entrada
- carga em tabela de staging
- tratamento e validação dos dados
- separação entre registros válidos e inválidos
- carga de registros válidos na tabela final
- gravação de registros inválidos em tabela de erros
- atualização da staging com status de processamento
- geração de métricas de execução
- movimentação dos arquivos processados para pasta de histórico

---

## Arquitetura da solução

A solução foi organizada em um job principal e transformações auxiliares.

### Fluxo geral do job

```text
Start
  |
  v
00_gera_id_execucao
  |
  v
01_captura_staging_pessoas
  |
  v
Move files para processados
  |
  v
02_tratamento_pessoas
  |
  v
03_metricas_execucao
  |
  v
Success

Componentes do processo
1. Job principal

O job principal é responsável por orquestrar toda a execução do processo.

00_gera_id_execucao

Responsável por:

obter data/hora da execução
gerar um identificador único de execução
armazenar o identificador em variável Pentaho (ID_EXECUCAO)

Esse identificador é utilizado para rastrear os registros tratados e consolidar as métricas da execução.

01_captura_staging_pessoas

Responsável por:

localizar os arquivos CSV na pasta de entrada
ler os arquivos
mapear os campos
inserir ou atualizar os dados na tabela public.stg_pessoas

Essa etapa representa a carga inicial para a camada de staging.

Move files para processados

Responsável por:

mover os arquivos lidos da pasta de entrada para a pasta de processados

Essa etapa evita que os arquivos permaneçam disponíveis para nova leitura na pasta de entrada ao final da execução.

02_tratamento_pessoas

Responsável por:

ler os registros da staging
aplicar regras de validação e tratamento
encaminhar registros válidos para a tabela final
encaminhar registros inválidos para a tabela de erros
atualizar a staging com status, motivo do erro, data de processamento e identificador da execução
03_metricas_execucao

Responsável por:

consolidar os indicadores da execução
calcular quantidades de registros processados, válidos, inválidos e pendentes
registrar início, fim, status e totais da execução
inserir o resumo da execução em tabela de métricas
Transformação 01 - Captura para staging

A transformação de captura realiza a leitura dos arquivos CSV e a gravação em staging.

Fluxo lógico
Leitura dos arquivos CSV
  |
  v
Mapeamento dos campos
  |
  v
Insert / Update em public.stg_pessoas
Objetivo
carregar os dados dos arquivos CSV para a tabela public.stg_pessoas
preparar os registros para a etapa de tratamento
Tabela utilizada
public.stg_pessoas
Transformação 02 - Tratamento de pessoas

Essa é a principal transformação de negócio do processo.

Fluxo lógico
Table input
  |
  v
Select values
  |
  v
Modified JavaScript Value (tratativa de erros)
  |
  v
Filter rows
  |                         \
  |                          \
  v                           v
saida_tb_pessoa              saida_etl_pessoas_erros
  |                           |
  v                           v
Add constants                Add constants
  |                           |
  v                           v
Get system info              Get system info
  |                           |
  v                           v
Get variables                Get variables
  |                           |
  v                           v
Select values                Select values
  |                           |
  v                           v
Insert / Update pessoa       Insert erro
  |                           |
  v                           v
Update stg_pessoas           Update stg_pessoas
SQL principal do tratamento

O Table input principal do tratamento foi estruturado para já identificar o caso em que um mesmo CPF aparece associado a nomes diferentes, evitando uso de Merge Join e evitando duplicidade de linhas na tabela de erros.

select
    p.id_staging,
    p.nome,
    p.cpf,
    p.data_nascimento,
    p.email,
    p.telefone,
    p.sexo,
    p.orgao,
    p.matricula,
    p.cargo,
    p.data_admissao,
    p.cpf_duplicado,
    p.matricula_duplicada,
    case
        when p.cpf in (
            select cpf
            from public.stg_pessoas
            group by cpf
            having count(distinct nome) > 1
        ) then 'S'
        else null
    end as cpf_pessoas_diferentes
from public.stg_pessoas p
where dt_processamento is null
order by p.id_staging;
Regras de validação aplicadas

As regras implementadas no step tratativa de erros são:

CPF obrigatório
email inválido
órgão obrigatório
data de admissão menor que data de nascimento
CPF existente para mais de uma pessoa
CPF duplicado
matrícula duplicada
JavaScript de validação
var motivo_erro = null;

if (cpf == null || String(cpf).trim() == "") {
  motivo_erro = "CPF obrigatorio";
} else if (email == null || String(email).indexOf("@") < 0) {
  motivo_erro = "Email invalido";
} else if (orgao == null || String(orgao).trim() == "") {
  motivo_erro = "Orgao obrigatorio";
} else if (data_admissao != null && data_nascimento != null && data_admissao.before(data_nascimento)) {
  motivo_erro = "Data admissao menor que data nascimento";
} else if (cpf_pessoas_diferentes != null) {
  motivo_erro = "CPF existente para mais de uma pessoa";
} else if (cpf_duplicado != null) {
  motivo_erro = "CPF duplicado";
} else if (matricula_duplicada != null) {
  motivo_erro = "Matricula duplicada";
}
Observação importante

A regra CPF existente para mais de uma pessoa foi posicionada antes de CPF duplicado, para garantir prioridade da validação mais específica.

Encaminhamento dos registros
Registros válidos

Quando motivo_erro IS NULL, o registro segue para a tabela final de pessoas.

Além disso, a staging é atualizada com:

status_processamento = PROCESSADO
dt_processamento
id_execucao
Registros inválidos

Quando motivo_erro IS NOT NULL, o registro segue para a tabela de erros.

Além disso, a staging é atualizada com:

status_processamento = ERRO
dt_processamento
motivo_erro_processamento
id_execucao
Transformação 03 - Métricas de execução

Essa transformação consolida os dados da execução e grava um resumo em tabela de métricas.

Objetivo
consolidar indicadores da última execução
registrar totais processados, válidos, inválidos e pendentes
registrar data/hora de início e fim
registrar status da execução
Conceito das métricas
qtd_processados_execucao: total de registros que passaram pelo fluxo de tratamento naquela execução
qtd_validos_execucao: total de registros classificados como válidos naquela execução
qtd_invalidos_execucao: total de registros classificados como inválidos naquela execução
qtd_validos_total: total acumulado de registros válidos
qtd_invalidos_total: total acumulado de registros inválidos
Estrutura de dados
Tabelas principais
public.stg_pessoas

Tabela de staging que recebe a carga inicial dos arquivos CSV.

Campos principais:

id_staging
nome
cpf
data_nascimento
email
telefone
sexo
orgao
matricula
cargo
data_admissao
status_processamento
dt_processamento
motivo_erro_processamento
id_execucao
public.tb_pessoas

Tabela final com os registros válidos processados.

public.etl_pessoas_erros

Tabela destinada ao armazenamento dos registros inválidos e seus respectivos motivos de erro.

public.etl_metricas_execucao

Tabela com o resumo de cada execução do processo.

Consultas de apoio e validação
1. Consulta para verificar registros válidos na tabela final
select *
from public.tb_pessoas
order by cpf;
2. Consulta para verificar registros inválidos na tabela de erros
select *
from public.etl_pessoas_erros
order by dt_erro desc;
3. Consulta para verificar a staging após o processamento
select
    id_staging,
    nome,
    cpf,
    status_processamento,
    motivo_erro_processamento,
    dt_processamento,
    id_execucao
from public.stg_pessoas
order by id_staging;
4. Consulta para verificar totais por status na staging
select
    status_processamento,
    count(*) as quantidade
from public.stg_pessoas
group by status_processamento
order by status_processamento;
5. Consulta para verificar motivos de erro
select
    motivo_erro,
    count(*) as quantidade
from public.etl_pessoas_erros
group by motivo_erro
order by quantidade desc;
6. Consulta para verificar CPFs associados a mais de um nome
select
    cpf
from public.stg_pessoas
group by cpf
having count(distinct nome) > 1
order by cpf;
7. Consulta para verificar métricas da execução
select *
from public.etl_metricas_execucao
order by dt_inicio desc;
8. Consulta para verificar resumo das últimas execuções
select
    id_execucao,
    nome_processo,
    dt_inicio,
    dt_fim,
    qtd_processados_execucao,
    qtd_validos_execucao,
    qtd_invalidos_execucao,
    qtd_validos_total,
    qtd_invalidos_total,
    status_execucao,
    mensagem_erro
from public.etl_metricas_execucao
order by dt_inicio desc;
Estratégia de processamento

A estratégia adotada foi dividida em camadas:

1. Ingestão

Os dados são lidos de arquivos CSV e carregados para a staging.

2. Validação

Os registros são submetidos às regras de negócio e integridade.

3. Separação

Os registros são encaminhados para tabela final ou tabela de erros.

4. Rastreamento

A staging é atualizada com status, data de processamento, motivo de erro e identificador da execução.

5. Monitoramento

Ao final, as métricas da execução são consolidadas e gravadas em tabela específica.

Teste de volume realizado

Foi gerada uma carga de teste com 10.000 registros contendo casos válidos e inválidos.

Resultado obtido na primeira execução
10.000 registros processados
7.300 registros válidos
2.700 registros inválidos

Os registros inválidos foram encaminhados para a tabela de erros com o respectivo motivo de rejeição, e os válidos foram encaminhados para a tabela final de pessoas.

Também foram registradas métricas da execução, possibilitando rastreamento e monitoramento do processo.

Comportamento em nova leitura do mesmo arquivo

Ao recolocar o arquivo na pasta de entrada, o processo executou nova carga, passando novamente pela staging e pelo fluxo de tratamento.

Nesse cenário:

os registros válidos já existentes na tabela final não geraram crescimento adicional na carga válida
os registros que permaneceram inconsistentes voltaram a ser classificados como inválidos
as métricas registraram a nova execução separadamente

Esse comportamento demonstra que a execução é rastreada por id_execucao e que as métricas refletem o que foi tratado em cada rodada.

Pontos de destaque da solução
uso de staging para desacoplamento entre entrada e tratamento
separação clara entre registros válidos e inválidos
rastreabilidade por id_execucao
atualização de status na staging
persistência de motivo do erro
geração de métricas de execução
identificação de CPF associado a pessoas diferentes
movimentação de arquivos processados para pasta de histórico
organização do fluxo em job principal e transformações auxiliares
Melhorias futuras

Como evolução da solução, podem ser adicionados:

controle de arquivos já processados
tabela de controle por nome de arquivo
validação por hash do arquivo
reprocessamento controlado de registros com erro
exportação automatizada de relatório de erros
dashboard de monitoramento das métricas
Tecnologias utilizadas
Pentaho Data Integration (PDI)
PostgreSQL
arquivos CSV
Estrutura resumida da solução
Job principal
├── 00_gera_id_execucao
├── 01_captura_staging_pessoas
├── Move files para processados
├── 02_tratamento_pessoas
└── 03_metricas_execucao
## Autor

Aline Souza  
Projeto desenvolvido como solução de teste prático para processo ETL de pessoas com tratamento, validação, monitoramento e rastreabilidade.