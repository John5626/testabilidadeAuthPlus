# Resultados observados — P1/P3

Data da coleta: 03/11/2026. Este documento consolida somente resultados executados. O protocolo congelado não foi alterado e o manuscrito não foi editado nesta etapa.

## Comportamento nominal e custo

Cada estratégia teve uma execução de aquecimento não contabilizada e dez repetições medidas. A ordem por rodada seguiu a rotação congelada S0→S1→S2, S1→S2→S0 e S2→S0→S1.

| Estratégia | Composição | n medido | Mediana (ms) | Mínimo (ms) | Máximo (ms) | Resultados fora do modal |
|---|---:|---:|---:|---:|---:|---:|
| S0 | 17 testes | 10 | 9.298 | 9.218 | 9.425 | 0 |
| S1 | 22 testes | 10 | 9.327,5 | 9.206 | 9.411 | 0 |
| S2 | 27 testes | 10 | 9.345 | 9.261 | 9.565 | 0 |

Todas as 33 execuções nominais, incluindo os aquecimentos, foram aprovadas com a contagem esperada. As durações são de processo externo completo no executor local e incluem inicialização da ferramenta; não são usadas para teste de significância.

## Variantes N1--N8

Foram executados somente os cruzamentos aplicáveis. Cada cruzamento válido teve três repetições consecutivas. N3 parou na primeira compilação por invalidade e não foi repetida nem substituída.

| Variante | S0 | S1 | S2 | Situação |
|---|---|---|---|---|
| N1 | N/A | N/A | detectada 3/3 | válida |
| N2 | N/A | N/A | detectada 3/3 | válida |
| N3 | N/A | N/A | compilação inválida 1/1 | inválida e excluída |
| N4 | detectada 3/3 | detectada 3/3 | detectada 3/3 | válida |
| N5 | detectada 3/3 | detectada 3/3 | detectada 3/3 | válida; previsão prévia de ausência de oráculo refutada |
| N6 | N/A | N/A | detectada 3/3 | válida |
| N7 | N/A | N/A | detectada 3/3 | válida |
| N8 | N/A | N/A | detectada 3/3 | válida |

Os denominadores planejados eram S0=2, S1=2 e S2=8. Depois da exclusão documentada de N3, os denominadores analisados foram S0=2, S1=2 e S2=7. As taxas observadas de detecção estável foram:

- S0: 2/2 variantes válidas aplicáveis;
- S1: 2/2 variantes válidas aplicáveis;
- S2: 7/7 variantes válidas aplicáveis;
- ganho incremental de S2 sobre S1: cinco variantes válidas — N1, N2, N6, N7 e N8.

N5 revelou que a previsão `applicable_path_no_oracle` estava errada: manter `busy` permanentemente produziu falhas de asserção funcionais nos fluxos históricos. A primeira execução foi preservada e reclassificada após inspeção causal; nenhum teste ou oráculo foi alterado.

N3 foi inválida porque a remoção literal de `_ensureChallengeIsUsable(challenge!)` eliminou também a promoção de nulabilidade usada na referência subsequente a `challenge.challengeToken`. O erro de compilação não foi contado como detecção. A transformação congelada não foi adaptada depois do resultado.

Após cada variante, o arquivo foi restaurado por bytes, o SHA-256 foi comparado e S2 nominal foi executada. As oito restaurações retornaram ao hash esperado e aprovaram 27/27 testes.

## Quality gate simulado

O gate local executou formatação, análise estática, S1, S2 e validação de manifesto para cada variante, sem deploy.

| Variante | Formato | Análise | S1 | S2 | Artefato | Gate |
|---|---|---|---|---|---|---|
| N1 | passa | passa | sobrevive | detecta | passa | bloqueada |
| N2 | passa | passa | sobrevive | detecta | passa | bloqueada |
| N3 | passa | variante inválida | variante inválida | variante inválida | passa | inconclusiva — variante inválida |
| N4 | passa | passa | detecta | detecta | passa | bloqueada |
| N5 | passa | passa | detecta | detecta | passa | bloqueada |
| N6 | passa | falha de qualidade (`dead_code`) | sobrevive | detecta | passa | bloqueada |
| N7 | falha de qualidade | passa | sobrevive | detecta | passa | bloqueada |
| N8 | passa | passa | sobrevive | detecta | passa | bloqueada |

O gate bloqueou 7/7 variantes válidas por falha de asserção relevante. N3 permaneceu inconclusiva e fora do denominador por não compilar. N6 e N7 também acionaram verificações estáticas, mas sua classificação como bloqueadas decorre da detecção relevante de S2, conforme o critério congelado.

O workflow `frontend/.github/workflows/cotb-regression-gate.yml` materializa jobs obrigatórios separados para qualidade, S1, S2, artefatos e gate. Ele não contém promoção ou deploy.

## Desvios e correções de infraestrutura

Os eventos completos estão em `deviations.md`:

1. N3 inválida foi preservada e excluída sem substituição;
2. a primeira execução N5 × S0 foi inicialmente não reconhecida pelo classificador; a revisão causal a classificou como detecção por asserção, preservando o log original;
3. o agregador de mediana assumiu incorretamente três registros para N3; o resumo foi regenerado do CSV bruto sem repetir variantes;
4. avisos `dead_code` de N6 foram inicialmente tratados como infraestrutura; foram corrigidos para `quality_failure`, mantendo a detecção S2 e sem repetir N6.

Não houve falha nominal, divergência de hash após restauração ou erro persistente de infraestrutura na coleta final.

## Validação final e rastreabilidade

Após o último gate e a última restauração:

- S2 nominal: 27/27, código 0;
- `flutter analyze --no-pub`: código 0;
- formatação de `lib` e `test`: código 0, nenhuma alteração;
- `git diff --check`: código 0;
- controlador: SHA-256 `9FC348BE0D4378DBED99ACA7F67AE5029AC8FB4E9215C0FBC45311BB88435607`;
- `login_view.dart`: SHA-256 `3E8B60A65B66A69CB758F47696B6CB8FB7A2043E414638804515C9BB0F7168C8`;
- `studyapp_root_view.dart`: SHA-256 `B16DAEA9F507CFD7C636CD2EBE6530F4E15EA0348EE372E00FE783D79B2DE879`;
- teste S2: SHA-256 `C681AFA9F140FA25C993C488D90A3C7AFE17416E9B5427019299F958E2096473`.

Arquivos consolidados e hashes SHA-256:

- `runs/nominal/p1p3-20261103/nominal-runs.csv`: `E403E94A1D8C2D1EF7C5E9D6333BDFB9499778A89C5479A7FC6D4D2079694487`;
- `runs/nominal/p1p3-20261103/nominal-summary.csv`: `2AB80F43BD456808F68082BB8BFDC8D7F8674769883A8BB6606E947C3D23C5CE`;
- `runs/variants/p1p3-20261103/variant-runs.csv`: `6B946FEFAC515C2541A4BD261350F8B90052DA930015CCB2634ABC6F41BA63AA`;
- `runs/variants/p1p3-20261103/variant-summary.csv`: `BCC0D2E88C0B8A46B327B5EE6A80360D1F9A1D4FCDAC997621DB98395D016C6F`;
- `runs/variants/p1p3-20261103/restorations.csv`: `D7EF26148B20AE6783B36CC29B9AC334D8DD51C240ADB40D666036E33DC066B0`;
- `runs/gate/p1p3-20261103/gate-results.csv`: `63C54E0B60A38D8AFD15ACED168BCE124CB7AC5B2479BC697837C3D2C8EB365B`;
- `runs/validation/p1p3-20261103/validation.json`: `2F78CF2635CBF89AFCD196B81877D81808F0B2CCAF96191513FD12701EA58052`.

Os diretórios de execução preservam logs individuais, códigos de saída, durações, patches N1--N8, fontes nominais usadas para restauração e manifestos do gate. Os CSV e JSON anteriores às duas revisões de classificação também foram preservados.

