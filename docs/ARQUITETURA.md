# Arquitetura do Ponto Study — guia de cada arquivo

Este guia explica, em português simples, para que serve cada parte do projeto, o que você pode mudar com segurança e o que exige cuidado.

## A ideia geral: camadas que não se misturam

```
Telas (features/*/..._screen.dart)
   │  mostram dados e repassam toques
   ▼
Controladores e repositórios (features/*/..._controller.dart, ..._repository.dart)
   │  buscam e gravam no banco, chamam os cálculos
   ├──────────────► Cálculos puros (domain/)  — sem tela, sem banco, 100% testáveis
   ▼
Banco local (core/database/)  — SQLite via Drift
```

- **Telas** nunca escrevem SQL nem fazem cálculos de tempo.
- **domain/** nunca importa Flutter nem o banco.
- **AppScope** (`lib/app/app_scope.dart`) entrega os repositórios para qualquer tela: `AppScope.of(context).subjects`.

## Regra dos dados: salvar fatos, calcular o resto

Salvamos só o que **aconteceu**: sessões, pausas, matérias, planejamentos, configurações. Totais, médias, sequência de dias e progresso de metas são **calculados** na hora (em `lib/domain/stats/study_stats.dart`) e por isso nunca ficam desatualizados.

---

## Arquivos

### `lib/main.dart`
- **Função:** ponto de partida. Abre o banco, carrega as preferências e mostra o app.
- **Pode modificar:** quase nada. Só para adicionar inicializações novas.
- **Depende de:** `app/app.dart`, `app/app_scope.dart`, `core/database/database.dart`.

### `lib/app/app.dart`
- **Função:** configura o `MaterialApp` (tema, idioma português) e decide a primeira tela: sem perfil, mostra "Como podemos chamar você?"; com perfil, abre a tela principal.
- **Pode modificar:** título, idioma.
- **Cuidado:** a condição `settings.profile == null` controla o onboarding.

### `lib/app/app_scope.dart`
- **Função:** cria uma única vez o banco, os repositórios e os controladores e os disponibiliza para as telas.
- **Pode modificar:** adicionar novos repositórios quando criar módulos novos.
- **Relação:** usado por praticamente todas as telas.

### `lib/app/shell.dart`
- **Função:** navegação principal. Em janela larga (≥ 840 px) mostra a sidebar; no celular, a barra inferior com Início, Matérias, Estudar, Plano e Mais.
- **Pode modificar:** ordem, nomes e ícones das seções (lista `_destinations`).
- **Cuidado:** `shellTab` e `goToTab()` são usados por outras telas para trocar de aba.

### `lib/core/database/tables.dart`
- **Função:** estrutura de todas as tabelas: `profiles`, `app_settings`, `subjects`, `content_nodes` (árvore), `study_sessions`, `session_pauses`, `plan_items`.
- **Pode modificar:** adicionar colunas ou tabelas.
- **Não modifique sem entender:** remover ou renomear colunas. Isso exige migração (veja abaixo).

### `lib/core/database/database.dart`
- **Função:** abre o arquivo SQLite (modo WAL, chaves estrangeiras ativas) e define a versão do banco.
- **Para mudar o banco:** altere `tables.dart`, aumente `schemaVersion` em +1 e descreva a mudança em `onUpgrade`. O arquivo `database.g.dart` é gerado por `dart run build_runner build` e **nunca** deve ser editado à mão.

### `lib/core/theme/app_themes.dart`
- **Função:** os 6 temas. Cada um tem cores para modo escuro e claro, raio de borda, sombras, fonte de títulos e tipo de decoração.
- **Pode modificar:** cores (`Color(0xFFRRGGBB)`), raios, descrições. Para um tema novo, copie um `AppThemeSpec`, troque o `id` e adicione em `appThemes`.
- **Não modifique:** os `id` existentes, porque ficam salvos nas preferências.

### `lib/core/theme/theme_decor.dart`
- **Função:** desenha a decoração de fundo de cada tema (pinheiros, chuva, sol, ondas, molduras) em vetores, sem imagens.
- **Pode modificar:** formas e opacidades. Mantenha opacidades baixas para preservar a leitura.

### `lib/core/widgets/common.dart`
- **Função:** componentes reutilizáveis: `PageScaffold`, `SectionCard`, `StatTile`, `ProgressLine`, `EmptyState`, `SubjectBadge`, `confirmDialog`, `ResponsiveGrid`.
- **Pode modificar:** o visual. A mudança vale para o app inteiro.

### `lib/core/widgets/subject_node_picker.dart`
- **Função:** campo "Matéria + Assunto/tópico", usado no cronômetro, registro manual e planejamento.

### `lib/core/utils/format.dart`
- **Função:** formata tempo ("1h 30min", "01:02:05") e datas em português.

### `lib/domain/timer/timer_math.dart`
- **Função:** cálculo do tempo do cronômetro: `(agora − início) − pausas`. É por isso que o tempo continua certo mesmo com o app minimizado ou fechado.
- **Testes:** `test/timer_math_test.dart`.

### `lib/domain/stats/study_stats.dart`
- **Função:** tempo por dia, semana e matéria; sequência de dias; progresso de metas; média diária.
- **Testes:** `test/study_stats_test.dart`.

### `lib/features/onboarding/onboarding_screen.dart`
- **Função:** primeira tela, que pede só o nome.

### `lib/features/subjects/`
| Arquivo | Função |
| --- | --- |
| `subject_repository.dart` | Criar, editar, arquivar e excluir matérias; criar, editar, reordenar, mover e excluir itens da árvore (com transações). |
| `content_tree.dart` | Transforma a lista do banco em árvore: ordem, profundidade, descendentes, caminho ("Repetição › for"). |
| `subjects_screen.dart` | Lista de matérias e tela de arquivadas. |
| `subject_form.dart` | Formulário da matéria. |
| `subject_detail_screen.dart` | Matéria + árvore de conteúdos com todas as ações. |
| `node_form.dart` | Formulário de assunto/tópico/subtópico. |

### `lib/features/timer/`
| Arquivo | Função |
| --- | --- |
| `session_repository.dart` | Iniciar, pausar, retomar, finalizar, cancelar, registro manual, edição. Cada ação grava na hora. |
| `timer_controller.dart` | Acompanha a sessão ativa e redesenha o relógio a cada segundo. O tique serve **só** para a tela: o tempo vem dos horários gravados. |
| `timer_screen.dart` | Tela do cronômetro. |
| `manual_session_screen.dart` | Registro manual e edição de sessões. |

### `lib/features/planning/`
- `plan_repository.dart`: atividades planejadas e cópia de semana.
- `planning_screen.dart`: semana com planejado × estudado de verdade e formulário de atividade.

### `lib/features/dashboard/dashboard_screen.dart`
- **Função:** tela inicial com resumo e cards ocultáveis (lista em `DashboardCards`, em `settings_controller.dart`).

### `lib/features/history/history_screen.dart` e `lib/features/reports/reports_screen.dart`
- Histórico com filtro, edição e exclusão; relatórios de produtividade calculados das sessões reais.

### `lib/features/settings/`
- `settings_repository.dart`: perfil e configurações no banco.
- `settings_controller.dart`: mantém preferências em memória e salva cada alteração.
- `settings_screen.dart`: perfil, metas, temas, modo e cor de destaque. **Ao lançar versão nova, atualize `appVersion` aqui.**

---

## Build e distribuição

| Arquivo | Função |
| --- | --- |
| `pubspec.yaml` | Nome, versão e dependências. A versão (`0.1.0+1`) é usada nos nomes dos instaladores. |
| `tool/prepare_platforms.sh` | Gera `android/` e `windows/`, aplica o nome "Ponto Study", gera o código do banco e os ícones. |
| `installer/ponto_study.iss` | Instalador do Windows (Inno Setup). **Não altere o `AppId`.** |
| `.github/workflows/build.yml` | Testes → APK → instalador Windows (com teste de instalação) → Release quando há tag `v*`. |
| `assets/icon/` | Ícone do app (`icon.png`) e camada do ícone adaptativo Android (`icon_foreground.png`). |

## Testes

| Arquivo | O que verifica |
| --- | --- |
| `test/timer_math_test.dart` | Cálculo de tempo com pausas, pausa em andamento, relógio ajustado para trás. |
| `test/study_stats_test.dart` | Semana, períodos, por matéria, sequência de dias, metas, média. |
| `test/database_test.dart` | Perfil, configurações, matérias, hierarquia, reordenar, mover sem ciclos, excluir, cronômetro completo, recuperação de sessão, registro manual, planejamento e chaves estrangeiras. |
| `test/app_flow_test.dart` | Abre o app, informa o nome e confirma que o Início aparece. |
