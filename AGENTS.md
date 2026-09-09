# Instruções para trabalhar neste projeto

Leia PROJECT_CONTEXT.md antes de qualquer mudança. O proprietário autorizou a migração dos arquivos para GitHub; isso não autoriza deploy em produção nem mudanças no Supabase.

1. Não recrie o projeto Supabase bjypwenzgusuojaewffq. Não execute reset, seed, migrations ou SQL de referência contra produção.
2. Não apague, sobrescreva ou renumere dados existentes. Não mude credenciais, funções RPC, sessões, buckets ou políticas sem autorização específica.
3. Trabalhe em branch codex/ e valide desktop e mobile juntos. Não promova, publique ou altere DNS/aliases sem aprovação.
4. site/ é o snapshot original; faça alterações de desenvolvimento em src/. Não substitua o original por versões históricas sem comparação.
5. Nunca coloque backups de dados, senhas, hashes de acesso, tokens de sessão, .env ou chaves secretas no GitHub. A chave publishable que já está no frontend não é uma service-role key.
6. Não suponha que um preview usa dados isolados: por padrão o código aponta para produção. Testes de escrita exigem ambiente de teste ou autorização.
7. Corrigir RLS é uma pendência real, mas deve ser planejado e testado sem interromper as RPCs de autenticação própria.
8. Não confunda READY com validação funcional; registre exatamente quais testes foram realizados e quais não foram.
