# Roube Minérios Hub

Painel colaborativo da equipe do jogo Roube Minérios no Roblox. Migração recuperada em 09/09/2026.

Leia primeiro [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) e [AGENTS.md](AGENTS.md).

- `site/`: os três HTML obtidos diretamente do domínio oficial, preservados sem alterações.
- `src/`: os mesmos conteúdos desktop/mobile descompactados para leitura e edição; o index é idêntico ao publicado.
- `database/`: metadados e funções SQL existentes, somente referência. Não são migrations para executar.
- `recovered-functions/`: fontes de Edge Functions, incluindo fontes históricas; não publicar automaticamente.
- `MANIFEST.json`: origem, tamanho e SHA-256 dos arquivos.

Para examinar localmente: `python -m http.server 8080 --directory src` e abra `http://localhost:8080`.
O frontend ainda aponta para o Supabase real: fazer login e usar ações pode alterar dados reais. Não há banco de teste neste pacote.

O repositório não contém dados privados, senhas, hashes de acesso, sessões ou service-role key. O backup de conteúdo foi guardado separadamente, somente no computador do proprietário.

Nenhum deploy, alteração de DNS ou alteração de banco faz parte desta migração. Preservar o projeto Supabase existente é essencial para manter os dados.
