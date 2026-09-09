import { createClient } from 'npm:@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'content-type, x-hub-token, authorization, apikey',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  if (req.method !== 'POST') return new Response(JSON.stringify({ error: 'Método inválido' }), { status: 405, headers: { ...cors, 'Content-Type': 'application/json' } })

  try {
    const token = req.headers.get('x-hub-token') || ''
    if (!token) return new Response(JSON.stringify({ error: 'Sessão inválida' }), { status: 401, headers: { ...cors, 'Content-Type': 'application/json' } })

    const url = Deno.env.get('SUPABASE_URL')!
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(url, serviceKey)

    const { data: authData, error: authError } = await supabase.rpc('hub_api', { p_token: token, p_action: 'bootstrap', p_payload: {} })
    if (authError || !authData?.ok) return new Response(JSON.stringify({ error: 'Sessão inválida' }), { status: 401, headers: { ...cors, 'Content-Type': 'application/json' } })

    const form = await req.formData()
    const file = form.get('file')
    if (!(file instanceof File)) return new Response(JSON.stringify({ error: 'Selecione uma imagem' }), { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } })

    const allowed = ['image/jpeg','image/png','image/webp','image/gif']
    if (!allowed.includes(file.type)) return new Response(JSON.stringify({ error: 'Formato não suportado. Use JPG, PNG, WEBP ou GIF.' }), { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } })
    if (file.size > 5 * 1024 * 1024) return new Response(JSON.stringify({ error: 'A imagem deve ter no máximo 5 MB' }), { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } })

    const extMap: Record<string,string> = { 'image/jpeg':'jpg','image/png':'png','image/webp':'webp','image/gif':'gif' }
    const path = `chat/${Date.now()}-${crypto.randomUUID()}.${extMap[file.type] || 'img'}`
    const bytes = new Uint8Array(await file.arrayBuffer())
    const { error: uploadError } = await supabase.storage.from('project-media').upload(path, bytes, { contentType: file.type, upsert: false })
    if (uploadError) throw uploadError

    const { data: publicData } = supabase.storage.from('project-media').getPublicUrl(path)
    return new Response(JSON.stringify({ ok: true, url: publicData.publicUrl }), { headers: { ...cors, 'Content-Type': 'application/json' } })
  } catch (e) {
    return new Response(JSON.stringify({ error: e?.message || 'Falha no upload' }), { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } })
  }
})

