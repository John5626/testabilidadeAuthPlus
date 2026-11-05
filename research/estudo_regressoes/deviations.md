# Desvios e decisões pós-congelamento

O protocolo em `protocol.md` permanece inalterado. Este arquivo registra eventos pós-congelamento, decisões, impacto e repetição/exclusão aplicável.

## 2026-11-03 — N3 inválida por nulabilidade após transformação literal

- **Momento:** primeira repetição N3 × S2, depois de N1 e N2 concluídas e restauradas.
- **Transformação aplicada:** remoção literal de `_ensureChallengeIsUsable(challenge!)`, exatamente como congelada.
- **Evento:** a remoção também eliminou a promoção de nulabilidade usada pelo compilador. `challenge.challengeToken` deixou de compilar porque `challenge` manteve o tipo `AuthenticationChallenge?`.
- **Evidência:** `runs/variants/p1p3-20261103/logs/n3-s2-r1.txt`, diff `runs/variants/p1p3-20261103/diffs/N3.patch`, código de saída 1 e classificação `invalid_variant` em `variant-runs.csv`.
- **Critério aplicado:** falha de compilação não conta como detecção. N3 é inválida, fica excluída dos denominadores analisados e não será substituída.
- **Decisão do coordenador:** opção A — preservar a transformação e o resultado, sem inserir uma promoção nula mecânica depois de conhecido o resultado.
- **Restauração:** o alvo foi restaurado pelo bloco `finally`; o controlador retornou ao SHA-256 nominal `9FC348BE0D4378DBED99ACA7F67AE5029AC8FB4E9215C0FBC45311BB88435607`.
- **Retomada:** executar S2 integral pós-N3 e confirmar hashes. Somente em caso de 27/27 e hashes nominais, retomar N4--N8. N1/N2 permanecem como coletadas.

## 2026-11-03 — revisão da classificação N5 × S0, repetição 1

- **Momento:** primeira repetição de N5 × S0, após N4 concluída e restaurada.
- **Evento:** o classificador automático esperava apenas o título do cenário W1 e não reconheceu quatro falhas de asserção em fluxos históricos. A execução foi inicialmente marcada `inconclusive_unmatched_failure` e a campanha parou antes de N6.
- **Inspeção causal:** a remoção de `_busy = false` mantém o controlador ocupado; as asserções falharam em consequências diretas desse estado permanente: operações posteriores retornaram `false`, a mensagem de MFA não foi produzida e a versão de política não foi recarregada. Não houve erro de ferramenta ou infraestrutura.
- **Decisão do coordenador:** reclassificar a execução preservada como `detected_assertion`, sem reexecutá-la, sem alterar teste/oráculo e sem excluir N5. A previsão prévia `applicable_path_no_oracle` para S0/S1 estava errada e será relatada como previsão refutada pelos dados.
- **Ajuste permitido:** somente o classificador passou a reconhecer os títulos das asserções funcionais relevantes. O log bruto e o resultado original permanecem preservados.
- **Retomada:** confirmar S2 nominal e hashes; continuar N5 × S0 nas repetições 2 e 3, depois S1/S2 e N6--N8.

## 2026-11-03 — erro de mediana no pós-processamento

- **Momento:** depois da coleta e restauração completas de N1--N8.
- **Evento:** o agregador assumia três observações por grupo e acessava o índice 1. N3 possui corretamente apenas uma observação, pois foi classificada inválida na primeira compilação; o cálculo lançou erro de índice.
- **Impacto:** nenhum teste, log, diff, código de saída ou restauração foi perdido. Os 12 cruzamentos planejados estavam preservados; todos os cruzamentos válidos possuíam três repetições e N3 possuía uma execução inválida.
- **Correção:** cálculo geral de mediana para `n` ímpar/par e script separado `summarize-variants.ps1`, que regenera somente CSV/JSON a partir dos registros brutos. Nenhuma variante foi reexecutada.

## 2026-11-03 — revisão do gate para N6

- **Momento:** gate simulado N6, após formato, análise, S1, S2 e manifesto completos.
- **Evento:** a análise estática retornou dois avisos `dead_code`, consequência direta da transformação congelada `if (false && widget.errorMessage != null)`. O classificador tratou inicialmente qualquer saída não reconhecida do analisador como infraestrutura e marcou o gate inconclusivo.
- **Resultado observado:** formatação passou; análise falhou por qualidade da própria variante; S1 passou 22/22; S2 falhou pela asserção relevante de W1; manifesto foi criado e validado.
- **Decisão do coordenador:** N6 é `blocked`, pois S2 detectou a violação. Os avisos permanecem registrados como `quality_failure`, nunca como infraestrutura. A execução N6 não será repetida.
- **Retomada:** preservar CSV/manifesto anteriores à revisão, confirmar restauração/hash e executar somente N7--N8.

