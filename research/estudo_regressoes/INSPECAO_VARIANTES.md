# Inspeção de viabilidade para o novo conjunto de regressões

Data da inspeção: 03/11/2026.

Estado: **documento exploratório anterior ao pré-registro**. Os itens N1--N8 são candidatos; ainda não constituem o conjunto congelado, não foram injetados e não produziram resultados experimentais.

## Base inspecionada

- Código histórico: `frontend@ANONYMIZED_BASE_REVISION`.
- Estado nominal proposto para o novo estudo: código histórico acrescido da correção temporal C6, cujo controlador tem SHA-256 `F699E82D3907E02D12FB13BC50CD0C69962E52A720A558BCC8F51433102301E7`.
- S0: 17 testes históricos de `studyapp_flow_controller_test.dart`.
- S1: S0 mais C4, C5 e C6a--C6c, totalizando 22 testes.
- S2: ainda inexistente; nesta inspeção são propostos quatro cenários de widget, sem implementação.

Aplicabilidade é separada de detecção. `A/detecta` significa que a composição atual ativa e possui oráculo para a falha; `A/sobrevive` significa que ativa o caminho, mas não observa o efeito; `N/A` significa que a estratégia atual não ativa ou não consegue observar legitimamente o efeito. Essa distinção deve ser mantida no denominador por estratégia.

## Candidatos independentes de F1--F8

### N1 — Logout não limpa a sessão local

- **Requisito/risco:** logout deve remover a sessão em memória e a credencial persistida; caso contrário, uma reabertura pode autenticar novamente sem credenciais.
- **Local exato:** `frontend/lib/src/features/studyapp/presentation/studyapp_flow_controller.dart`, método `logout()`, chamada `sessionStore.clear()`.
- **Transformação única:** remover somente `sessionStore.clear()`, preservando `flush()`, limpeza do workspace e navegação.
- **Ativação:** sessão ACCESS previamente iniciada e persistida; usuário aciona logout.
- **Efeito incorreto esperado:** a UI volta à landing, mas a sessão continua no store e pode ser restaurada numa nova instância.
- **Categoria:** sessão/persistência/logout.
- **Aplicabilidade:** S0 `N/A` (não exercita logout); S1 `N/A`; S2 `planejada`, pelo cenário W3.
- **Teste histórico capaz de detectar:** não. `secure_auth_session_store_test.dart` testa o store diretamente, mas não o encadeamento do controlador.

### N2 — Login bem-sucedido omite a persistência da sessão

- **Requisito/risco:** após sessão ACCESS e workspace válidos, a sessão deve ser persistida para a retomada prevista no aplicativo móvel.
- **Local exato:** `studyapp_flow_controller.dart`, final de `_startAuthenticatedSession()`, chamada `await sessionStore.persistSession()`.
- **Transformação única:** remover somente a chamada de persistência.
- **Ativação:** login retorna ACCESS e o workspace carrega com sucesso.
- **Efeito incorreto esperado:** o fluxo atual mostra o workspace, mas uma nova instância do store não recupera a sessão.
- **Categoria:** sessão/persistência/retomada.
- **Aplicabilidade:** S0 e S1 percorrem o sucesso, porém usam `MemoryAuthSessionStore`, no qual a durabilidade é inobservável; por isso `N/A` para o denominador desta falha. S2 `planejada`, pelo cenário W3 com armazenamento falso durável.
- **Teste histórico capaz de detectar:** não. Os testes históricos verificam a sessão em memória, não a escrita persistente causada pelo controlador.

### N3 — Challenge MFA expirado ainda é enviado para verificação

- **Requisito/risco:** challenge expirado não deve chamar o serviço nem liberar sessão/workspace.
- **Local exato:** `studyapp_flow_controller.dart`, método `verifyMfa()`, chamada `_ensureChallengeIsUsable(challenge!)`.
- **Transformação única:** remover somente a validação local da validade no fluxo MFA.
- **Ativação:** store contém `MFA_REQUIRED` com `expiresAt` no passado e o usuário envia um código formalmente válido.
- **Efeito incorreto esperado:** o repositório é chamado com challenge expirado e, se o dublê responder ACCESS, o workspace é liberado.
- **Categoria:** MFA/expiração/sessão.
- **Aplicabilidade:** S0 `N/A` e S1 `N/A`, pois todos os challenges usados têm validade futura; S2 `planejada`, pelo cenário W2.
- **Teste histórico capaz de detectar:** não.

### N4 — MFA recusado descarta o challenge e retorna ao login

- **Requisito/risco:** código MFA inválido deve manter o challenge utilizável e a tela MFA, sem sessão ou workspace, permitindo nova tentativa.
- **Local exato:** `studyapp_flow_controller.dart`, `catch (error)` genérico de `verifyMfa()`.
- **Transformação única:** substituir `_errorMessage = error.toString()` por `_returnToLoginAfterChallengeFailure(error)`.
- **Ativação:** `verifyMfa` lança `InvalidMfaCodeException` para challenge ainda válido.
- **Efeito incorreto esperado:** challenge é apagado e a pessoa volta ao login após um simples código recusado.
- **Categoria:** MFA/recuperabilidade/navegação.
- **Aplicabilidade:** S0 `A/detecta`, pelo teste histórico “MFA inválido mantém challenge isolado e workspace bloqueado”; S1 `A/detecta` por conter S0; S2 também detectaria cumulativamente e poderia observar a tela.
- **Teste histórico capaz de detectar:** sim, com asserções de estágio e preservação do challenge.

### N5 — Falha de login deixa a interface permanentemente ocupada

- **Requisito/risco:** após sucesso ou falha, a operação deve encerrar o estado ocupado para permitir recuperação e nova tentativa.
- **Local exato:** `studyapp_flow_controller.dart`, bloco `finally` de `signIn()`, atribuição `_busy = false` protegida pela geração ativa.
- **Transformação única:** remover somente `_busy = false`, mantendo a invalidação da operação e a notificação.
- **Ativação:** login em andamento termina com erro de credencial ou serviço enquanto a geração ainda é a ativa.
- **Efeito incorreto esperado:** o erro pode existir no controlador, mas o botão continua desabilitado e com indicador de progresso indefinido.
- **Categoria:** falha de serviço/recuperabilidade/estado de UI.
- **Aplicabilidade:** S0 `A/sobrevive` e S1 `A/sobrevive`: ambos executam falha de credencial, mas não verificam `isBusy`; S2 `planejada/detecta`, pelo cenário W1.
- **Teste histórico capaz de detectar:** não com os oráculos atuais.

### N6 — Erro de login não é renderizado

- **Requisito/risco:** a pessoa deve receber retorno recuperável e uniforme após falha, sem ficar sem explicação.
- **Local exato:** `frontend/lib/src/features/studyapp/presentation/login_view.dart`, condição `if (widget.errorMessage != null)` que inclui a mensagem no formulário.
- **Transformação única:** tornar somente essa condição sempre falsa, preservando o estado do controlador.
- **Ativação:** `LoginView` recebe `errorMessage` após falha de autenticação.
- **Efeito incorreto esperado:** o controlador contém a mensagem, porém nenhum texto de erro aparece na tela.
- **Categoria:** falha de serviço/observabilidade/UI.
- **Aplicabilidade:** S0 e S1 `N/A`, pois não constroem `LoginView`; S2 `planejada/detecta`, pelo cenário W1.
- **Teste histórico capaz de detectar:** não.

### N7 — Falha transitória ao restaurar sessão mantém apenas o spinner

- **Requisito/risco:** uma falha não classificada ao confirmar sessão válida deve apresentar mensagem e ação de nova tentativa, sem liberar workspace.
- **Local exato:** `studyapp_flow_controller.dart`, `catch` genérico de `resumeSession()`, ramo em que `sessionStore.session != null`, atribuição da mensagem “Não foi possível confirmar a sessão”.
- **Transformação única:** suprimir somente essa atribuição, mantendo estágio `restoring` e sessão local.
- **Ativação:** sessão local ainda válida e `loadWorkspace()` lança erro transitório diferente de `IdentitySessionInvalidException`.
- **Efeito incorreto esperado:** `StudyAppRootView` permanece mostrando `CircularProgressIndicator`, sem mensagem nem botão “Tentar novamente”.
- **Categoria:** sessão/falha de serviço/recuperabilidade/UI.
- **Aplicabilidade:** S0 e S1 `N/A`, pois cobrem recusa explícita da sessão, não erro transitório; S2 `planejada/detecta`, pelo cenário W4.
- **Teste histórico capaz de detectar:** não.

### N8 — Cancelamento do MFA navega para o destino errado

- **Requisito/risco:** cancelar o challenge deve descartá-lo e retornar ao login, mantendo a semântica da jornada.
- **Local exato:** `frontend/lib/src/features/studyapp/presentation/studyapp_root_view.dart`, construção de `MfaChallengeView`, ligação `onCancel: controller.leaveAuthenticationChallenge`.
- **Transformação única:** ligar `onCancel` a `controller.openLanding`.
- **Ativação:** tela MFA visível; usuário toca “Cancelar e voltar ao login”.
- **Efeito incorreto esperado:** challenge é apagado, mas a UI vai à landing em vez de apresentar o login prometido pelo controle.
- **Categoria:** navegação/MFA/integração View--Controller.
- **Aplicabilidade:** S0 e S1 `N/A`, pois chamam o controlador diretamente e não verificam a ligação do widget; S2 `planejada/detecta`, pelo cenário W2.
- **Teste histórico capaz de detectar:** não. O teste histórico comprova `leaveAuthenticationChallenge()`, mas não que a View invoque esse comando.

## Cenários de widget propostos para S2

Os cenários devem usar `StudyAppRootView`, dublês determinísticos e `Completer`; não devem usar `sleep`.

### W1 — Falha de login visível e recuperável

1. Abrir a landing, navegar para login e preencher credenciais sintéticas.
2. Manter `signIn` pendente por `Completer` e verificar botão desabilitado mais progresso visível.
3. Concluir com erro uniforme e verificar: progresso removido, mensagem visível, botão novamente habilitado e ausência de workspace.

Valor adicional: observa renderização, habilitação do controle e recuperação da interação, que não são verificadas pelos testes do controlador. Detecta N5 e N6.

### W2 — MFA recusado/expirado e cancelamento coerente

1. Produzir challenge MFA por interação de login e mostrar `MfaChallengeView`.
2. Para recusa comum, enviar seis dígitos, verificar `mfa-error`, permanência da tela e ausência de workspace.
3. Em caso separado com challenge expirado, confirmar que o repositório MFA não é chamado e que a jornada retorna a estado recuperável.
4. Tocar o controle de cancelamento e verificar a presença de `LoginView`, não landing/workspace.

Valor adicional: cobre mensagem, formulário real, ausência visual de workspace e ligação View--Controller. Detecta N3, reforça N4 e detecta N8.

### W3 — Persistência e remoção através de reinício simulado

1. Usar `SecureAuthSessionStore` com `SessionCredentialStorage` falso compartilhado entre instâncias.
2. Após login ACCESS, reconstruir a aplicação/controlador e confirmar retomada somente depois da consulta de workspace.
3. Acionar logout pela tela de perfil, aguardar a conclusão e reconstruir novamente; confirmar que workspace não reaparece e a credencial foi removida.

Valor adicional: observa o efeito durável de interação real, ausente no `MemoryAuthSessionStore`. Detecta N1 e N2. A retomada deve ser testada sem expor o token em logs.

### W4 — Falha transitória na retomada oferece nova tentativa

1. Iniciar com sessão local válida e `loadWorkspace()` controlado por `Completer`.
2. Concluir a primeira tentativa com erro transitório e verificar mensagem mais botão “Tentar novamente”, sem workspace.
3. Fazer a segunda chamada retornar workspace e verificar transição única para a tela autenticada.

Valor adicional: observa a diferença entre spinner, mensagem e ação de recuperação. Detecta N7 e não duplica o caso histórico de sessão explicitamente inválida.

## Candidatos excluídos nesta inspeção

- **Workspace tardio após logout/abandono:** já é representado por F6/F7; repetir a mesma guarda com outro nome inflaria artificialmente o novo conjunto.
- **Erro tardio de login:** já é representado por F8.
- **Sessão local expirada:** já é representada por F5.
- **Duas tentativas concorrentes em que a antiga vence:** no código nominal, `_busy` impede a segunda tentativa e as guardas de geração impedem a resposta antiga. Produzir a falha exigiria ao menos remover o bloqueio de reentrada e outra guarda, violando a regra de uma alteração semântica por variante. Não deve ser pré-registrada nessa forma.

## Não conformidade nominal a resolver antes do pré-registro

Há uma lacuna real no estado corrigido: `_startAuthenticatedSession()` atribui `_workspace` e `StudyAppStage.workspace` antes de `await sessionStore.persistSession()`. Se a persistência lançar exceção, o `catch` externo de `signIn()` limpa a sessão e publica erro, mas não limpa `_workspace` nem devolve o estágio ao login. Assim, um teste de “falha ao salvar sessão não deixa estado autenticado parcial” provavelmente falharia **sem qualquer variante**.

Esse comportamento não pode ser contado como mutante detectado. Antes do congelamento P1, deve-se:

1. criar uma verificação de conformidade nominal com store cuja persistência falha;
2. registrar o resultado como defeito da base, se confirmado;
3. corrigir e repetir S0/S1 sem reclassificar a descoberta como variante;
4. só então decidir se uma variante independente de persistência ainda é necessária.

## Riscos metodológicos

- N1/N2 só são aplicáveis a uma estratégia que modele durabilidade; usar `MemoryAuthSessionStore` e incluí-las no denominador de S0/S1 produziria comparação injusta.
- N5/N6/N7/N8 foram escolhidas por efeitos de UI atualmente ausentes da suíte do controlador. O pré-registro deve ocorrer antes de implementar W1--W4 para reduzir viés de adequação retrospectiva.
- N4 já é detectada pela suíte histórica e deve permanecer no conjunto se o objetivo for medir a composição real por categoria; ela não deve ser removida apenas por não favorecer S2.
- Testes de widget podem observar navegação do cliente, mas não demonstram autorização efetiva no backend nem segurança geral do aplicativo.
