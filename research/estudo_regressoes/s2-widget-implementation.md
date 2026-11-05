# Implementação nominal da estratégia S2

## Escopo e composição

S2 foi implementada depois do congelamento do protocolo, sem injetar N1--N8 e sem ampliar os quatro cenários semânticos pré-registrados. O arquivo `frontend/test/cotb_widget_regression_test.dart` contém **5 casos técnicos** para os **4 cenários W1--W4**. Somada aos 22 testes de S1, a suíte cumulativa S2 possui **27 testes**.

| Cenário | Casos técnicos | Efeitos observados pela interface |
|---|---:|---|
| W1 | 1 | progresso e envio desabilitado enquanto o login está pendente; mensagem de credencial inválida, remoção do progresso, reabilitação do envio e ausência de workspace após a falha |
| W2 | 2 | MFA recusado mantém tela e challenge; cancelamento retorna ao login; challenge expirado não chama o repositório e não libera workspace |
| W3 | 1 | login pela UI persiste credencial; nova instância de `StudyAppRootView` retoma a sessão; logout pela UI remove a credencial; terceira instância permanece na landing |
| W4 | 1 | falha transitória na retomada mostra mensagem e ação de nova tentativa sem workspace; o retry realiza uma única transição autenticada bem-sucedida |

Os testes interagem com widgets reais (`StudyAppRootView`, `LoginView`, `MfaChallengeView`, `WorkspaceView` e `LandingView`). Ordem assíncrona é controlada por `Completer` e barreiras observáveis. Não há `sleep`; dados, JWT e armazenamento são sintéticos. W3 usa `SecureAuthSessionStore` com um `SessionCredentialStorage` falso compartilhado entre três instâncias do fluxo.

## Alterações realizadas

- `frontend/test/cotb_widget_regression_test.dart`: implementação dos cinco casos técnicos de W1--W4 e dos dublês determinísticos necessários.
- `frontend/lib/src/features/studyapp/presentation/login_view.dart`: correção nominal mínima de layout, substituindo apenas o `Row` do convite de cadastro por `Wrap`, com alinhamento central.

Hashes SHA-256 após a validação:

- teste S2: `C681AFA9F140FA25C993C488D90A3C7AFE17416E9B5427019299F958E2096473`;
- `login_view.dart`: `3E8B60A65B66A69CB758F47696B6CB8FB7A2043E414638804515C9BB0F7168C8`;
- controlador nominal, não alterado nesta etapa: `9FC348BE0D4378DBED99ACA7F67AE5029AC8FB4E9215C0FBC45311BB88435607`.

## Critério de parada e desvio datado

Em **2026-11-03 às 10:02 (America/Sao_Paulo)**, a primeira execução do harness expôs um `RenderFlex overflowed by 100 pixels on the right` no `Row` que combina “Não tem uma conta?” e o botão de cadastro. Como S2 nominal falhou, a condição de parada “falha nominal em S0, S1 ou S2” do protocolo foi acionada antes de qualquer variante.

A execução foi interrompida e preservada em `runs/nominal/s2-widget-layout-failure-before-correction.txt`. Com autorização do coordenador, aplicou-se a menor correção possível: `Row` para `Wrap` apenas nesse bloco. A suíte isolada e a cumulativa foram então repetidas integralmente. A descoberta é um **defeito nominal de layout revelado pelo harness**, não uma variante N1--N8, não constitui detecção de mutante e não entra em numerador ou denominador de taxa.

Antes da coleta nominal final, houve ainda dois ajustes de construção do harness, sem alteração dos cenários ou oráculos:

1. inclusão do import do contrato `StudyAppRepository` e remoção de um diretório vazio criado por caminho relativo incorreto;
2. substituição do `MockStudyAppRepository.loadWorkspace()` temporizado por uma fixture estática e repositórios controlados. A dependência do atraso artificial de 260 ms prendia W3 no relógio falso do teste. O ajuste tornou a barreira explícita e determinística, como exigido pelo protocolo.

A tentativa exploratória anterior foi preservada em `runs/nominal/s2-widget-isolated-attempt1.txt`, mas não compõe resultado nominal medido. Nenhuma execução de N1--N8 ocorreu antes ou durante esses ajustes.

## Validação nominal final

| Verificação | Comando | Resultado | Duração externa |
|---|---|---:|---:|
| S2 isolada | `flutter test --no-pub test/cotb_widget_regression_test.dart --reporter expanded` | 5/5 aprovados | 7.129 ms |
| S2 cumulativa | `flutter test --no-pub test/studyapp_flow_controller_test.dart test/cotb_authentication_testability_test.dart test/cotb_obsolete_response_conformance_test.dart test/cotb_widget_regression_test.dart --reporter expanded` | 27/27 aprovados | 9.557 ms |
| análise estática | `flutter analyze --no-pub` | sem problemas | não medida |
| formatação | `dart format --output=none --set-exit-if-changed <arquivos modificados>` | estável, código 0 | não medida |
| diff | `git diff --check` | sem erros de whitespace | não medida |

Não havia processo Flutter/Dart de depuração nem Dart Tooling Daemon ativo ao final; portanto, não existia aplicação em execução à qual aplicar hot reload/hot restart. A validação de execução foi feita pelas suítes Flutter isolada e cumulativa acima.

## Evidências preservadas

- `runs/nominal/s2-widget-layout-failure-before-correction.txt` — SHA-256 `B8362A5269C74045E16F2F46DF1EC7097200F228DA6F8E7CE24BAADC1D7C99DE`;
- `runs/nominal/s2-widget-isolated-attempt1.txt` — SHA-256 `CB79481A842B7914CACAAA23E9DFDC2E4D3AD5D8F26B086EAB5AEF2ECEE2BA65`;
- `runs/nominal/s2-widget-isolated-final.txt` — SHA-256 `5C90E28B04A5FAD10000FE0EC6F2D42C11B348B136D9A8B67FF4E634CEC5EF75`;
- `runs/nominal/s2-cumulative-final.txt` — SHA-256 `BD3B2590F1EC53443033BAC6C807E22B8EEA07FF1F5C8EF73FC2AA3E8EFF640A`;
- `runs/nominal/flutter-analyze-final.txt` — SHA-256 `96E8EDE689BD5C387C205362935871FFBDA334CA7D3FF5DF5B451BA9C01A8257`;
- `runs/nominal/dart-format-check-final.txt` — SHA-256 `20EDEB1F47F7B9AB73ADC166304F89551F151E46E67E2FAD44795B46309CD839`;
- `runs/nominal/git-diff-check-final.txt` — SHA-256 `F0498686AE32840CE2D1DD1F47108A1549D3F2B89A4F899EA2736001B238F364`;
- metadados de comando, código de saída e duração nos arquivos `*.meta.txt` correspondentes.

Esta etapa demonstra apenas que o baseline nominal de S2 está executável. As dez repetições nominais medidas e a campanha N1--N8 continuam sendo etapas posteriores do protocolo.
