# Assinatura fixa do APK (Android)

## Por que isso importa

O Android só aceita **atualizar** um app instalado se a versão nova for assinada com **a mesma chave** da anterior. Sem uma chave fixa, cada build do GitHub usa uma chave temporária diferente. Aí o Android recusa a atualização, e seria preciso desinstalar o app, o que apaga os dados do celular.

A chave é um **segredo**: quem tem a chave pode publicar "atualizações" do seu app. Por isso ela **não fica no repositório**. Ela fica nos *Secrets* do GitHub, que são criptografados e só o workflow consegue ler.

## Como configurar (uma única vez, leva 3 minutos)

Você recebeu dois arquivos: `ponto_study_upload.jks` (a chave) e `ponto_study_upload.jks.base64.txt` (a mesma chave em texto), além da senha.

1. Abra o repositório no GitHub → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.
2. Crie estes 4 segredos:

| Nome | Valor |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | todo o conteúdo do arquivo `ponto_study_upload.jks.base64.txt` |
| `ANDROID_KEYSTORE_PASSWORD` | a senha recebida |
| `ANDROID_KEY_PASSWORD` | a mesma senha |
| `ANDROID_KEY_ALIAS` | `pontostudy` |

3. Rode o workflow de novo (aba **Actions** → última execução da tag → **Re-run all jobs**) ou publique a próxima versão.

No log do passo "Assinar APK" deve aparecer: *APK assinado com a chave fixa do Ponto Study.*

## Guarde a chave em local seguro

Faça uma cópia de `ponto_study_upload.jks` e da senha (por exemplo, num gerenciador de senhas). Se a chave for perdida, as próximas versões não poderão atualizar o app já instalado.
