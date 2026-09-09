-- REFERENCE SNAPSHOT ONLY. Do not execute against production.
CREATE OR REPLACE FUNCTION public.hub_login(p_user text, p_secret text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  m public.hub_members%rowtype;
  raw_token text;
begin
  select * into m
  from public.hub_members
  where lower(login_name)=lower(trim(p_user))
    and active=true
    and access_hash = encode(extensions.digest(salt || p_secret, 'sha256'),'hex')
  limit 1;
  if m.id is null then
    return jsonb_build_object('ok',false,'error','Usuário ou senha incorretos');
  end if;
  raw_token := encode(extensions.gen_random_bytes(32),'hex');
  delete from public.hub_sessions where member_id=m.id or expires_at < now();
  insert into public.hub_sessions(token_hash,member_id)
  values (encode(extensions.digest(raw_token,'sha256'),'hex'),m.id);
  return jsonb_build_object('ok',true,'token',raw_token,'user',jsonb_build_object('name',m.display_name,'role',m.role));
end;
$function$
