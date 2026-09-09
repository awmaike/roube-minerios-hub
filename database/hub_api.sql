-- Scoped production fix: bind idea ownership to the authenticated Hub member.
ALTER TABLE public.ideas
  ADD COLUMN IF NOT EXISTS member_id uuid REFERENCES public.hub_members(id);

UPDATE public.ideas i
SET member_id = hm.id
FROM public.hub_members hm
WHERE i.member_id IS NULL
  AND lower(trim(hm.login_name)) = 'devill'
  AND lower(trim(i.author_name)) IN (lower(trim(hm.display_name)), lower(trim(hm.login_name)));

CREATE OR REPLACE FUNCTION public.hub_api(p_token text, p_action text, p_payload jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  m public.hub_members%rowtype;
  item_author text;
  item_member_id uuid;
  result jsonb;
  new_status text;
  target_id uuid;
  new_salt text;
  unread_count integer;
  msg_body text;
  msg_image text;
begin
  select hm.* into m
  from public.hub_sessions hs join public.hub_members hm on hm.id=hs.member_id
  where hs.token_hash=encode(extensions.digest(p_token,'sha256'),'hex') and hs.expires_at>now() and hm.active=true limit 1;
  if m.id is null then return jsonb_build_object('ok',false,'error','Sessão inválida'); end if;

  if p_action='bootstrap' then
    select count(*) into unread_count from public.chat_messages cm
    where cm.member_id<>m.id and cm.created_at > coalesce((select cr.last_read_at from public.chat_reads cr where cr.member_id=m.id),'epoch'::timestamptz);
    return jsonb_build_object('ok',true,'user',jsonb_build_object('id',m.id,'name',m.display_name,'role',m.role),'ideas',coalesce((select jsonb_agg(to_jsonb(x) order by x.created_at desc) from public.ideas x),'[]'::jsonb),'gallery',coalesce((select jsonb_agg(to_jsonb(x) order by x.created_at desc) from public.gallery_items x),'[]'::jsonb),'decisions',coalesce((select jsonb_agg(to_jsonb(x) order by x.created_at desc) from public.decisions x),'[]'::jsonb),'chat_unread',unread_count);
  elsif p_action='listChatMessages' then
    select count(*) into unread_count from public.chat_messages cm
    where cm.member_id<>m.id and cm.created_at > coalesce((select cr.last_read_at from public.chat_reads cr where cr.member_id=m.id),'epoch'::timestamptz);
    result:=coalesce((select jsonb_agg(to_jsonb(x) order by x.created_at asc) from (select cm.id,cm.member_id,cm.author_name,cm.body,cm.image_url,cm.created_at,cm.edited_at from public.chat_messages cm order by cm.created_at desc limit 200) x),'[]'::jsonb);
    return jsonb_build_object('ok',true,'messages',result,'unread',unread_count);
  elsif p_action='sendChatMessage' then
    msg_body:=trim(coalesce(p_payload->>'body',''));
    msg_image:=nullif(trim(coalesce(p_payload->>'image_url','')),'');
    if length(msg_body)=0 and msg_image is null then return jsonb_build_object('ok',false,'error','Mensagem vazia'); end if;
    if length(msg_body)>1200 then return jsonb_build_object('ok',false,'error','Mensagem muito longa'); end if;
    if msg_image is not null and msg_image not like 'https://bjypwenzgusuojaewffq.supabase.co/storage/v1/object/public/project-media/chat/%' then return jsonb_build_object('ok',false,'error','Imagem inválida'); end if;
    insert into public.chat_messages(member_id,author_name,body,image_url) values(m.id,m.display_name,msg_body,msg_image);
    return jsonb_build_object('ok',true);
  elsif p_action='editChatMessage' then
    target_id:=(p_payload->>'id')::uuid;
    msg_body:=trim(coalesce(p_payload->>'body',''));
    select author_name into item_author from public.chat_messages where id=target_id;
    if item_author is null or item_author<>m.display_name then return jsonb_build_object('ok',false,'error','Você só pode editar suas próprias mensagens'); end if;
    if length(msg_body)=0 then return jsonb_build_object('ok',false,'error','A mensagem não pode ficar vazia'); end if;
    if length(msg_body)>1200 then return jsonb_build_object('ok',false,'error','Mensagem muito longa'); end if;
    update public.chat_messages set body=msg_body,edited_at=now() where id=target_id;
    return jsonb_build_object('ok',true);
  elsif p_action='markChatRead' then
    insert into public.chat_reads(member_id,last_read_at) values(m.id,now()) on conflict(member_id) do update set last_read_at=excluded.last_read_at;
    return jsonb_build_object('ok',true);
  elsif p_action='deleteChatMessage' then
    select author_name into item_author from public.chat_messages where id=(p_payload->>'id')::uuid;
    if item_author is null or (item_author<>m.display_name and m.role<>'admin') then return jsonb_build_object('ok',false,'error','Sem permissão'); end if;
    delete from public.chat_messages where id=(p_payload->>'id')::uuid;
    return jsonb_build_object('ok',true);
  elsif p_action='adminListUsers' then
    if m.role<>'admin' then return jsonb_build_object('ok',false,'error','Sem permissão'); end if;
    result:=coalesce((select jsonb_agg(jsonb_build_object('id',x.id,'username',x.login_name,'name',x.display_name,'role',x.role,'active',x.active) order by x.display_name) from public.hub_members x),'[]'::jsonb);
    return jsonb_build_object('ok',true,'users',result);
  elsif p_action='adminSetActive' then
    if m.role<>'admin' then return jsonb_build_object('ok',false,'error','Sem permissão'); end if;
    target_id:=(p_payload->>'id')::uuid;
    if target_id=m.id and coalesce((p_payload->>'active')::boolean,false)=false then return jsonb_build_object('ok',false,'error','Você não pode desativar seu próprio acesso'); end if;
    update public.hub_members set active=coalesce((p_payload->>'active')::boolean,true) where id=target_id;
    if coalesce((p_payload->>'active')::boolean,true)=false then delete from public.hub_sessions where member_id=target_id; end if;
    return jsonb_build_object('ok',true);
  elsif p_action='adminResetPassword' then
    if m.role<>'admin' then return jsonb_build_object('ok',false,'error','Sem permissão'); end if;
    target_id:=(p_payload->>'id')::uuid;
    if length(coalesce(p_payload->>'password',''))<8 then return jsonb_build_object('ok',false,'error','A senha deve ter pelo menos 8 caracteres'); end if;
    new_salt:=encode(extensions.gen_random_bytes(16),'hex');
    update public.hub_members set salt=new_salt, access_hash=encode(extensions.digest(new_salt || (p_payload->>'password'),'sha256'),'hex') where id=target_id;
    delete from public.hub_sessions where member_id=target_id;
    return jsonb_build_object('ok',true);
  elsif p_action='createIdea' then
    insert into public.ideas(title,description,status,category,author_name,member_id) values (p_payload->>'title',coalesce(p_payload->>'description',''),coalesce(p_payload->>'status','ideia'),coalesce(p_payload->>'category','geral'),m.display_name,m.id); return jsonb_build_object('ok',true);
  elsif p_action='editIdea' then
    target_id:=(p_payload->>'id')::uuid;
    select author_name,member_id into item_author,item_member_id from public.ideas where id=target_id;
    if item_author is null or coalesce(item_member_id=m.id,item_author=m.display_name)=false then return jsonb_build_object('ok',false,'error','Você só pode editar suas próprias ideias'); end if;
    if length(trim(coalesce(p_payload->>'title','')))=0 then return jsonb_build_object('ok',false,'error','Título obrigatório'); end if;
    update public.ideas
      set title=trim(p_payload->>'title'),
          description=coalesce(p_payload->>'description',''),
          category=coalesce(p_payload->>'category',category),
          status=coalesce(p_payload->>'status',status),
          member_id=coalesce(member_id,m.id),
          updated_at=now()
    where id=target_id;
    return jsonb_build_object('ok',true);
  elsif p_action='updateIdeaStatus' then
    select author_name into item_author from public.ideas where id=(p_payload->>'id')::uuid; if item_author is null or (item_author<>m.display_name and m.role<>'admin') then return jsonb_build_object('ok',false,'error','Sem permissão'); end if; new_status:=p_payload->>'status'; update public.ideas set status=new_status,updated_at=now() where id=(p_payload->>'id')::uuid; return jsonb_build_object('ok',true);
  elsif p_action='deleteIdea' then
    select author_name into item_author from public.ideas where id=(p_payload->>'id')::uuid; if item_author is null or (item_author<>m.display_name and m.role<>'admin') then return jsonb_build_object('ok',false,'error','Sem permissão'); end if; delete from public.ideas where id=(p_payload->>'id')::uuid; return jsonb_build_object('ok',true);
  elsif p_action='createDecision' then
    insert into public.decisions(title,details,status,author_name) values (p_payload->>'title',coalesce(p_payload->>'details',''),coalesce(p_payload->>'status','discussao'),m.display_name); return jsonb_build_object('ok',true);
  elsif p_action='deleteDecision' then
    select author_name into item_author from public.decisions where id=(p_payload->>'id')::uuid; if item_author is null or (item_author<>m.display_name and m.role<>'admin') then return jsonb_build_object('ok',false,'error','Sem permissão'); end if; delete from public.decisions where id=(p_payload->>'id')::uuid; return jsonb_build_object('ok',true);
  elsif p_action='listComments' then
    result:=coalesce((select jsonb_agg(to_jsonb(c) order by c.created_at) from public.comments c where c.idea_id=(p_payload->>'idea_id')::uuid),'[]'::jsonb); return jsonb_build_object('ok',true,'comments',result);
  elsif p_action='addComment' then
    insert into public.comments(idea_id,body,author_name) values ((p_payload->>'idea_id')::uuid,p_payload->>'body',m.display_name); return jsonb_build_object('ok',true);
  elsif p_action='addGallery' then
    insert into public.gallery_items(title,description,image_url,category,author_name) values (p_payload->>'title',coalesce(p_payload->>'description',''),p_payload->>'image_url',coalesce(p_payload->>'category','mapa'),m.display_name); return jsonb_build_object('ok',true);
  elsif p_action='deleteGallery' then
    select author_name into item_author from public.gallery_items where id=(p_payload->>'id')::uuid;
    if item_author is null or (item_author<>m.display_name and m.role<>'admin') then return jsonb_build_object('ok',false,'error','Sem permissão'); end if;
    delete from public.gallery_items where id=(p_payload->>'id')::uuid; return jsonb_build_object('ok',true);
  elsif p_action='logout' then
    delete from public.hub_sessions where token_hash=encode(extensions.digest(p_token,'sha256'),'hex'); return jsonb_build_object('ok',true);
  end if;
  return jsonb_build_object('ok',false,'error','Ação inválida');
end;$function$
