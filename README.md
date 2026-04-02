# ETL de Migracao de Pessoas em Pentaho - Versao com Staging Transiente

## Objetivo

Implementar uma ETL de migracao de pessoas utilizando Pentaho Data Integration, contemplando carga em staging, tratamento e validacao de dados, segregacao de erros, metricas de execucao e controle de processamento por registro.

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

## Aderencia aos requisitos do edital

A solucao foi estruturada para atender aos requisitos centrais descritos no teste tecnico:

- **Normalizacao de dados**  
  Implementada na transformacao de tratamento, com tipagem de campos, padronizacao de datas e organizacao dos dados antes da carga final.

- **Integridade de dados**  
  Aplicacao de regras de validacao como CPF obrigatorio, email com formato minimo valido, orgao obrigatorio e consistencia entre data de admissao e data de nascimento.

- **Deteccao de erro com relatorio**  
  Registros invalidos sao direcionados para a tabela `etl_pessoas_erros`, com registro do motivo do erro para rastreabilidade.

- **Padronizacao em formatos**  
  Campos foram tratados para manter consistencia de tipo e formato, especialmente nas colunas de data.

- **Robustez contra erro na execucao**  
  A etapa de tratamento utiliza controle por registro na staging, com as colunas `status_processamento`, `dt_processamento` e `motivo_erro_processamento`, permitindo identificar o andamento do processamento do lote corrente.

- **Metricas de execucao**  
  A transformacao de metricas registra quantidade de registros lidos, validos, invalidos, horario de inicio, horario de fim e status da execucao.

## Contexto da prova de conceito

Esta implementacao foi pensada como uma prova de conceito alinhada ao contexto descrito no enunciado, que envolve migracao de dados em ambiente governamental, com multiplos orgaos, execucoes paralelas e necessidade de controle operacional.

Por se tratar de uma entrega tecnica demonstrativa, a solucao foi mantida enxuta e objetiva, priorizando:
- clareza da arquitetura
- rastreabilidade dos erros
- controle da execucao
- separacao entre staging, tratamento, destino final e metricas

## Como executar

1. Criar as tabelas executando o script SQL em `sql/create_tables.sql`
2. Ajustar a conexao com o banco PostgreSQL no Pentaho
3. Garantir que o arquivo `input/pessoas.csv` esteja disponivel
4. Executar o job `job_migracao_pessoas_transiente.kjb`

## Pre-requisitos

Para executar o projeto, e necessario:

- Pentaho Data Integration (PDI / Spoon)
- PostgreSQL instalado e em execucao
- Criacao previa do banco de dados
- Execucao do script `sql/create_tables.sql`

## Ajustes necessarios no ambiente

Para executar o projeto em outra maquina, pode ser necessario:
- ajustar a conexao com o banco nos arquivos `.ktr` e `.kjb`
- informar a senha da conexao localmente no Pentaho
- reapontar o caminho do arquivo CSV de entrada, caso a estrutura do repositorio seja alterada
- manter a estrutura de pastas do repositorio para reduzir ajustes manuais

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

## Riscos e mitigacoes

### Risco: duplicidade de carga entre execucoes
**Mitigacao:** nesta versao, a staging foi modelada como transiente por lote, com reinicializacao a cada nova carga, evitando acumulacao indevida de registros entre execucoes.

### Risco: registros inconsistentes ou incompletos
**Mitigacao:** validacoes de negocio foram implementadas na etapa de tratamento, com segregacao de registros invalidos em tabela especifica de erros.

### Risco: perda de rastreabilidade sobre falhas
**Mitigacao:** os registros invalidos armazenam o `motivo_erro`, e a staging registra `status_processamento`, `dt_processamento` e `motivo_erro_processamento`.

### Risco: dificuldade de monitorar a execucao
**Mitigacao:** a transformacao de metricas registra quantidade lida, quantidade valida, quantidade invalida, horario de inicio, horario de fim e status do processo.

### Risco: evolucao para cenarios maiores
**Mitigacao:** a arquitetura foi organizada em job principal e transformacoes separadas, facilitando evolucoes futuras, como staging persistente, deduplicacao de entrada e controle de lotes/arquivos processados.

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