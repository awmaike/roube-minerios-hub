-- REFERENCE SNAPSHOT ONLY. Do not execute against production.
CREATE OR REPLACE FUNCTION public.hub_delete_comment(p_token text, p_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  m public.hub_members%rowtype;
  item_author text;
begin
  select hm.* into m
  from public.hub_sessions hs
  join public.hub_members hm on hm.id = hs.member_id
  where hs.token_hash = encode(extensions.digest(p_token,'sha256'),'hex')
    and hs.expires_at > now()
    and hm.active = true
  limit 1;

  if m.id is null then
    return jsonb_build_object('ok',false,'error','Sessão inválida');
  end if;

  select c.author_name into item_author
  from public.comments c
  where c.id = p_id;

  if item_author is null then
    return jsonb_build_object('ok',false,'error','Comentário não encontrado');
  end if;

  if item_author <> m.display_name and m.role <> 'admin' then
    return jsonb_build_object('ok',false,'error','Sem permissão');
  end if;

  delete from public.comments where id = p_id;
  return jsonb_build_object('ok',true);
end;
$function$
