> Cópia anonimizada para avaliação. Hashes e congelamento citados pertencem aos originais privados; os bytes desta exportação são identificados em SHA256SUMS.

# Protocolo prÃ©-registrado â€” detecÃ§Ã£o e contenÃ§Ã£o de regressÃµes

## Congelamento

- Data e hora: `2026-11-03T09:54:41-03:00` (America/Sao_Paulo).
- Estado: **congelado antes da implementaÃ§Ã£o de W1--W4 e da injeÃ§Ã£o de N1--N8**.
- Freeze SHA-256: `5b472d5e9656fd80c8c27d196c1c21a47d69f9e24f7ad97ad02526cb1679088c`.
- CÃ¡lculo: SHA-256 dos bytes UTF-8 de `protocol.md` com o valor desta linha substituÃ­do literalmente por `<FREEZE_SHA256>`, seguidos por LF (`0x0A`) e pelos bytes UTF-8 integrais de `variants.csv`.
- Fontes anteriores ao congelamento: `INSPECAO_VARIANTES.md`, `nominal-persistence-correction.md`, `baseline-reproduction.md` e `Docs/COTB/SOLICITACAO_MELHORIAS_COTB2027.md`.

Este protocolo nÃ£o serÃ¡ reescrito depois da coleta. Qualquer alteraÃ§Ã£o necessÃ¡ria serÃ¡ registrada como desvio datado, com motivo, momento, impacto e decisÃ£o de repetir ou excluir execuÃ§Ãµes, sem apagar a versÃ£o congelada.

## Objetivo e questÃµes de pesquisa

O objetivo Ã© avaliar experimentalmente a capacidade de estratÃ©gias cumulativas de teste para detectar falhas e conter regressÃµes em jornadas de autenticaÃ§Ã£o Flutter, separando capacidade de execuÃ§Ã£o, adequaÃ§Ã£o do orÃ¡culo, custo e comportamento do gate.

- **QP1 â€” DetecÃ§Ã£o:** quais categorias de defeitos sÃ£o detectadas pelos testes do controlador e quais ganhos incrementais surgem com testes de widget e, se posteriormente considerada viÃ¡vel, integraÃ§Ã£o?
- **QP2 â€” LimitaÃ§Ãµes:** quais defeitos de sessÃ£o, navegaÃ§Ã£o, MFA, falha de serviÃ§o e assincronia permanecem nÃ£o detectados em cada estratÃ©gia?
- **QP3 â€” Custo e contenÃ§Ã£o:** qual o tempo de execuÃ§Ã£o e a estabilidade das estratÃ©gias e em que condiÃ§Ãµes o quality gate bloqueia corretamente uma variante defeituosa?

As redaÃ§Ãµes e os critÃ©rios de resposta de QP1--QP3 ficam fixos neste ponto. NÃ£o serÃ£o ajustados retrospectivamente para coincidir com resultados.

## Base nominal

Todas as variantes N1--N8 serÃ£o aplicadas Ã  mesma base nominal:

1. `frontend@ANONYMIZED_BASE_REVISION` (tag `ANONYMIZED_BASE_TAG`);
2. correÃ§Ã£o temporal C6, previamente auditada;
3. correÃ§Ã£o nominal de persistÃªncia, confirmada antes deste prÃ©-registro.

O controlador efetivo dessa base possui SHA-256 `9fc348be0d4378dbed99aca7f67ae5029ac8fb4e9215c0fbc45311bb88435607`. O teste que confirmou a nÃ£o conformidade de persistÃªncia e a correÃ§Ã£o possui SHA-256 `ab8978657f407ac75bd08a9f1aea16783794994bc828f48828491ff3b0d89cd2`; ele Ã© saneamento da base e nÃ£o integra S0 ou S1. A descoberta nominal nÃ£o Ã© variante e nÃ£o entra em qualquer denominador.

Antes de cada campanha, o hash do controlador deve coincidir com a base nominal e S0/S1 devem passar. ApÃ³s cada variante, o arquivo serÃ¡ restaurado e o hash serÃ¡ verificado novamente.

## EstratÃ©gias cumulativas

- **S0 â€” baseline histÃ³rica:** os 17 testes de `test/studyapp_flow_controller_test.dart`, executados sobre a base nominal corrigida.
- **S1 â€” controlador ampliado:** S0 + C4/C5 em `test/cotb_authentication_testability_test.dart` + C6a/C6b/C6c em `test/cotb_obsolete_response_conformance_test.dart`, totalizando 22 testes.
- **S2 â€” S1 + widget:** S1 acrescida dos quatro cenÃ¡rios W1--W4 definidos abaixo. S2 deve usar `StudyAppRootView`, interaÃ§Ã£o real com widgets, dublÃªs determinÃ­sticos e `Completer`/barreiras quando a ordem assÃ­ncrona for relevante; `sleep` arbitrÃ¡rio Ã© proibido.
- **S3 â€” integraÃ§Ã£o:** nÃ£o planejada para a anÃ¡lise principal. SÃ³ poderÃ¡ ser acrescentada apÃ³s decisÃ£o de viabilidade anterior Ã  sua coleta, em adendo separado, com ambiente descartÃ¡vel, dados sintÃ©ticos e denominadores prÃ³prios.
- **P4 â€” serviÃ§os reais:** nÃ£o planejada. Se infraestrutura descartÃ¡vel confiÃ¡vel se tornar disponÃ­vel, serÃ¡ estudo complementar e nÃ£o alterarÃ¡ retrospectivamente S0--S2 ou N1--N8.

### CenÃ¡rios de widget fixados para S2

- **W1 â€” falha de login visÃ­vel e recuperÃ¡vel:** controlar login pendente; observar progresso e botÃ£o desabilitado; concluir com erro; observar progresso removido, mensagem, reabilitaÃ§Ã£o do envio e ausÃªncia de workspace.
- **W2 â€” MFA recusado/expirado e cancelamento coerente:** observar tela MFA; recusa preserva tela/challenge e bloqueia workspace; challenge expirado nÃ£o chama o repositÃ³rio; cancelar apresenta login, nÃ£o landing/workspace.
- **W3 â€” persistÃªncia e remoÃ§Ã£o atravÃ©s de reinÃ­cio simulado:** usar `SecureAuthSessionStore` com `SessionCredentialStorage` falso compartilhado; reconstruir apÃ³s login para observar retomada; fazer logout pela UI, reconstruir e observar remoÃ§Ã£o durÃ¡vel.
- **W4 â€” falha transitÃ³ria na retomada oferece nova tentativa:** controlar a primeira carga de workspace para falhar; observar mensagem e aÃ§Ã£o de nova tentativa sem workspace; segunda tentativa bem-sucedida realiza uma Ãºnica transiÃ§Ã£o autenticada.

Os quatro cenÃ¡rios podem exigir mais de um caso de teste tÃ©cnico, mas sua composiÃ§Ã£o semÃ¢ntica nÃ£o serÃ¡ alterada depois de conhecidos os resultados das variantes.

## Conjunto independente de variantes

O catÃ¡logo congelado Ã© `variants.csv`. N1--N8 sÃ£o independentes do conjunto histÃ³rico F1--F8; os dois conjuntos nunca serÃ£o somados no mesmo denominador.

- N1: logout nÃ£o limpa a sessÃ£o local.
- N2: login bem-sucedido omite persistÃªncia.
- N3: challenge MFA expirado Ã© enviado para verificaÃ§Ã£o.
- N4: MFA recusado descarta challenge e retorna ao login.
- N5: falha de login deixa a interface ocupada.
- N6: erro de login nÃ£o Ã© renderizado.
- N7: falha transitÃ³ria na retomada deixa apenas spinner.
- N8: cancelamento MFA navega para destino incorreto.

Cada variante contÃ©m **uma alteraÃ§Ã£o semÃ¢ntica** exatamente como definida no CSV. NÃ£o haverÃ¡ substituiÃ§Ã£o de variante depois de observada sua detecÃ§Ã£o, nem inclusÃ£o de uma segunda alteraÃ§Ã£o para tornÃ¡-la detectÃ¡vel.

## Aplicabilidade e denominadores

Aplicabilidade Ã© definida antes da execuÃ§Ã£o e nÃ£o equivale a detecÃ§Ã£o. Uma variante Ã© aplicÃ¡vel quando a estratÃ©gia exercita legitimamente o caminho e possui acesso ao nÃ­vel em que o efeito pode existir. `applicable_path_no_oracle` tambÃ©m entra no denominador: o caminho Ã© exercitado, embora os orÃ¡culos atuais nÃ£o observem o efeito. `not_applicable` fica fora do denominador daquela estratÃ©gia.

| Variante | S0 | S1 | S2 |
|---|---|---|---|
| N1 | N/A | N/A | aplicÃ¡vel (W3) |
| N2 | N/A | N/A | aplicÃ¡vel (W3) |
| N3 | N/A | N/A | aplicÃ¡vel (W2) |
| N4 | aplicÃ¡vel | aplicÃ¡vel | aplicÃ¡vel (W2/cumulativa) |
| N5 | aplicÃ¡vel, caminho sem orÃ¡culo | aplicÃ¡vel, caminho sem orÃ¡culo | aplicÃ¡vel (W1) |
| N6 | N/A | N/A | aplicÃ¡vel (W1) |
| N7 | N/A | N/A | aplicÃ¡vel (W4) |
| N8 | N/A | N/A | aplicÃ¡vel (W2) |

Denominadores planejados antes das exclusÃµes de validade/equivalÃªncia: S0=`2`, S1=`2`, S2=`8`. Para cada estratÃ©gia, a taxa serÃ¡ `variantes detectadas de modo estÃ¡vel / variantes vÃ¡lidas, nÃ£o equivalentes e aplicÃ¡veis`. SerÃ£o publicados o denominador planejado, todas as exclusÃµes e o denominador analisado; uma exclusÃ£o nunca aumenta artificialmente o numerador.

O ganho incremental de S2 serÃ¡ o conjunto de variantes vÃ¡lidas aplicÃ¡veis detectadas estavelmente por S2 e nÃ£o detectadas estavelmente por S1. Como S1 Ã© cumulativa de S0, diferenÃ§as S1--S0 tambÃ©m serÃ£o registradas, sem presumir ganho.

## Validade, equivalÃªncia e classificaÃ§Ã£o

Para cada variante e estratÃ©gia aplicÃ¡vel:

- **vÃ¡lida:** a Ãºnica transformaÃ§Ã£o prÃ©-registrada foi aplicada; a variante compila; a condiÃ§Ã£o de ativaÃ§Ã£o Ã© alcanÃ§Ã¡vel; e o harness nominal funciona;
- **equivalente:** inspeÃ§Ã£o e execuÃ§Ã£o demonstram que a transformaÃ§Ã£o nÃ£o modifica o comportamento requerido no escopo exercitÃ¡vel; serÃ¡ excluÃ­da com diff, justificativa e logs preservados;
- **invÃ¡lida:** nÃ£o compila, nÃ£o inicia ou nÃ£o representa a transformaÃ§Ã£o prÃ©-registrada; nÃ£o conta como detecÃ§Ã£o e serÃ¡ excluÃ­da com causa preservada;
- **detectada-estÃ¡vel:** as trÃªs repetiÃ§Ãµes falham por asserÃ§Ã£o relevante ao efeito da variante;
- **sobrevivente-estÃ¡vel:** as trÃªs repetiÃ§Ãµes terminam aprovadas apesar da variante aplicÃ¡vel;
- **instÃ¡vel/inconclusiva:** uma ou duas das trÃªs repetiÃ§Ãµes produzem resultado semÃ¢ntico diferente das demais; nÃ£o entra no numerador de detecÃ§Ã£o, permanece visÃ­vel no denominador aplicÃ¡vel e Ã© relatada separadamente;
- **erro de infraestrutura:** falha sem asserÃ§Ã£o relevante causada por ferramenta, ambiente ou configuraÃ§Ã£o; nÃ£o conta como detecÃ§Ã£o. Uma repetiÃ§Ã£o de confirmaÃ§Ã£o serÃ¡ permitida e preservada; persistindo, o cruzamento serÃ¡ inconclusivo por infraestrutura.

Timeout sÃ³ conta como detecÃ§Ã£o se for produzido por limite previamente fixado no prÃ³prio teste como orÃ¡culo do requisito (por exemplo, encerramento de `busy`) e reproduzir-se nas trÃªs repetiÃ§Ãµes. Timeout externo do executor Ã© infraestrutura.

## Procedimento de injeÃ§Ã£o e execuÃ§Ã£o

1. Confirmar hash da base nominal e aprovaÃ§Ãµes nominais.
2. Aplicar uma Ãºnica variante em worktree/cÃ³pia isolada e preservar seu diff.
3. Verificar compilaÃ§Ã£o e ativaÃ§Ã£o sem alterar os testes para favorecer a variante.
4. Executar apenas estratÃ©gias aplicÃ¡veis, trÃªs vezes cada, preservando stdout/stderr, cÃ³digo de saÃ­da, duraÃ§Ã£o, testes que falharam e motivo de classificaÃ§Ã£o.
5. Restaurar a base, confirmar hash e executar saneamento nominal antes da variante seguinte.

Os novos testes W1--W4 serÃ£o implementados e aprovados nominalmente antes de qualquer N1--N8 ser injetada. Depois da primeira execuÃ§Ã£o de variante, seus orÃ¡culos nÃ£o serÃ£o relaxados ou ampliados; correÃ§Ã£o de infraestrutura exige desvio e repetiÃ§Ã£o integral dos resultados afetados.

## RepetiÃ§Ãµes, duraÃ§Ã£o e estabilidade

### Nominal

Cada estratÃ©gia S0, S1 e S2 terÃ¡ uma execuÃ§Ã£o de aquecimento nÃ£o contabilizada e **10 repetiÃ§Ãµes medidas** no mesmo executor. A ordem por rodada serÃ¡ rotacionada para reduzir viÃ©s de aquecimento: S0â†’S1â†’S2, depois S1â†’S2â†’S0, depois S2â†’S0â†’S1, repetindo o ciclo atÃ© a dÃ©cima rodada. Cache e estado do executor serÃ£o mantidos constantes; qualquer limpeza/reinÃ­cio serÃ¡ registrada como desvio.

### Variantes

Cada cruzamento `variante Ã— estratÃ©gia aplicÃ¡vel` terÃ¡ **3 repetiÃ§Ãµes medidas** consecutivas. NÃ£o haverÃ¡ reexecuÃ§Ã£o seletiva para substituir resultado desfavorÃ¡vel. A Ãºnica repetiÃ§Ã£o extra permitida Ã© a confirmaÃ§Ã£o de erro classificado como infraestrutura, preservando a tentativa original.

Para cada estratÃ©gia e cruzamento serÃ£o informados `n`, mediana, mÃ­nimo e mÃ¡ximo da duraÃ§Ã£o em milissegundos. NÃ£o serÃ£o usados testes de significÃ¢ncia. Estabilidade nominal serÃ¡ a frequÃªncia de repetiÃ§Ãµes cujo cÃ³digo/contagem difere do resultado modal, sobre 10. Estabilidade de variante serÃ¡ a frequÃªncia de repetiÃ§Ãµes cujo desfecho semÃ¢ntico difere do modal, sobre 3; resultados mistos serÃ£o classificados como instÃ¡veis/inconclusivos.

## Quality gate simulado (P3)

O gate serÃ¡ avaliado sem deploy real e sem promoÃ§Ã£o de variantes. Jobs obrigatÃ³rios: formataÃ§Ã£o aplicÃ¡vel, anÃ¡lise estÃ¡tica, S1, S2 e validaÃ§Ã£o/publicaÃ§Ã£o dos artefatos de teste. S0 nÃ£o Ã© job separado porque estÃ¡ contida em S1; permanece estratÃ©gia analÃ­tica.

Para cada variante:

- **bloqueada:** job obrigatÃ³rio falha por asserÃ§Ã£o relevante;
- **nÃ£o bloqueada:** todos os jobs obrigatÃ³rios aprovam apesar da variante;
- **inconclusiva:** gate falha por infraestrutura/configuraÃ§Ã£o ou apresenta resultado instÃ¡vel.

A existÃªncia do workflow nÃ£o serÃ¡ tratada como evidÃªncia. A avaliaÃ§Ã£o exige execuÃ§Ã£o contra a base nominal e as variantes, com logs e classificaÃ§Ã£o. NÃ£o haverÃ¡ staging ou produÃ§Ã£o nesta pesquisa.

## EvidÃªncias e anÃ¡lise

SerÃ£o preservados ambiente, revisÃ£o/hashes, patches, lockfile, comandos, horÃ¡rios, duraÃ§Ã£o, stdout/stderr, cÃ³digos de saÃ­da, resultados legÃ­veis por mÃ¡quina e restauraÃ§Ã£o da base. A anÃ¡lise manterÃ¡ separados:

1. F1--F8 histÃ³ricos;
2. N1--N8 prÃ©-registrados;
3. comportamento nominal S0--S2;
4. erros de infraestrutura;
5. gate simulado.

As tabelas principais serÃ£o `variante Ã— estratÃ©gia Ã— repetiÃ§Ã£o Ã— classificaÃ§Ã£o`, detecÃ§Ã£o por categoria, ganho incremental, duraÃ§Ã£o/estabilidade nominal e resultado do gate. Cobertura de cÃ³digo, se coletada, serÃ¡ complementar e nÃ£o serÃ¡ usada como sinÃ´nimo de detecÃ§Ã£o, testabilidade ou seguranÃ§a.

## CritÃ©rios de parada e desvios

A coleta serÃ¡ interrompida antes de prosseguir quando ocorrer qualquer condiÃ§Ã£o:

- falha nominal em S0, S1 ou S2;
- hash da base nÃ£o restaurado apÃ³s uma variante;
- mais de uma alteraÃ§Ã£o semÃ¢ntica necessÃ¡ria para materializar a variante;
- erro de infraestrutura persistente apÃ³s uma confirmaÃ§Ã£o;
- necessidade de alterar um orÃ¡culo apÃ³s observar resultado de variante;
- exposiÃ§Ã£o de segredo, credencial, token ou PII em artefato.

O evento, arquivos afetados e decisÃ£o serÃ£o registrados. CorreÃ§Ãµes de infraestrutura ou de teste exigem nova execuÃ§Ã£o integral dos cruzamentos afetados. Variante invÃ¡lida/equivalente nÃ£o serÃ¡ substituÃ­da por outra apÃ³s a coleta. S3/P4 sÃ³ podem surgir por adendo de viabilidade anterior Ã s respectivas execuÃ§Ãµes e nÃ£o mudam a anÃ¡lise principal. O manuscrito sÃ³ serÃ¡ alterado depois de encerradas a coleta, a classificaÃ§Ã£o e a consolidaÃ§Ã£o dos resultados.

