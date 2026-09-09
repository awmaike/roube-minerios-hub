# Roube Minérios Hub — contexto do projeto

## Objetivo

Hub privado da equipe do jogo Roblox **Roube Minérios**. Centraliza ideias, galeria, decisões, comentários e chat para os três membros do projeto.

## Stack

- Frontend estático: HTML, CSS e JavaScript puro.
- Backend e dados: Supabase (Postgres, RPCs, Edge Function e Storage).
- Hospedagem: Vercel.

## Estrutura principal

- `index.html`: seleciona desktop ou mobile por largura de tela.
- `desktop.html` e `mobile.html`: arquivos publicados na raiz.
- `src/`: fontes legíveis de desktop, mobile e index; é onde editar o frontend.
- `database/`: referência das funções e estrutura do Supabase; não executar SQL de referência em produção sem autorização.
- `site/`: snapshot histórico dos arquivos publicados.

## Serviços oficiais

- GitHub: https://github.com/awmaike/roube-minerios-hub
- Vercel: projeto `roube-minerios-hub`, escopo `maike4`.
- Site oficial: https://hubminer.maikedev.com.br
- Supabase: projeto `bjypwenzgusuojaewffq` (`https://bjypwenzgusuojaewffq.supabase.co`).

## Variáveis de ambiente

Os nomes usados pelo backend são `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY`. Nunca registrar valores, senhas, chaves, tokens de sessão ou arquivos `.env` no GitHub.

## Como trabalhar e publicar

Não há `package.json` nem etapa de build do projeto original. Edite os arquivos em `src/`; antes de publicar, gere ou atualize os três arquivos finais `index.html`, `desktop.html` e `mobile.html` na raiz do pacote de publicação.

O deploy atual é feito diretamente no projeto Vercel `maike4/roube-minerios-hub` como produção. O GitHub registra o código, mas não está conectado para deploy automático. Depois de publicar, conferir o domínio oficial em desktop e mobile.

## O que está funcionando

- Login fechado por usuário do Hub e sessão própria.
- Ideias, comentários, galeria, decisões e chat.
- Desktop e mobile publicados no domínio oficial.
- Edição de ideias valida autoria pelo identificador real do membro; a ideia existente de Devill está vinculada ao seu membro.

## Cuidados

Não recriar o projeto Supabase, executar reset/seed, apagar dados, trocar credenciais, alterar RLS ou publicar sem autorização explícita. Mudanças pequenas devem manter desktop e mobile consistentes.
