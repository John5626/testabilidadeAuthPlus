# Correção nominal — falha de persistência da sessão

Data: 03/11/2026.

Classificação: **não conformidade da base corrigida antes do pré-registro P1**. Esta descoberta não é variante, não pertence ao denominador N1--N8 e o teste criado não integra S0 ou S1.

## Hipótese verificada

No estado corrigido apenas para C6, `_startAuthenticatedSession()` carregava o workspace, atribuía `StudyAppStage.workspace` e somente depois chamava `persistSession()`, fora do bloco que revertia a autenticação. A hipótese era que uma exceção do armazenamento deixaria estado autenticado parcial.

Foi criado o teste separado `frontend/test/cotb_persistence_failure_conformance_test.dart`. O dublê herda de `MemoryAuthSessionStore` e lança `StateError('synthetic persistence failure')` exclusivamente em `persistSession()`.

Oráculo definido antes da correção:

- `signIn()` retorna `false`;
- estágio final é `login`;
- workspace é `null`;
- sessão é `null`;
- a falha de persistência permanece observável como mensagem de erro.

## Evidência pré-correção

Comando:

```text
flutter test --no-pub test/cotb_persistence_failure_conformance_test.dart --reporter expanded
```

Controlador antes da correção, SHA-256:

```text
F699E82D3907E02D12FB13BC50CD0C69962E52A720A558BCC8F51433102301E7
```

Resultado: **0/1 aprovado**, código de saída do Flutter `1`. O valor observado conjuntamente foi:

```text
[StudyAppStage.workspace, Instance of 'WorkspaceData', null]
```

Portanto, a sessão havia sido removida, mas o estágio e o workspace ainda liberavam o estado autenticado. O log bruto está em `runs/p0/persistence-before-correction.txt` (SHA-256 `B30950C65D0AEC575BC2E8B1CFAFDB8B13F458F766E5A0F5BE4BA72BF5AAFA00`).

## Correção mínima

Arquivo alterado: `frontend/lib/src/features/studyapp/presentation/studyapp_flow_controller.dart`.

Alteração: `await sessionStore.persistSession()` foi movido para dentro do mesmo bloco `try` que carrega e aplica o workspace. Não foi alterada a ordem nominal de sucesso: sessão em memória → workspace → persistência → retorno. Se a escrita falha, o `catch` existente agora executa conjuntamente:

```text
sessionStore.clear();
_workspace = null;
_stage = StudyAppStage.login;
```

Controlador após a correção, SHA-256:

```text
9FC348BE0D4378DBED99ACA7F67AE5029AC8FB4E9215C0FBC45311BB88435607
```

Teste de conformidade final, SHA-256:

```text
AB8978657F407AC75BD08A9F1AEA16783794994BC828F48828491FF3B0D89CD2
```

## Evidência pós-correção

| Verificação | Comando resumido | Resultado |
|---|---|---|
| Conformidade isolada | `flutter test --no-pub test/cotb_persistence_failure_conformance_test.dart --reporter expanded` | 1/1 aprovado |
| Regressão S0 | `flutter test --no-pub test/studyapp_flow_controller_test.dart --reporter expanded` | 17/17 aprovados |
| Regressão S1 | S0 + `cotb_authentication_testability_test.dart` + `cotb_obsolete_response_conformance_test.dart` | 22/22 aprovados |
| Análise estática | `flutter analyze --no-pub` nos dois arquivos alterados | nenhum problema |
| Formatação | `dart format --output=none --set-exit-if-changed` nos dois arquivos | 0 mudanças após formatação |

Logs brutos:

| Arquivo | SHA-256 |
|---|---|
| `runs/p0/persistence-after-correction.txt` | `A97E72F21524AC4064A99CEC5FA9D3903E82A0E618012C5077FD4651A71B941C` |
| `runs/p0/s0-after-persistence-correction.txt` | `14A5F8B7AE1226554304FE53BEF6146691997DD068C3A463499077467AD66E86` |
| `runs/p0/s1-after-persistence-correction.txt` | `9A37CFDF3E18CED2D48889CC45239A7DE26C48A0C3E53A8FE3C44602D540F426` |
| `runs/p0/analyze-persistence-correction.txt` | `8AA954479A3B4BD658DF2E60A0E83923C0313C2C769DE22CD523FD75F920C969` |

## Impacto no protocolo

- S0 permanece com 17 testes e S1 permanece com 22; o novo teste é uma verificação de saneamento da base.
- Nenhuma variante N1--N8 foi implementada ou executada.
- N2 continua viável como omissão deliberada da persistência em um login nominal; é distinta desta descoberta, que tratou uma exceção real durante a escrita.
- O pré-registro pode referenciar o novo hash do controlador como estado nominal, registrando explicitamente a sequência `ANONYMIZED_BASE_REVISION + correção C6 + correção de persistência`.
