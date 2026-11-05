# Anonymous research artifact — Flutter authentication testing

Pacote de avaliação de configurações cumulativas de teste de autenticação Flutter. Contém código executável, testes, protocolos e cópias de resultados coletados.
## Estrutura

| Pasta | Conteúdo |
| --- | --- |
| `frontend/` | Base nominal do novo conjunto e testes de S0/S1/S2; teste de saneamento separado |
| `research/estudo_regressoes/` | Protocolo, catálogo N1–N8, desvios, scripts, CSV, logs, patches, restaurações e resultados do gate |
| `research/evidencias/` | Matrizes e registros históricos F1–F8, separados do conjunto novo |
| `research/experimento/frontend-historico/` | Base histórica com a guarda temporal, anterior à correção de persistência |
| `research/experimento/executar_mutacoes.ps1` | Executor histórico F1–F8 para a base histórica, não para a nominal atual |
| `workflow-reference/` | Workflow de referência inspecionado; não foi executado em CI hospedada |
| `provenance/` | Correspondência de hashes entre fontes privadas e exportação; regras de anonimização |
| `scripts/` | Verificação local de integridade e resultados |
| `outputs/` | Resultados recalculados a partir dos CSVs exportados |

## Conferir os resultados sem executar Flutter

Requer Python 3.10 ou superior, sem pacotes adicionais. A partir da raiz:

```powershell
python scripts/verify_artifact.py
python research/estudo_regressoes/scripts/analyze-results.py --tables-only --output-dir outputs/recomputed
```

Esperado: 33 execuções nominais (três aquecimentos e 30 medidas), 11 cruzamentos válidos com três repetições cada, N3 inválida e oito restaurações. S0/S1 detectam 2/2 variantes válidas aplicáveis; S2 detecta 7/7, acrescentando N1/N2/N6/N7/N8. O gate local bloqueou as sete válidas. As oportunidades de detecção são diferentes; não se trata de comparação percentual sob denominador comum.

Medianas de duração externa: 9.298 / 9.327,5 / 9.345 ms. Resultados históricos: 8/12 → 12/12 efeitos e 3/8 → 8/8 falhas. Os dois conjuntos não devem ser somados.

## Executar a base nominal exportada

Ambiente registrado na coleta: Windows 10.0.26300, Flutter 3.47.0 e Dart 3.13.0. Requer Flutter e acesso às dependências do `pubspec.lock` (ou cache local).

```powershell
cd frontend
flutter pub get
flutter test --no-pub test/studyapp_flow_controller_test.dart test/cotb_authentication_testability_test.dart test/cotb_obsolete_response_conformance_test.dart test/cotb_widget_regression_test.dart --reporter expanded
```

São esperados 27 testes. O teste `cotb_persistence_failure_conformance_test.dart` é saneamento da base e não integra esses 27.

## Repetir a campanha em uma cópia de trabalho

Requer PowerShell 7, Flutter/Dart e Git disponível para `git diff --no-index`, sem necessidade de histórico original. Prepare dependências em `frontend/` antes. Estes comandos modificam temporariamente os arquivos da cópia e os restauram; execute numa cópia descartável do pacote e use identificadores novos:

```powershell
pwsh -File research/estudo_regressoes/scripts/run-nominal.ps1 -RunId replication-001
pwsh -File research/estudo_regressoes/scripts/run-variants.ps1 -RunId replication-001
pwsh -File research/estudo_regressoes/scripts/run-gate.ps1 -RunId replication-001
python research/estudo_regressoes/scripts/analyze-results.py --run-id replication-001 --tables-only --output-dir outputs/replication-001
```

N3 deve permanecer inválida; não corrija sua transformação retrospectivamente. Uma reprodução pode encontrar diferenças ambientais, de tempo ou classificação: preserve-as e registre um adendo. Não substitua os registros originais em `p1p3-20261103`.

Para o histórico, prepare dependências em `research/experimento/frontend-historico/` e execute da raiz:

```powershell
pwsh -File research/experimento/executar_mutacoes.ps1 -Worktree ./research/experimento/frontend-historico
```

O executor histórico grava em `research/evidencias/mutacoes/`; utilize uma cópia descartável para preservar os registros fornecidos. Essa base é diferente da nominal N1–N8.

## Limites e proveniência

As cópias foram anonimizadas: caminhos, identificadores do produto, revisões privadas e dados de exemplo foram substituídos. O logo foi substituído por imagem neutra; a fonte tipográfica externa foi removida. Isso modifica os bytes e pode afetar apresentação e tempo. A aprovação nominal da exportação, quando disponível, é uma checagem do pacote, não nova medição do artigo. Consulte [proveniência](provenance/ANONYMIZATION.md) e [validação](VALIDATION.md).

Hashes nos CSVs e no protocolo descrevem as fontes da coleta original. `source-export-hashes.json` distingue esses hashes dos bytes exportados; `SHA256SUMS` identifica os arquivos atuais. O protocolo anonimizado não é byte a byte o documento originalmente congelado.

O armazenamento compartilhado é falso e em memória. O gate foi executado localmente; o workflow é apenas referência. Não houve dispositivo, armazenamento seguro nativo, serviços reais, CI hospedada ou deploy. Não se demonstra superioridade causal de widgets nem segurança geral da aplicação.

Licença de redistribuição ainda deve ser definida pelos titulares; consulte `LICENSING.md`. A URL pública de avaliação deverá ser acrescentada pelos autores ao artigo depois da criação do repositório.
