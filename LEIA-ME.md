# Ronda Hospitalar · publicação com base compartilhada

São 3 arquivos: `index.html` (o sistema), `supabase-setup.sql` (prepara o banco) e este guia.

## 1. Criar o banco gratuito (Supabase) — 5 minutos
1. Crie uma conta em https://supabase.com e um **New project** (anote a senha do banco, você não vai precisar dela no sistema).
2. Abra **SQL Editor → New query**.
3. Abra o `supabase-setup.sql`, troque `TROQUE-ESTE-CODIGO` por um **código de acesso longo** (16+ caracteres, só a equipe sabe) e cole tudo no editor. Clique **Run**. Deve aparecer "Success".
4. Vá em **Project Settings → API** e copie:
   - **Project URL** (ex.: `https://abcdefgh.supabase.co`)
   - a chave **anon public** (ou **publishable**)

## 2. Ligar o sistema ao banco
No `index.html`, no começo do arquivo, preencha as duas linhas:

```js
window.RONDA_CONFIG={
  supabaseUrl:"https://abcdefgh.supabase.co",
  supabaseKey:"sua-chave-anon-ou-publishable"
};
```

## 3. Publicar no GitHub Pages
1. Crie um repositório no GitHub e envie o `index.html` para a raiz.
2. **Settings → Pages →** branch `main`, pasta `/ (root)` → Save.
3. O endereço sai em `https://seu-usuario.github.io/nome-do-repositorio/`.

## 4. Primeiro uso
1. Cada aparelho digita o **código de acesso da equipe** na primeira vez (fica salvo no aparelho).
2. O primeiro a entrar cria o administrador na tela "Primeiro acesso".
3. O administrador cadastra os demais usuários em **Cadastros → Responsáveis e usuários**.

## Como a segurança funciona
- As tabelas do banco **não têm acesso público**. Toda leitura e gravação passa por funções que exigem o código de acesso da equipe.
- A chave `anon` fica visível no código da página, e isso é normal: sem o código ela não abre nada.
- O login com usuário e senha dentro do sistema define o perfil de cada pessoa (administrador, gestor, inspetor).
- O código de acesso é um segredo **compartilhado**: quem o tem consegue ler os dados (inclusive os hashes de senha dos usuários). Não divulgue o código fora da equipe. Para trocar, edite o texto no final do `supabase-setup.sql` e execute de novo; todos os aparelhos pedem o novo código.
- Para exigir contas individuais no nível do banco, o próximo passo seria usar o Supabase Auth.

## Observações
- A tela atualiza sozinha a cada ~4 segundos. Sem internet, aparece um aviso e o sistema reconecta sozinho.
- Fotos das não conformidades e dos equipamentos ficam no banco (plano gratuito: 500 MB).
- Projetos gratuitos do Supabase são pausados após cerca de 1 semana sem uso. Basta reativar no painel do Supabase.
- Em **Cadastros → Hospital** há exportação e importação de backup (`.json`, inclui fotos).
- Deixando `supabaseUrl` e `supabaseKey` vazios, o sistema funciona só no navegador, sem compartilhamento.
