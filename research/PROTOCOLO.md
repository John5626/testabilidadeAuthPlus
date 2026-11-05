> Cópia anonimizada para avaliação. Hashes e congelamento citados pertencem aos originais privados; os bytes desta exportação são identificados em SHA256SUMS.

# Protocolo congelado â€” avaliaÃ§Ã£o da testabilidade do frontend

Congelamento: 31/10/2026, antes da execuÃ§Ã£o da coleta descrita neste documento.

## RevisÃ£o e unidade de anÃ¡lise

- RepositÃ³rio: `frontend/`.
- RevisÃ£o-base: `ANONYMIZED_BASE_REVISION`.
- Unidade de anÃ¡lise: transiÃ§Ã£o de estado observÃ¡vel em uma jornada de autenticaÃ§Ã£o.
- Requisitos-orÃ¡culo: US-04, US-05 e `Docs/product/identity-jornadas.md`.
- Dados: exclusivamente sintÃ©ticos; nenhuma credencial, token ou PII real.

## QuestÃµes de pesquisa

- **QP1:** quais cenÃ¡rios selecionados podem ser exercitados sem backend, armazenamento seguro real ou dispositivo fÃ­sico, e quais substituiÃ§Ãµes sÃ£o necessÃ¡rias?
- **QP2:** quais transiÃ§Ãµes e falhas dirigidas sÃ£o detectadas pela suÃ­te existente e pela suÃ­te ampliada?
- **QP3:** quais componentes sÃ£o afetados ao acrescentar as verificaÃ§Ãµes que faltavam e ao corrigir eventual nÃ£o conformidade assÃ­ncrona? QP3 Ã© apenas descritiva.

## CenÃ¡rios e orÃ¡culos fixados

| ID | PrÃ©-condiÃ§Ã£o/estÃ­mulo | OrÃ¡culo observÃ¡vel | DependÃªncias substituÃ­das |
|---|---|---|---|
| C1 | Login retorna sessÃ£o `ACCESS` e a consulta do workspace termina com sucesso | workspace somente apÃ³s a consulta; sessÃ£o persistida; challenge ausente | autenticaÃ§Ã£o, workspace e armazenamento |
| C2 | Login retorna challenge de polÃ­ticas | estado `policyOnboarding`; sem workspace ou sessÃ£o; challenge apenas em memÃ³ria | autenticaÃ§Ã£o, polÃ­ticas, workspace e armazenamento |
| C3 | Login retorna MFA; verificaÃ§Ã£o Ã© rejeitada | estado continua `mfaChallenge`; sem workspace ou sessÃ£o; challenge preservado | autenticaÃ§Ã£o, workspace e armazenamento |
| C4 | armazenamento contÃ©m sessÃ£o expirada | sessÃ£o removida e estado `login`; workspace nÃ£o Ã© consultado | relÃ³gio pela data sintÃ©tica, workspace e armazenamento |
| C5 | login ou carregamento do workspace falha | operaÃ§Ã£o nÃ£o Ã© sucesso; sessÃ£o nÃ£o permanece ativa; workspace nÃ£o Ã© liberado | autenticaÃ§Ã£o, workspace e armazenamento |
| C6 | login estÃ¡ pendente, usuÃ¡rio abandona o fluxo e a resposta chega depois | resposta obsoleta nÃ£o muda o destino escolhido nem cria sessÃ£o | autenticaÃ§Ã£o assÃ­ncrona, workspace e armazenamento |

SÃ£o previstas 12 transiÃ§Ãµes/efeitos verificÃ¡veis: duas por cenÃ¡rio, escolhidas antes da coleta: destino final e presenÃ§a/ausÃªncia do estado de seguranÃ§a correspondente (sessÃ£o/challenge/workspace ou chamada externa).

## SuÃ­tes

- **Existente:** testes de autenticaÃ§Ã£o jÃ¡ presentes em `studyapp_flow_controller_test.dart`, sem alteraÃ§Ã£o.
- **Ampliada estÃ¡vel:** testes adicionais para C4 e para a falha de carregamento do workspace em C5; deve passar na revisÃ£o-base para participar da campanha de falhas.
- **Conformidade C6:** teste separado. Se falhar na revisÃ£o-base, a falha serÃ¡ registrada como nÃ£o conformidade observada, nÃ£o como variante injetada. A campanha nÃ£o o usarÃ¡ atÃ© que exista uma base corrigida.

## Campanha dirigida de falhas

Cada variante altera uma condiÃ§Ã£o por vez em cÃ³pia isolada da revisÃ£o-base. A variante precisa compilar e o teste nominal da revisÃ£o-base precisa passar antes de ser considerada elegÃ­vel. Erro de compilaÃ§Ã£o, alteraÃ§Ã£o equivalente ou execuÃ§Ã£o inconclusiva serÃ¡ excluÃ­do, com justificativa.

| ID | Falha introduzida | Resultado incorreto esperado | Teste previsto para detectar |
|---|---|---|---|
| F1 | challenge de polÃ­ticas encaminha ao workspace | acesso antes do aceite | existente C2 |
| F2 | challenge de MFA encaminha ao workspace | acesso antes do segundo fator | existente C3 |
| F3 | sessÃ£o recusada na retomada encaminha ao workspace | acesso com sessÃ£o invÃ¡lida | existente retomada invÃ¡lida |
| F4 | falha ao carregar workspace nÃ£o remove a sessÃ£o iniciada | credencial permanece ativa apÃ³s falha | ampliada C5 |
| F5 | verificaÃ§Ã£o de expiraÃ§Ã£o local Ã© ignorada | sessÃ£o expirada nÃ£o Ã© removida antes da consulta | ampliada C4 |

O conjunto Ã© dirigido e nÃ£o pretende representar todos os defeitos possÃ­veis.

## Indicadores e regras de anÃ¡lise

- Isolamento: cenÃ¡rios executados sem infraestrutura externa / 6 selecionados.
- Cobertura da matriz: transiÃ§Ãµes/efeitos com asserÃ§Ã£o executada / 12 previstos.
- DetecÃ§Ã£o: variantes detectadas / variantes vÃ¡lidas e nÃ£o equivalentes.
- Uma variante Ã© detectada somente quando uma asserÃ§Ã£o falha; falha de compilaÃ§Ã£o nÃ£o conta.
- Para a comparaÃ§Ã£o entre suÃ­tes, ambas executam as mesmas variantes elegÃ­veis.
- QP3 registra arquivos e responsabilidades afetadas; nÃ£o usa linhas modificadas como proxy de produtividade.
- A anÃ¡lise Ã© descritiva, com nÃºmeros absolutos e denominadores; nÃ£o haverÃ¡ teste de hipÃ³tese para cinco variantes dirigidas.

## Reprodutibilidade

Comandos, versÃµes, saÃ­das brutas, fontes das variantes e tabela derivada serÃ£o preservados em `research/evidencias/` e `research/analise/`. Todos os nÃºmeros do manuscrito devem ser produzidos por script a partir dos registros brutos.

## Adendo pÃ³s-coleta: correÃ§Ã£o C6

A execuÃ§Ã£o inicial confirmou a nÃ£o conformidade prevista como possibilidade no protocolo. Sem alterar os orÃ¡culos, C6 foi corrigido com uma guarda de geraÃ§Ã£o e reexecutado. A suÃ­te ampliada passou a conter 20 testes, a matriz atingiu 12/12 efeitos conformes e a campanha F1--F5 foi repetida na revisÃ£o corrigida. O resultado anterior permanece preservado em `evidencias/conformidade_c6/resultado.json`.

