# Ponto Study

Plataforma local de estudos para **Windows** e **Android**. Com ela você organiza matérias em árvore (Matéria → Assunto → Tópico → Subtópico), registra o tempo com um cronômetro confiável, planeja a semana e acompanha sua evolução em relatórios. Tudo fica salvo no seu aparelho, sem login e sem internet.

> **Versão atual: 0.1.0** — Etapas 1 e 2 do roadmap (fundação e controle de estudos).
> Questões, avaliações, sistema de domínio e revisões chegam na Etapa 3; a IA, na Etapa 4.

---

## 1. Como instalar

Baixe os arquivos na página **[Releases](https://github.com/isoucyber/ponto_study/releases/latest)**.

### Windows 10 / 11

1. Baixe `PontoStudy-Setup-<versão>.exe`.
2. Abra o arquivo. Na primeira vez, o Windows pode mostrar **"O Windows protegeu o computador"** (SmartScreen). Isso aparece porque o app não tem um certificado digital pago, e não quer dizer que haja algo errado com ele. Clique em **Mais informações → Executar assim mesmo**.
3. Siga o instalador. Ele cria os atalhos no **menu Iniciar** e na **área de trabalho**.
4. Para desinstalar: *Configurações do Windows → Aplicativos → Ponto Study → Desinstalar*.

Prefere não instalar? Baixe `PontoStudy-<versão>-Windows-portatil.zip`, extraia e abra `ponto_study.exe`.

### Android

1. Baixe `PontoStudy-<versão>.apk` no celular.
2. Toque no arquivo. Se o Android pedir, permita **"Instalar apps desconhecidos"** para o navegador ou gerenciador de arquivos.
3. Toque em **Instalar** e abra o **Ponto Study**.

> **Atualizações no Android:** cada versão do `.apk` é assinada automaticamente pelo GitHub. Se o Android recusar a atualização ("conflito de pacote"), faça backup dos dados (disponível a partir da Etapa 3), desinstale e instale de novo. Isso deixa de acontecer quando a chave de assinatura fixa for configurada (veja [docs/ASSINATURA_ANDROID.md](docs/ASSINATURA_ANDROID.md)).

---

## 2. Como usar

| Seção | O que faz |
| --- | --- |
| **Início** | Tempo de hoje e da semana, metas, sequência de dias, planejado para hoje, matérias na semana e últimas sessões. Use **Personalizar** para ocultar cards. |
| **Matérias** | Crie matérias (nome, ícone, cor, prioridade, meta semanal). Dentro delas, crie assuntos, tópicos e subtópicos em quantos níveis quiser. Pelo menu ⋮ de cada item você pode adicionar subitens, editar, mover para cima ou para baixo, mover para outro item ou excluir. |
| **Estudar** | Escolha a matéria (e, se quiser, o assunto) e inicie o cronômetro. Pausar, retomar, finalizar e cancelar. Pode minimizar ou fechar o app: o tempo continua certo. Para algo que você já estudou, use **Registro manual**. |
| **Planejamento** | Monte a semana dia a dia, com horário, duração e prioridade. "Estudar agora" inicia o cronômetro. Marcar uma atividade como concluída **não** cria horas: horas só vêm de sessões reais. |
| **Histórico** | Todas as sessões por dia, com filtro por matéria. Dá para editar e excluir. |
| **Relatórios** | Total, média diária, dias com estudo, meta batida, horas por dia e por matéria, e comparação com o período anterior. |
| **Configurações** | Nome, avatar, objetivo, metas, 6 temas (Dark Forest, Rainy Day, Sunset, Beach, Dark Academia, Minimalista), modo claro/escuro e cor de destaque. |

**Onde ficam os dados:** num banco SQLite na pasta de dados do app. O caminho exato aparece em *Configurações → Seus dados*.

---

## 3. Para desenvolvedores

### Tecnologias

- **Flutter 3.47 / Dart 3** — uma única base de código para Windows e Android.
- **Drift + SQLite** — banco local tipado, com migrações e transações.
- **GitHub Actions** — testes, compilação e publicação dos instaladores.
- **Inno Setup** — instalador do Windows.

### Estrutura

```
lib/
├── main.dart                  # início do app
├── app/                       # MaterialApp, navegação (shell) e AppScope
├── core/
│   ├── database/              # tabelas e abertura do banco (Drift)
│   ├── theme/                 # 6 temas + decorações de fundo
│   ├── utils/                 # formatação de tempo e datas
│   └── widgets/               # componentes reutilizáveis
├── domain/                    # cálculos puros (tempo, estatísticas) — sem tela e sem banco
└── features/                  # um módulo por pasta
    ├── onboarding/  dashboard/  subjects/  timer/
    └── planning/    history/    reports/   settings/
test/                          # testes automáticos
tool/prepare_platforms.sh      # gera android/ e windows/ e aplica nome/ícone
installer/ponto_study.iss      # script do instalador Windows
.github/workflows/build.yml    # automação do GitHub
docs/                          # documentação em português
```

O guia detalhado de cada arquivo está em **[docs/ARQUITETURA.md](docs/ARQUITETURA.md)**.

### Rodar no seu computador

Pré-requisitos: [Flutter](https://docs.flutter.dev/get-started/install) e, para Windows, o Visual Studio com "Desenvolvimento para desktop com C++".

```bash
bash tool/prepare_platforms.sh windows   # ou: android
flutter run -d windows                   # ou: flutter run (celular conectado)
flutter test                             # testes
```

No Windows, rode o primeiro comando no **Git Bash**.

### Publicar uma nova versão

1. Atualize `version:` em `pubspec.yaml`, `appVersion` em `lib/features/settings/settings_screen.dart` e o `CHANGELOG.md`.
2. Crie `docs/releases/vX.Y.Z.md` com as notas da versão.
3. Envie para o branch `main`.

O GitHub Actions roda os testes, compila Android e Windows, testa a instalação e o uso no Windows e num emulador Android e, se tudo passar, cria a tag `vX.Y.Z` e publica a Release com todos os arquivos.

### Segurança

Nenhuma senha, token ou chave é guardada no repositório (veja `.gitignore`). Chaves de assinatura e de API devem ficar nos *Secrets* do GitHub ou no cofre do sistema operacional.
