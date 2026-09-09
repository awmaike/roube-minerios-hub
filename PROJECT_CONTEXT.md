# PROJECT_CONTEXT — Roube Minérios Hub

Documento de passagem para Codex, preparado em 09/09/2026. Fonte histórica: conversa “Criar jogo temático no Roblox”, ID `6aa032db-0238-83e9-a3d2-9fcaf4f3032e`. O histórico foi tratado como relato; fatos atuais abaixo foram conferidos nos arquivos públicos e nas consultas somente leitura do Supabase/GitHub.

## 1. Objetivo e limite da migração

O Hub organiza ideias, mapas, referências, decisões e conversas de uma equipe de três pessoas que desenvolve um jogo de minérios no Roblox. Este repositório é o site de colaboração, não o jogo Roblox: não recuperamos arquivo .rbxl, modelos 3D ou scripts Luau do jogo.

O pedido inicial foi reunir arquivos e contexto sem alterar produção nem GitHub. Depois o proprietário autorizou explicitamente preencher o repositório vazio com o projeto e a documentação, reforçando que não pode perder os dados existentes. Essa autorização não inclui publicar o site, migrar o banco ou corrigir produção.

**Migrar para Codex significa versionar o código e abrir o repositório no Codex. Não significa criar um banco novo.** O frontend deve continuar usando o Supabase existente quando uma futura publicação for autorizada. Não executar SQL desta pasta, resets, seeds, recriação de tabelas, importações ou limpeza de Storage para “instalar” o projeto.

## 2. Identificadores e estado confirmado

| Recurso | Referência / estado |
|---|---|
| Site oficial | https://hubminer.maikedev.com.br |
| GitHub | https://github.com/awmaike/roube-minerios-hub |
| Estado inicial do GitHub | Público, branch padrão main, tamanho 0; Contents API respondeu explicitamente “This repository is empty.” |
| Vercel, nome histórico | roube-minerios-hub |
| Escopo Vercel | maike4; team_7wyW0xsevE4JYvub2aqY2nww, informado pelo erro de autorização |
| URL Vercel histórica | https://roube-minerios-hub-maike4.vercel.app |
| Supabase | bjypwenzgusuojaewffq |
| API Supabase | https://bjypwenzgusuojaewffq.supabase.co |
| Nome/região históricos do banco | Roube Minerios Hub, São Paulo / sa-east-1; não reconfirmados no painel nesta migração |
| Último deploy relatado | dpl_BZLRCDjMQKX5AF7YQ7mRGKaFCe5p, dito READY no histórico |
| Backup aprovado pelo usuário | dpl_A4U8oYQSk3qTL3agMeBXQAKazFJS |

Nesta migração `/index.html`, `/desktop.html` e `/mobile.html` responderam HTTP 200, Content-Type text/html; seus bytes foram baixados diretamente do domínio oficial. O conector Vercel não listou equipes e negou consultas do projeto/deploy com HTTP 403. Portanto não foi possível confirmar o ID do deploy associado hoje ao domínio, configurações de build, vínculo Git ou proteção de previews. O status READY mencionado acima é histórico, não verificação atual.

## 3. Arquivos recuperados e como usá-los

`site/index.html` tem 365 bytes e decide a versão usando `matchMedia('(max-width:760px)')`, redirecionando com `location.replace` para `/mobile.html` ou `/desktop.html`. A escolha ocorre ao abrir o index; não é um sistema que troca automaticamente de aplicativo a cada resize.

`site/desktop.html` tem 19.402 bytes e `site/mobile.html` tem 9.178 bytes. São wrappers com HTML gzip codificado em Base64 dentro do próprio arquivo. Eles usam `atob`, `Uint8Array`, `Blob`, `DecompressionStream('gzip')`, `Response.text()` e `document.write()` para abrir o conteúdo. Não precisam buscar outro HTML de um preview remoto. Ainda dependem de JavaScript e suporte a DecompressionStream.

`src/desktop.html` (49.683 bytes) e `src/mobile.html` (19.867 bytes) são o resultado exato da descompactação, com HTML/CSS/JavaScript legíveis, sem refatoração. `src/index.html` é cópia do index. A igualdade entre o payload descompactado e src deve ser preservada no snapshot inicial. O frontend é estático, com JavaScript no próprio HTML; não foi encontrado um projeto React/Next nem package.json original. Não inventar uma cadeia de build como se fosse a original.

O desktop referencia Google Fonts (Inter) e CDN jsDelivr de supabase-js v2. As chamadas examinadas à aplicação usam fetch para RPCs HTTP. O mobile não tem dependência externa de script declarada no HTML. Ambos dependem da rede para dados.

`recovered-functions/` preserva cinco fontes recuperadas da API administrativa Supabase. `chat-upload` é backend de upload usado pelo site. As outras são fontes históricas, não equivalentes automaticamente ao conteúdo atual:

| Função | Papel |
|---|---|
| desktop-stable-final | HTML compactado embutido; fonte histórica recuperável |
| desktop-v3-source | Busca HTML em preview Vercel desktop-ideas-preview-3; dependência externa antiga |
| mobile-stable-source | Busca wrapper mobile-comments-packed.html e fragmentos .txt em deploy Vercel antigo |
| mobile-chat-image-preview | HTML compactado do experimento de imagem mobile |
| chat-upload | Recebe multipart, valida sessão própria, envia imagem ao Storage |

Outras funções listadas ACTIVE: desktop-ideas-preview, desktop-ideas-preview-cors, hub-enhancements-preview e mobile-chat-image-preview-file. Não foram exportadas suas fontes; não são necessárias ao carregamento dos três HTML atuais. Não apagar nenhuma função porque parece antiga: o uso externo não foi auditado.

## 4. Arquitetura de dados e autenticação

Fluxo principal: navegador → `/rest/v1/rpc/hub_login` → token próprio do Hub → `/rest/v1/rpc/hub_api` com p_token/p_action/p_payload → PostgreSQL. Upload do chat: navegador → `/functions/v1/chat-upload` com x-hub-token e arquivo → validação via hub_api bootstrap → Storage project-media → URL retornada → sendChatMessage grava referência.

Os HTML contêm a URL do Supabase e uma chave **publishable**, já pública no site. Ela identifica o projeto e não é a senha do usuário nem a chave service_role. Não colocar service-role key, credenciais administrativas, senhas ou token de sessão no código. A função chat-upload lê SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY do ambiente no servidor; somente os nomes estão exportados.

### Login atual versus login antigo

No início houve cadastro por email via Supabase Auth, problemas de limite de envio e retorno para localhost:3000. Depois a equipe escolheu login fechado por nome de usuário, sem cadastro público e sem email na interface. Os nomes históricos são Devill (administrador), seA e Carafull (membros). Senhas do histórico não foram copiadas para este pacote.

O login atual é customizado em PostgreSQL, não uma chamada signInWithPassword do Supabase Auth. `hub_login(p_user,p_secret)` compara lower(login_name) com lower(trim(p_user)), exige active=true e compara SHA-256(salt concatenado com senha). Gera 32 bytes aleatórios representados em hexadecimal, guarda somente o SHA-256 do token em hub_sessions e devolve token/name/role ao frontend.

No login a função elimina sessões anteriores daquele membro e sessões expiradas. A expiração padrão é 30 dias. Portanto entrar com o mesmo membro em outro navegador pode invalidar a sessão anterior. Os tokens são guardados em localStorage pelo frontend (mobile usa rm_token; desktop usa roube_minerios_token).

`hub_api` valida hash do token, validade e active=true a cada chamada. É SECURITY DEFINER com search_path public,extensions. `hub_delete_comment` tem a mesma abordagem. Essas funções têm acesso concedido a anon/authenticated; a permissão de negócio depende da validação interna, não de uma sessão Supabase Auth. Não substituir por políticas auth.uid() sem redesenhar e testar esse fluxo.

As tabelas antigas profiles e colunas author_id ligadas a auth.users continuam existindo. Operações novas usam author_name e, no chat, member_id. Muitas verificações de autoria comparam author_name com display_name, não UUID. Renomear usuários pode alterar a capacidade de editar/remover conteúdos antigos. Não fazer essa mudança sem plano.

## 5. Banco, tabelas e contratos

`database/schema.json` registra colunas, tipos, defaults, constraints, chaves e RLS observados. `hub_api.sql`, `hub_login.sql` e `hub_delete_comment.sql` são definições extraídas, marcadas como referência, não migrations. `policies.json` e `grants.json` registram políticas e grants; `grants-buckets.json` contém metadados do bucket.

| Tabela | Uso / observação |
|---|---|
| profiles | Perfil legado ligado a auth.users; RLS ligado |
| ideas | title, description, status, category, author_name, author_id legado, timestamps; RLS ligado |
| comments | idea_id, body, author_name, author_id legado, created_at; RLS ligado |
| gallery_items | título, descrição, image_url, categoria, autor; RLS ligado |
| decisions | title, details, status, autor e timestamps; RLS ligado |
| hub_members | login_name único, display_name, salt, access_hash, role, active; RLS ligado |
| hub_sessions | token_hash chave, member_id, expires_at, created_at; RLS ligado |
| chat_messages | member_id, author_name, body, image_url, created_at, edited_at; RLS desligado |
| chat_reads | member_id chave, last_read_at; RLS desligado |
| site_bundle_chunks | seq, content, updated_at; conteúdo auxiliar histórico; RLS desligado |

Estados válidos de ideia: ideia, aprovada, fazendo, finalizada, descartada. Estados de decisão: discussao, aprovado, fazendo, concluido. Não trocar esses valores por traduções da interface no banco. Categorias são texto; há opções como geral, mecanica, minerio, mapa e referencia nas interfaces.

### Ações de hub_api

| Ação | Contrato principal |
|---|---|
| bootstrap | Retorna user, ideas, gallery, decisions e chat_unread |
| listChatMessages | Últimas 200 mensagens ordenadas para exibição; contador de não lidas |
| sendChatMessage | body até 1.200 caracteres; image_url opcional com prefixo específico do Storage chat |
| editChatMessage | Somente autor; texto não vazio, até 1.200; grava edited_at |
| deleteChatMessage | Autor ou admin; remove registro, não o objeto do Storage |
| markChatRead | Upsert de last_read_at para o membro |
| createIdea / editIdea | Criação com autor da sessão; edição somente pelo autor; valida título na edição |
| updateIdeaStatus / deleteIdea | Autor ou admin |
| listComments / addComment | Consulta por idea_id / criação com autor da sessão |
| createDecision / deleteDecision | Criação autenticada / exclusão autor ou admin |
| addGallery / deleteGallery | Registra image_url / exclui registro autor ou admin |
| adminListUsers | Somente admin; retorna metadados sem hash/salt |
| adminSetActive | Somente admin; não pode desativar a si próprio; desativação elimina sessões do alvo |
| adminResetPassword | Somente admin; mínimo de 8 caracteres; gera salt, altera hash e elimina sessões |
| logout | Elimina sessão atual |

Excluir comentário usa RPC separada `hub_delete_comment(p_token,p_id)`, permitida ao autor ou admin. Não chamar uma ação deleteComment inexistente em hub_api.

## 6. Funcionalidades e diferença entre desktop/mobile

Desktop recuperado: painel Geral, ideias e filtros, criação/edição de ideia, Ler mais/Ler menos, mapas/desenhos e galeria, decisões, comentários, chat e Administração. Editar ideia é exclusivo do autor; admin pode excluir conteúdo alheio. Há confirmação de exclusão. A correção histórica do Salvar usa botão e submit explícitos, estado Salvando e refresh após RPC.

O chat desktop tem anexar imagem, prévia, remover seleção, colar print com Ctrl+V, botão desabilitado durante envio, mensagens/imagens, edição/exclusão conforme permissões. Enter envia e Shift+Enter permite nova linha. O código faz polling de chat a cada 3 segundos: não foi encontrada assinatura Realtime/WebSocket implementando esse fluxo, apesar de ter sido sugerida no histórico.

Mobile recuperado: navegação inferior Geral / Chat / Menu, ideias com edição/exclusão conforme autoria, sheet de comentários, galeria/mapas, formulário de imagens e lista administrativa de usuários. O painel administrativo mobile observado apenas lista usuários; não contém os controles completos de senha/ativação existentes no desktop. Ambos usam o mesmo projeto e os mesmos dados, mas não têm paridade integral de interface.

### Divergências verificadas — não ocultar

O último relato dizia que a versão final continha prévia de imagem mobile, envio sem texto e melhorias HEIC. **O mobile atualmente baixado não contém handler de prévia, conversão HEIC nem estado Enviando para esse fluxo**; ainda mostra “Preview mobile” no login. O formulário aceita selecionar arquivo e enviar com body vazio, mas isso não comprova que o backend aceita.

Há uma incompatibilidade concreta: hub_api permite body vazio quando image_url existe, mas a constraint de chat_messages exige char_length(body) >= 1. Enviar somente imagem pode falhar depois de fazer upload. Não foi feito envio de teste em produção. Corrigir exige alinhar constraint e RPC com autorização e testes próprios; não usar um espaço sem entender trim e edição.

## 7. Imagens e Storage

Bucket confirmado: project-media, público, limite de 10.485.760 bytes, MIME PNG/JPEG/WebP/GIF. Upload de chat tem limite menor, de 5 MiB, aplicado no frontend e na função. A função aceita POST/OPTIONS, verifica x-hub-token via bootstrap, valida MIME/tamanho, gera caminho `chat/<timestamp>-<uuid>.<ext>`, usa upsert=false e devolve URL pública.

verify_jwt=false em chat-upload significa que ela usa a autenticação própria descrita acima; não significa ausência de validação. A chave service_role fica no servidor. CORS permite origem * e os headers definidos no código; configuração não foi alterada.

**Galeria funciona diferente do chat:** ambos os frontends usam FileReader.readAsDataURL e gravam base64 em gallery_items.image_url, com limite de 1.500.000 bytes no formulário. Portanto nem todas as imagens estão no Storage; exportar só o bucket perde imagens da galeria. Exportar só tabelas perde os bytes de imagens do chat.

Excluir mensagem/galeria pela RPC remove linha, sem limpeza do Storage no código examinado. Upload bem sucedido seguido de sendChatMessage malsucedido pode deixar objeto sem referência. Não apagar objetos “órfãos” nesta migração.

## 8. Histórico de decisões e incidentes

1. Ideação do jogo começou com dragões/ovos e evoluiu para minérios. O Hub surgiu como painel da equipe, separado do projeto Roblox.
2. Protótipo inicial usava localStorage, sem colaboração real. Em seguida foi escolhido Supabase para dados/login e Vercel para frontend.
3. GitHub Pages chegou a ser proposto; o usuário criou awmaike/roube-minerios-hub. Tentativas de escrita foram relatadas como bloqueadas. A publicação passou a ocorrer diretamente na Vercel e o repositório ficou vazio.
4. Login por email foi substituído por nomes fechados e sessões próprias; entrou Administração para Devill.
5. Foram adicionados chat, imagens, contagem de não lidas, editar/apagar mensagens, exclusão de comentários, edição de ideias e confirmações.
6. Vários deploys falharam por publicador receber caminho local como texto (`/mnt/data/...`, `sandbox:/...`), arquivos ausentes, HTML como texto/DOCTYPE, dependências de chunks, CORS e carregamento infinito.
7. Previews Vercel protegidos foram usados como fonte do oficial e passaram a exigir login Vercel. Isso é diferente do login do Hub. Alterar DNS não resolve dependência quebrada de preview.
8. Desktop v3 com Salvar e Ler mais/Ler menos e mobile com comentários foram aprovados como “100%” no backup dpl_A4U8oYQSk3qTL3agMeBXQAKazFJS.
9. Melhorias de contador/destaque de comentários, resumo Geral, voltar ao topo e ampliar galeria mobile foram propostas em preview. O usuário depois pediu ignorá-las e focar o envio de imagem mobile; não assumir que entraram no oficial.
10. Correções mobile causaram regressões desktop; ocorreram novas tentativas de restauração. Referências intermediárias: dpl_6X2ZtyVKRV496txJm699rfFwBqf7 e dpl_EpMnDvKCUzb6sjKd95fsuVzzPz6S. São registros de tentativa, não backups confiáveis aprovados.
11. Último relato de restauração: três HTML juntos em dpl_BZLRCDjMQKX5AF7YQ7mRGKaFCe5p; usuário respondeu que estava funcional e pediu migração.
12. Agora: snapshots atuais recuperados, código descompactado, contratos do banco documentados, autorização específica para GitHub, nenhuma mudança de produção/banco.

## 9. Backups e preservação dos dados

O ID “backup 100%” é uma referência a deploy de frontend. **Não é backup do banco** e não garante que o deploy ainda esteja acessível ou livre de dependências. Nesta migração não foi possível baixar aquele deploy por ID, pois Vercel retornou 403. As fontes históricas recuperadas não devem ser rotuladas como cópia exata dele sem comparar.

O backup atual verificável de frontend é site/, com SHA-256 em MANIFEST.json. Além disso foi criada, fora do repositório público, pasta private-backup contendo cópia local de conteúdo: ideias, comentários, decisões, galeria, mensagens, marcadores de leitura e metadados de membros. A captura encontrou 2 ideias, 2 comentários, 1 item de galeria, 0 decisões, 18 mensagens, 2 marcadores e 3 membros. Esses números são uma fotografia e mudam com o uso.

A cópia privada não inclui hashes/salts de senha, sessões, auth.users, objetos não referenciados, configuração completa ou dump integral. Ela ajuda a recuperar conteúdo, mas não substitui backup completo do projeto. Os arquivos públicos do Storage referenciados no JSON são copiados para media/ e relacionados em media-manifest.json; qualquer falha deve ser observada nesse manifesto.

Para continuar sem perder dados: manter o projeto Supabase e URLs atuais; não fazer importação do backup no banco vivo; não rodar SQL de referência; não executar seeds “de exemplo”; obter backup completo e validar restauração separada antes de mudanças estruturais futuras. Backups privados nunca devem entrar neste repositório público.

## 10. Pendências reais de segurança e qualidade

RLS está desligado em chat_messages, chat_reads e site_bundle_chunks. Grants confirmados permitem SELECT/INSERT/UPDATE/DELETE e outros privilégios a anon/authenticated nas duas tabelas de chat. A chave pública do frontend, portanto, não deve ser tratada como barreira de proteção dos dados. site_bundle_chunks não apareceu na listagem desses grants; exposição efetiva dessa tabela requer verificar também PUBLIC e demais acessos. Não presumir o mesmo alcance só porque RLS está desligado.

Planejar revisão das permissões diretas das tabelas e da fronteira SECURITY DEFINER. Não aplicar ENABLE RLS indiscriminadamente nem remover permissões de funções durante migração: isso pode interromper o login/chat. Testar acesso anônimo negado e operações legítimas em ambiente separado antes de alterar produção. Nenhuma correção de segurança foi aplicada aqui.

O hash de senha atual é SHA-256 com salt; não é bcrypt/Argon2 e não foi encontrada proteção contra tentativas repetidas em hub_login. Uma evolução de autenticação precisa preservar acessos e conteúdo. Tokens em localStorage exigem cuidado com XSS. Manter escaping de conteúdo e revisar qualquer nova inserção de HTML.

Outras pendências: envio de imagem sem texto incompatível com constraint, funcionalidades mobile relatadas mas ausentes, políticas legadas auth.uid() coexistindo com membros próprios, dependência de DecompressionStream, ausência de ambiente de teste isolado e configuração Vercel ainda não inspecionável.

## 11. Fluxo recomendado no Codex e futura publicação

1. Abrir este repositório, ler AGENTS.md e este documento. Criar branch codex/ para trabalho novo.
2. Usar src/ para desenvolvimento legível e manter site/ como snapshot da recuperação. Não substituir um arquivo mobile por uma fonte antiga sem verificar desktop também.
3. Servir src/ por HTTP local; não usar file:// para concluir que o app está quebrado. O index usa caminhos absolutos a partir da raiz do servidor.
4. Para testes sem efeitos reais, criar ambiente separado apenas quando autorizado ou simular respostas de API localmente. Uma cópia do frontend apontada ao projeto atual continua sendo produção no que diz respeito aos dados.
5. Validar login com usuários de teste, criação/edição/estado/exclusão e permissões, comentários, galeria, chat texto, imagem com/sem texto, falhas de upload, limite de arquivo, sessão expirada e Administração. Validar em desktop, largura mobile e Safari/iPhone real quando possível.
6. Preparar publicação estática com index.html, desktop.html e mobile.html juntos na raiz de saída. Decidir conscientemente se publicar HTML legível ou gerar wrappers. Não esquecer assets/dependências nem apontar produção a preview protegido.
7. Antes de conectar GitHub à Vercel ou publicar, confirmar conta/projeto, root directory, diretório de saída, branch de produção, domínio e proteção. Solicitar aprovação para o deploy concreto. O repositório não contém automação de deploy configurada nesta migração.
8. Depois de autorizado, conferir HTTP, Content-Type, conteúdo real dos três arquivos e fluxos nos dois dispositivos; status READY sozinho não basta. Registrar ID, data e hashes do deploy validado.
9. Em regressão de frontend, propor restauração somente dos arquivos/deploy previamente validados. Não desfazer dados do Supabase para corrigir HTML.

## 12. Verificações e limites desta entrega

Verificado: repositório inicialmente vazio, obtenção HTTP dos três arquivos atuais, extração gzip, leitura das RPCs, tabelas, RLS, grants, bucket e cinco fontes de funções, exportação privada de conteúdo. Não foram usados logins reais nem executadas ações de escrita nas RPCs. Não foi validado o fluxo autenticado completo. Não houve teste de envio/exclusão de mensagens ou alteração de senha. Não houve modificação de Supabase, Vercel, DNS ou conteúdo de produção.

O contexto descreve o que existe e suas divergências; não promete que toda função dita pronta no histórico esteja de fato implementada. O código atual é a referência para continuidade; o histórico explica a intenção e os incidentes.

Validação local adicional: os scripts inline de src/index.html, src/desktop.html e src/mobile.html passaram pela verificação de sintaxe do Node. Foram baixadas as cinco imagens de Storage referenciadas no backup, sem falhas. A busca por padrões de chaves secretas não encontrou resultados no pacote público; não equivale a uma auditoria completa de segurança.
