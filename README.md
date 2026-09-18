# Carteira Consórcio — Vendas & Comissões

App de controle de vendas e comissões de consórcio, com banco de dados real
(Supabase) e hospedagem própria (Vercel). Leva uns 10-15 minutos para configurar.

Aviso importante: eu (Claude) não tenho como criar a conta ou fazer o deploy
por você — não tenho acesso à sua conta Supabase nem Vercel. Os passos abaixo
são só cliques e colar/copiar, sem precisar programar.

---

## Passo 1 — Criar o projeto no Supabase (banco de dados)

1. Acesse **https://supabase.com** e crie uma conta gratuita (dá para entrar
   com GitHub ou Google).
2. Clique em **New project**.
3. Escolha um nome (ex.: `consorcio`), uma senha de banco (guarde-a, mas você
   não vai precisar dela no dia a dia) e a região mais próxima (ex.: São Paulo).
4. Aguarde ~2 minutos até o projeto ficar pronto.

## Passo 2 — Criar as tabelas

1. No menu lateral do Supabase, clique em **SQL Editor** → **New query**.
2. Abra o arquivo `schema.sql` (nesta mesma pasta), copie todo o conteúdo e
   cole no editor.
3. Clique em **Run**. Deve aparecer "Success. No rows returned".

Isso cria as tabelas `sales`, `receipt_overrides` e `settings`, já com as
permissões de acesso e a sincronização em tempo real configuradas.

## Passo 3 — Pegar sua URL e chave do projeto

1. No menu lateral, vá em **Project Settings** (ícone de engrenagem) →
   **API**.
2. Copie o valor de **Project URL** (algo como `https://xxxxx.supabase.co`).
3. Copie o valor de **anon public** (uma chave longa, começando com `eyJ...`).
   Essa é a chave "pública" feita para ir dentro do site — não é a chave
   secreta (`service_role`), que você **nunca** deve colocar aqui.

## Passo 4 — Colar as credenciais no app

1. Abra o arquivo `index.html` (nesta pasta) em qualquer editor de texto.
2. Procure por estas duas linhas, perto do início do `<script>`:
   ```js
   var SUPABASE_URL = "COLE_AQUI_A_SUA_SUPABASE_URL";
   var SUPABASE_ANON_KEY = "COLE_AQUI_A_SUA_SUPABASE_ANON_KEY";
   ```
3. Substitua pelos valores que você copiou no Passo 3, por exemplo:
   ```js
   var SUPABASE_URL = "https://xxxxx.supabase.co";
   var SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";
   ```
4. Salve o arquivo.

## Passo 5 — Publicar no Vercel

Duas formas, escolha a que preferir:

### Opção A — sem instalar nada (recomendada)
1. Acesse **https://vercel.com** e crie uma conta gratuita.
2. Crie um repositório novo no **GitHub** (github.com → New repository) e
   suba estes arquivos para lá (pelo site do GitHub dá para arrastar os
   arquivos direto, em "Add file → Upload files").
3. No Vercel, clique em **Add New → Project**, escolha **Import Git
   Repository** e selecione o repositório que você acabou de criar.
4. Não precisa mudar nenhuma configuração (é um site estático). Clique em
   **Deploy**.
5. Em ~30 segundos você recebe um link tipo `https://consorcio-xxxx.vercel.app`.

### Opção B — pelo terminal (se você tem Node.js instalado)
Dentro desta pasta, rode:
```bash
npx vercel login
npx vercel --prod
```
Siga as instruções na tela (a primeira vez ele pergunta o nome do projeto —
pode aceitar o padrão). Ao final ele mostra o link do site publicado.

## Passo 6 — Testar com os dois

1. Abra o link do Vercel no seu navegador e cadastre uma venda de teste.
2. Mande o mesmo link para sua namorada. Ela deve ver a mesma venda
   aparecer, e qualquer alteração de um lado aparece automaticamente do
   outro (a aba se atualiza sozinha, sem precisar dar F5).
3. Confira na barra lateral do app: deve aparecer **"Sincronizado
   (Supabase)"** com uma bolinha verde. Se aparecer "Salvo só neste
   navegador" (bolinha amarela), confira se colou as credenciais certas no
   Passo 4 e se rodou o `schema.sql` no Passo 2.

---

## Sobre segurança dos dados

Este é um acesso simples ("quem tem o link e a chave, acessa"), sem
login/senha individual — o mesmo espírito de uma planilha do Google
compartilhada por link. É suficiente para uso pessoal entre vocês dois,
mas **qualquer pessoa que descobrir o link do site e abrir o código-fonte
consegue ver a URL e a chave do Supabase** (elas ficam visíveis no
JavaScript da página, isso é normal e esperado para a chave `anon`).

Se no futuro você quiser login de verdade (com senha, só vocês dois
autenticados), o Supabase tem isso pronto (Supabase Auth) — é um passo a
mais de configuração. É só pedir que eu ajusto o app e as políticas de
acesso (RLS) para exigir login.

## Limites do plano gratuito

O plano grátis do Supabase inclui banco de até 500 MB e é mais que
suficiente para milhares de vendas e parcelas — não é algo com que você
precisa se preocupar no uso pessoal. O Vercel no plano grátis também é mais
que suficiente para um site estático como este.

## Arquivos desta pasta

- `index.html` — o app completo (é só isso que vai para o Vercel).
- `schema.sql` — script para rodar uma vez no Supabase (Passo 2).
- `README.md` — este guia.
