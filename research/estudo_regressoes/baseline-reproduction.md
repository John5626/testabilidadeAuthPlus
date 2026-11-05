# Reprodução da linha de base (P0)

Data da reprodução: 03/11/2026. Este relatório registra somente resultados observados. Ele congela a linha histórica antes do pré-registro e da execução do novo conjunto de variantes.

## Identidade e composição

- **Revisão histórica:** `ANONYMIZED_BASE_REVISION`, tag `ANONYMIZED_BASE_TAG` no repositório `frontend/`.
- **S0 — baseline histórica:** `test/studyapp_flow_controller_test.dart`, 17 testes da revisão limpa `ANONYMIZED_BASE_REVISION`.
- **S1 — controlador ampliado:** S0 + dois testes C4--C5 em `test/cotb_authentication_testability_test.dart` + três testes C6a--C6c em `test/cotb_obsolete_response_conformance_test.dart`, totalizando 22 testes.
- **Identidade correta de S1:** `ANONYMIZED_BASE_REVISION` + patch local da correção C6 + testes locais C4--C6. A correção e os testes não pertencem ao commit `ANONYMIZED_BASE_REVISION` e não possuem commit próprio.

O controlador nominal de `ANONYMIZED_BASE_REVISION` é o blob Git `a61bc30f79fb4b86b83587fa4ec457797c8b1eb0`. O controlador corrigido é o blob calculado `da5c4e3b569322e949554ddd87ab4d61b96fb0f6`, SHA-256 `f699e82d3907e02d12fb13bc50cd0c69962e52a720a558bcc8f51433102301e7`. A campanha confirmou o mesmo SHA-256 antes e depois das variantes, evidenciando restauração byte a byte.

## Ambiente e comandos

Ambiente observado: Windows NT `10.0.26300.0`, PowerShell `7.6.5`, Git `2.56.0.windows.1`, Flutter `3.47.0` stable (`4cf2416426`) e Dart `3.13.0`.

```powershell
# S0, worktree limpo em ANONYMIZED_BASE_REVISION
flutter test --no-pub test/studyapp_flow_controller_test.dart --reporter expanded

# S1, worktree em ANONYMIZED_BASE_REVISION com patch/testes locais
flutter test --no-pub test/studyapp_flow_controller_test.dart test/cotb_authentication_testability_test.dart test/cotb_obsolete_response_conformance_test.dart --reporter expanded
```

A campanha F1--F8 foi executada com cópia em memória de `../experimento/executar_mutacoes.ps1`; somente o diretório de saída foi redirecionado, preservando o script e os logs anteriores.

## Resultados reproduzidos

| Verificação | Resultado observado | Duração desta reprodução |
|---|---:|---:|
| S0 nominal | 17/17 aprovados; código 0 | 32.690 ms |
| S1 nominal | 22/22 aprovados; código 0 | 10.761 ms |
| F1--F8 em S0 | F1--F3 detectadas; F4--F8 sobreviveram: 3/8 | incluída na campanha |
| F1--F8 em S1 | F1--F8 detectadas por asserção: 8/8 | incluída na campanha |
| Campanha completa | 16 execuções; classificações coincidentes com o relato anterior | 160.357 ms |

O código externo da campanha foi `1` porque a última execução terminou com a falha de asserção esperada da variante F8; os registros por variante separam códigos de saída, sobrevivência e detecção por asserção. Não foi observado erro de infraestrutura na campanha reproduzida.

As durações acima documentam esta reprodução, mas **não são uma comparação de custo entre S0 e S1**: houve apenas uma execução por suíte, S0 foi uma execução fria e S1 ocorreu com ambiente aquecido/cacheado. Elas não devem alimentar QP3 sem repetições controladas posteriores.

## Evidências preservadas

- S0 nominal: [`../evidencias/p0-reproducao/bruto/base-ANONYMIZED_BASE_REVISION-s0.txt`](../evidencias/p0-reproducao/bruto/base-ANONYMIZED_BASE_REVISION-s0.txt)
- S1 nominal: [`../evidencias/p0-reproducao/bruto/corrected-ANONYMIZED_BASE_REVISION-s1.txt`](../evidencias/p0-reproducao/bruto/corrected-ANONYMIZED_BASE_REVISION-s1.txt)
- Resultado estruturado da campanha: [`../evidencias/p0-reproducao/bruto/campanha-f1-f8.json.txt`](../evidencias/p0-reproducao/bruto/campanha-f1-f8.json.txt)
- Logs individuais F1--F8 × S0/S1: [`../evidencias/p0-reproducao/bruto/mutacoes/`](../evidencias/p0-reproducao/bruto/mutacoes/)
- Resolução de dependências: [`../evidencias/p0-reproducao/bruto/base-ANONYMIZED_BASE_REVISION-pub-get.txt`](../evidencias/p0-reproducao/bruto/base-ANONYMIZED_BASE_REVISION-pub-get.txt)
- Diff do lockfile: [`../evidencias/p0-reproducao/dependency-resolution-drift.patch`](../evidencias/p0-reproducao/dependency-resolution-drift.patch)
- Logs históricos preservados: [`../evidencias/mutacoes/bruto/`](../evidencias/mutacoes/bruto/)

Checksums SHA-256 dos registros principais:

| Arquivo | SHA-256 |
|---|---|
| `base-ANONYMIZED_BASE_REVISION-s0.txt` | `8c04635976f4d1670182aa157fbd27b74f26d656f63a99430337575133de10ef` |
| `corrected-ANONYMIZED_BASE_REVISION-s1.txt` | `db4084d36d1ecc0edd81827b0603fa5ca1ddc6c67705376bb9f2eb603d321c4c` |
| `campanha-f1-f8.json.txt` | `216d9071a0759eb591b72df3ee474b89f52354c47c464ee0828d252a9a6eb116` |
| `dependency-resolution-drift.patch` | `4a5cdc9b440b23b391d37a4157fcc772918b68abad96b755071a0c8b6a507c4c` |

## Lockfile e equivalência ambiental

`flutter pub get` com Flutter 3.47.0 alterou temporariamente quatro dependências transitivas: `matcher` 0.12.19→0.12.20, `meta` 1.18.0→1.19.0, `test_api` 0.7.11→0.7.12 e `vector_math` 2.2.0→2.4.4. O patch registra a passagem do blob Git abreviado `98db85b` para `4098208`. O lockfile do worktree limpo foi restaurado após a coleta, mas os testes usaram a resolução atual presente em `.dart_tool`.

Assim, a reprodução confirma o comportamento do código `ANONYMIZED_BASE_REVISION` no ambiente de 03/11/2026; ela não é uma reconstrução bit a bit do ambiente de 31/10/2026. O worktree S1 já possuía o lockfile modificado antes desta auditoria e foi preservado para não descartar estado preexistente.

## Cronologia 19→20→22

Os totais distintos pertencem a etapas diferentes e não devem ser fundidos:

1. **19 testes:** 17 históricos + C4 + C5, antes da incorporação de C6 à suíte ampliada.
2. **20 testes:** etapa corretiva inicial, com um teste agregado de conformidade C6 após a correção.
3. **22 testes:** aprofundamento final, que substituiu o teste agregado pela decomposição C6a, C6b e C6c.

O registro intermediário permanece em [`../evidencias/conformidade_c6/resultado.json`](../evidencias/conformidade_c6/resultado.json). Para o estudo de regressões, S0 tem 17 testes e S1 tem 22; os valores 19 e 20 são evidência histórica, não estratégias adicionais.

## Divergências e limitações da linha de base

- S1 depende de patch e arquivos locais ainda sem commit; por isso, não pode ser identificada apenas por `ANONYMIZED_BASE_REVISION`.
- O script consolidado F1--F8 pressupõe a correção C6 já aplicada e não reproduz a campanha aprofundada em uma cópia pura de `ANONYMIZED_BASE_REVISION`.
- A resolução de dependências difere da registrada no lockfile histórico, conforme o patch preservado.
- O worktree corrigido possui ponteiro `.git` absoluto e não constitui pacote portátil isolado.
- A variante equivalente F4a continua documentada no resultado histórico, mas não possui diff/log bruto preservado; ela permanece fora do denominador.
- Os artefatos do artigo e da campanha ainda dependem de caminhos e hashes porque o repositório `research/` não possui revisão Git publicada.

## Conclusão P0

P0 foi **reproduzida com ressalvas documentadas**: S0 confirmou 17/17, S1 confirmou 22/22, e a campanha repetiu 3/8 versus 8/8 com logs e códigos de saída por cruzamento. Nenhum número histórico foi alterado. A linha de base adequada para as próximas etapas é S0=`ANONYMIZED_BASE_REVISION` e S1=`ANONYMIZED_BASE_REVISION` + patch C6 + testes C4--C6, com a deriva ambiental explicitada. O novo conjunto de variantes deve permanecer separado de F1--F8 e somente pode ser executado depois de seu pré-registro.

