> Cópia anonimizada para avaliação. Hashes e congelamento citados pertencem aos originais privados; os bytes desta exportação são identificados em SHA256SUMS.

# Protocolo de aprofundamento â€” C6 e campanha assÃ­ncrona

Congelamento: 31/10/2026, antes da coleta adicional.

## MotivaÃ§Ã£o e vÃ­nculo com o protocolo original

A execuÃ§Ã£o original revelou C6 e a correÃ§Ã£o introduziu uma guarda de geraÃ§Ã£o. A extensÃ£o nÃ£o altera a questÃ£o principal nem o indicador agregado de 12 efeitos: ela decompÃµe internamente os dois efeitos de C6 (destino final e ausÃªncia de estado de seguranÃ§a indevido) em trÃªs pontos de chegada da resposta assÃ­ncrona e acrescenta trÃªs falhas dirigidas definidas antes da nova execuÃ§Ã£o. Os subcenÃ¡rios sÃ£o reportados em uma matriz prÃ³pria, sem serem somados ao denominador de 12 efeitos.

## SubcenÃ¡rios e orÃ¡culos

| ID | Evento tardio | OrÃ¡culo |
|---|---|---|
| C6a | sucesso da autenticaÃ§Ã£o apÃ³s abandono | retorno falso; destino escolhido preservado; sem workspace e sessÃ£o |
| C6b | erro da autenticaÃ§Ã£o apÃ³s abandono | retorno falso; destino escolhido preservado; sem mensagem de erro obsoleta |
| C6c | workspace conclui apÃ³s abandono posterior Ã  autenticaÃ§Ã£o | retorno falso; destino escolhido preservado; sem workspace e sessÃ£o |

## Falhas adicionais

| ID | AlteraÃ§Ã£o semÃ¢ntica dirigida | DetecÃ§Ã£o esperada |
|---|---|---|
| F6 | mudanÃ§a de fluxo nÃ£o invalida o login ativo | C6a |
| F7 | resposta do workspace nÃ£o verifica a geraÃ§Ã£o vigente | C6c |
| F8 | exceÃ§Ã£o do login nÃ£o verifica a geraÃ§Ã£o vigente | C6b |

Cada falha serÃ¡ introduzida individualmente na revisÃ£o corrigida. CompilaÃ§Ã£o invÃ¡lida, equivalÃªncia ou inconclusÃ£o serÃ¡ excluÃ­da com justificativa. A suÃ­te existente permanece com 17 testes; a ampliada incluirÃ¡ todos os testes C4--C6. A anÃ¡lise continuarÃ¡ descritiva, com nÃºmeros absolutos e denominadores; nenhuma inferÃªncia estatÃ­stica serÃ¡ adicionada pela expansÃ£o dirigida.

## Produtos esperados

- matriz C6 antes/depois com trÃªs subcenÃ¡rios;
- campanha consolidada F1--F8;
- figura de comparaÃ§Ã£o das suÃ­tes atualizada por script;
- diagrama de controle/observaÃ§Ã£o das dependÃªncias;
- atualizaÃ§Ã£o do artigo, ameaÃ§as Ã  validade e pacote de evidÃªncias.

