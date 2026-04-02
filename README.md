# ETL de Migracao de Pessoas em Pentaho - Versao com Staging Transiente

## Pre-requisitos

Para executar o projeto, e necessario:

- Pentaho Data Integration (PDI / Spoon)
- PostgreSQL instalado e em execucao
- Criacao de um banco para o projeto
- Execucao do script `sql/create_tables.sql` 
- Ajuste manual da conexao de banco nos arquivos `.ktr` e `.kjb`, se necessario

## Objetivo

Implementar uma ETL de migracao de pessoas utilizando Pentaho Data Integration (PDI), contemplando carga em staging, tratamento e validacao de dados, segregacao de erros, metricas de execucao e controle de processamento por registro.

## Arquitetura da solucao

A solucao foi organizada em tres etapas principais:

1. Captura do arquivo CSV para a tabela de staging
2. Tratamento e validacao dos registros
3. Consolidacao de metricas de execucao

### Job principal
- `job_migracao_pessoas_transiente.kjb`

### Transformacoes
- `01_captura_stage_pessoas.ktr`
- `02_tratamento_pessoas.ktr`
- `03_metricas_execucao.ktr`

## Estrategia adotada

Nesta versao, a tabela de staging foi tratada como uma area transiente por lote. Antes de cada nova carga, a staging e reinicializada, permitindo que o lote corrente seja processado do inicio ao fim com isolamento.

Essa abordagem foi adotada para simplificar a execucao da prova de conceito e manter o foco nos requisitos centrais do teste: validacao, rastreabilidade, tratamento de erros, metricas e controle de processamento.

## Estrutura do repositorio

- `jobs/`: job principal da orquestracao
- `transformations/`: transformacoes de carga, tratamento e metricas
- `sql/`: scripts de criacao das tabelas
- `input/`: arquivo CSV de exemplo
- `docs/`: imagens ou evidencias da arquitetura

## Estruturas de dados

### Tabelas principais
- `stg_pessoas`: staging transiente de entrada
- `tb_pessoas`: tabela final com registros validos
- `etl_pessoas_erros`: tabela de rejeicoes com motivo do erro
- `etl_metricas_execucao`: tabela com metricas do processo

### Controle de processamento na staging
A tabela `stg_pessoas` possui colunas de controle para registrar o andamento do tratamento:
- `status_processamento`
- `dt_processamento`
- `motivo_erro_processamento`

Essas colunas permitem rastrear, dentro do lote corrente, quais registros foram processados com sucesso e quais falharam.

## Regras implementadas

### Validacoes de integridade e negocio
- CPF obrigatorio
- Email com formato minimo valido
- Orgao obrigatorio
- Data de admissao maior ou igual a data de nascimento

### Roteamento dos registros
- Registros validos sao enviados para `tb_pessoas`
- Registros invalidos sao enviados para `etl_pessoas_erros`

### Exemplos de motivos de erro
- `CPF obrigatorio`
- `Email invalido`
- `Orgao obrigatorio`
- `Data admissao menor que data nascimento`

## Metricas implementadas

A transformacao de metricas registra:
- nome do processo
- data/hora de inicio
- data/hora de fim
- quantidade de registros lidos
- quantidade de registros validos
- quantidade de registros invalidos
- status da execucao

## Como executar

1. Criar as tabelas executando o script SQL em `sql/create_tables.sql`
2. Ajustar a conexao com o banco PostgreSQL no Pentaho
3. Garantir que o arquivo `input/pessoas.csv` esteja disponivel
4. Executar o job `job_migracao_pessoas_transiente.kjb`

## Resultado esperado

Ao final da execucao:
- a staging recebe os registros do lote corrente
- registros validos sao gravados em `tb_pessoas`
- registros invalidos sao gravados em `etl_pessoas_erros`
- metricas sao gravadas em `etl_metricas_execucao`

## Evidencias de execucao

Na execucao de teste realizada com o arquivo de exemplo:
- 10 registros foram carregados na staging
- 7 registros validos foram gravados em `tb_pessoas`
- 3 registros invalidos foram gravados em `etl_pessoas_erros`
- as metricas foram registradas em `etl_metricas_execucao`
- a staging registrou o status de processamento por linha, incluindo sucesso e erro

## Robustez e retomada

Embora esta versao utilize staging transiente por lote, foi implementado controle de processamento por registro na etapa de tratamento.

Cada linha da `stg_pessoas` recebe:
- status de processamento
- data/hora de processamento
- motivo de erro, quando aplicavel

Com isso, dentro do lote corrente, e possivel identificar quais registros foram processados com sucesso e quais falharam, garantindo rastreabilidade e suporte a retomada da etapa de tratamento sem necessidade de reavaliar manualmente cada linha.

## Limitacoes da versao atual

Esta versao utiliza staging transiente por lote. Isso significa que a camada de entrada e reinicializada a cada nova execucao.

Dessa forma, a retomada implementada nesta versao esta concentrada na etapa de tratamento do lote corrente, e nao em uma persistencia completa da entrada entre multiplas execucoes.

## Evolucoes futuras

- Implementacao de staging persistente
- Controle de arquivo ou lote ja processado
- Deduplicacao de entrada
- Validacao de CPF duplicado
- Mais regras de qualidade de dados
- Retomada completa sem recarga da entrada

## Ajuste de conexao

Por seguranca, a senha da conexao com o banco nao foi armazenada nos arquivos do projeto. Ao executar o fluxo em outro ambiente, e necessario configurar a senha localmente no Pentaho.