# Ponto Study

Aplicativo local de controle e planejamento de estudos. Sem servidor,
sem login, sem internet — todos os dados ficam salvos no seu próprio
dispositivo (Android, Windows ou navegador).

Esta é a **Etapa 1** do projeto: banco de dados, cadastro de matérias,
dashboard, registro de estudo, cálculo automático de horas, validações,
confirmação de exclusão e testes automatizados.

---

## 1. Tecnologias usadas

| Tecnologia | Para que serve |
|---|---|
| Flutter + Dart | Interface e lógica do app (Android, Windows e Web com um só código) |
| Drift | Banco de dados SQLite com a mesma API nas três plataformas |
| sqlite3_flutter_libs | Implementação nativa do SQLite (Android/Windows) |
| path_provider | Descobrir onde salvar o arquivo do banco no dispositivo |

Não usamos Firebase, Supabase, nem qualquer serviço online.

---

## 2. Estrutura das pastas

```
lib/
├── main.dart                  → ponto de entrada do app
├── theme/                     → cores, fontes e tema claro/escuro
│   ├── app_colors.dart
│   ├── app_text_styles.dart
│   └── app_theme.dart
├── database/                  → tudo relacionado ao SQLite
│   ├── tables.dart            → definição das tabelas
│   ├── database.dart          → consultas SQL (queries)
│   └── connection/            → como o banco é aberto em cada plataforma
├── repositories/               → CRUD puro, sem regra de negócio
│   ├── subject_repository.dart
│   └── study_session_repository.dart
├── services/                   → regras de negócio (cálculo de progresso etc)
│   ├── subject_service.dart
│   └── study_service.dart
├── screens/                    → telas do app
│   ├── root/root_screen.dart  → decide bottom nav vs sidebar
│   ├── home/home_screen.dart  → dashboard
│   ├── subjects/               → lista e formulário de matérias
│   └── study/                  → registrar sessão de estudo
├── widgets/                     → componentes reutilizáveis
│   ├── subject_card.dart
│   ├── progress_bar.dart
│   ├── stat_card.dart
│   └── custom_button.dart
└── utils/
    └── duration_utils.dart     → conversão "1h30" <-> minutos
```

**Regra geral do projeto**: `screens` chamam `services`, `services`
chamam `repositories`, `repositories` chamam `database`. Nunca o
caminho inverso.

---

## 3. Instalando o ambiente

### 3.1 Instalar o Flutter
1. Baixe em https://docs.flutter.dev/get-started/install
2. Extraia e adicione a pasta `flutter/bin` ao PATH do sistema.
3. Rode no terminal: `flutter doctor` e resolva os itens marcados com "✗".

### 3.2 Configurar Android Studio (necessário para Android)
1. Instale o Android Studio.
2. Abra "SDK Manager" e instale o Android SDK + um emulador (ou conecte
   um celular físico com "Depuração USB" ativada).

### 3.3 Configurar Windows (necessário para gerar o app Windows)
1. Instale o "Desktop development with C++" pelo Visual Studio Installer
   (Community Edition é suficiente).
2. Rode: `flutter config --enable-windows-desktop`

### 3.4 Configurar VS Code
1. Instale as extensões "Flutter" e "Dart".
2. Abra a pasta do projeto no VS Code.

---

## 4. Colocando o projeto para rodar

Este ZIP contém apenas a pasta `lib/` e os arquivos de configuração —
ainda faltam as pastas `android/`, `windows/` e `web/`, que o próprio
Flutter gera para você. Faça assim:

```bash
# 1. Descompacte o Ponto_Study.zip em uma pasta temporária
# 2. Crie um projeto Flutter novo com o mesmo nome, EM OUTRO LOCAL:
flutter create ponto_study
cd ponto_study

# 3. Apague a pasta lib/ e o pubspec.yaml gerados automaticamente,
#    e substitua pelos arquivos que vieram no ZIP (lib/ e pubspec.yaml)

# 4. Instale as dependências:
flutter pub get

# 5. Gere o código do banco de dados (isso cria database.g.dart):
dart run build_runner build --delete-conflicting-outputs
```

A partir daqui o projeto está pronto para rodar.

---

## 5. Executando

**Android** (emulador ligado ou celular conectado):
```bash
flutter run
```

**Windows**:
```bash
flutter run -d windows
```

**Web** — precisa de um passo extra (veja seção 7 abaixo antes de rodar):
```bash
flutter run -d chrome
```

---

## 6. Gerando os aplicativos finais

**APK Android:**
```bash
flutter build apk --release
```
O arquivo fica em `build/app/outputs/flutter-apk/app-release.apk`.

**Executável Windows:**
```bash
flutter build windows --release
```
Os arquivos ficam em `build/windows/x64/runner/Release/`. Copie a
pasta inteira para instalar em outro PC (o `.exe` sozinho não roda
sem as DLLs ao lado).

---

## 6.1 Rodando os testes automatizados

O projeto tem testes para as partes mais importantes: conversão de
tempo, validação de matérias, cálculo de progresso e o comportamento
de "excluir matéria" (que na verdade arquiva — veja seção 8.1).

```bash
flutter test
```

Para rodar um arquivo específico:
```bash
flutter test test/subject_service_test.dart
```

---

## 7. Rodando na Web (passo manual necessário)

O SQLite no navegador usa uma versão compilada para WebAssembly. Dois
arquivos precisam estar na pasta `web/` do seu projeto:

- `sqlite3.wasm`
- `drift_worker.js`

Depois de rodar `flutter pub get`, copie esses arquivos do pacote
`sqlite3` e do `drift` (instruções atualizadas em
https://drift.simonbinder.eu/platforms/web/ — o comando exato pode
mudar conforme a versão do pacote, então vale conferir a documentação
oficial se algo não funcionar).

Sem esses dois arquivos, a versão Web abre mas não consegue salvar
dados.

---

## 8.1 O que acontece quando você "exclui" uma matéria

Excluir uma matéria **não apaga nada do banco**. Na verdade, ela é
"arquivada": a coluna `archived` (em `lib/database/tables.dart`)
muda de `false` para `true`. A matéria some das suas listas ativas
(dashboard, "Minhas Matérias"), mas todas as sessões de estudo dela
continuam gravadas no banco, intactas.

Isso foi uma escolha deliberada: como os dados ficam só no seu
dispositivo, sem backup automático, um "excluir" que apagasse o
histórico de verdade poderia custar horas de estudo registradas sem
chance de desfazer. A tela de exclusão (em
`add_edit_subject_screen.dart`) já avisa quantas sessões e quantas
horas aquela matéria tem antes de pedir a confirmação.

Se no futuro você quiser mesmo apagar esses dados de vez (por
exemplo, numa tela "Matérias arquivadas" com opção de excluir
definitivamente), seria necessário adicionar um novo método em
`AppDatabase` que faça um `delete(subjects)` de verdade — hoje esse
método não existe de propósito, para que nenhuma tela apague dados
por engano.

---

## 8. Como alterar coisas comuns

| Quero alterar... | Onde mexer |
|---|---|
| Cor principal do app | `lib/theme/app_colors.dart`, variável `primary` |
| Tamanho de fontes | `lib/theme/app_text_styles.dart` |
| Arredondamento dos cards/botões | `lib/theme/app_theme.dart`, variável `borderRadius` |
| Textos da tela inicial | `lib/screens/home/home_screen.dart` |
| Ícones disponíveis para matérias | `lib/screens/subjects/add_edit_subject_screen.dart`, lista `icons` |
| Adicionar uma nova coluna no banco | `lib/database/tables.dart` + rodar `build_runner build` de novo |
| Adicionar uma nova aba de navegação | `lib/screens/root/root_screen.dart` |

## 9. Adicionando uma nova tela

1. Crie o arquivo em `lib/screens/<nome-da-feature>/minha_tela.dart`.
2. Se ela precisar de dados, injete o `service` correspondente pelo
   construtor (veja `HomeScreen` como exemplo).
3. Se for uma aba nova (visível na navegação), registre-a em
   `lib/screens/root/root_screen.dart`.

## 10. O que ainda falta (próximas etapas)

- Cronômetro de estudo
- Planejamento diário/semanal
- Histórico com filtros
- Relatórios com gráficos
- Backup/exportação em JSON
- Perfil do usuário e onboarding
- Temas prontos (Oceano, Sakura, etc)
- Identidade visual "○ Study" (logo)

Essas features fazem parte das Etapas 2 a 5, combinadas anteriormente.
