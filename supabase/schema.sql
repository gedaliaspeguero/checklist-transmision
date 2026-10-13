-- Checklist de transmisión en vivo
-- Tablas con prefijo checklist_ para convivir con las demás apps del proyecto.
-- Lectura abierta (anon); escritura solo a través de las funciones de abajo.

create table if not exists public.checklist_marcas (
  lista      text not null check (lista ~ '^[a-z0-9-]{1,60}$'),
  item_id    text not null check (item_id ~ '^[a-z0-9-]{1,60}$'),
  estado     text not null check (estado in ('ok', 'bad')),
  por        text check (char_length(por) <= 40),
  updated_at timestamptz not null default now(),
  primary key (lista, item_id)
);

alter table public.checklist_marcas enable row level security;

drop policy if exists checklist_marcas_select on public.checklist_marcas;
create policy checklist_marcas_select on public.checklist_marcas
  for select to anon, authenticated using (true);

-- Marcar, cambiar o quitar (p_estado null) la marca de un equipo.
create or replace function public.checklist_marcar(p_lista text, p_item text, p_estado text, p_por text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_estado is null then
    delete from checklist_marcas where lista = p_lista and item_id = p_item;
    return;
  end if;
  if p_estado not in ('ok', 'bad') then
    raise exception 'estado inválido';
  end if;
  if not exists (select 1 from checklist_marcas where lista = p_lista and item_id = p_item)
     and (select count(*) from checklist_marcas where lista = p_lista) >= 200 then
    raise exception 'la lista está llena';
  end if;
  insert into checklist_marcas (lista, item_id, estado, por, updated_at)
  values (p_lista, p_item, p_estado, left(nullif(btrim(p_por), ''), 40), now())
  on conflict (lista, item_id) do update
    set estado = excluded.estado, por = excluded.por, updated_at = now();
end;
$$;

-- Borrar todas las marcas de una lista (para reutilizarla en otro evento).
create or replace function public.checklist_reiniciar(p_lista text)
returns void
language sql
security definer
set search_path = public
as $$
  delete from checklist_marcas where lista = p_lista;
$$;

revoke all on function public.checklist_marcar(text, text, text, text) from public;
revoke all on function public.checklist_reiniciar(text) from public;
grant execute on function public.checklist_marcar(text, text, text, text) to anon, authenticated;
grant execute on function public.checklist_reiniciar(text) to anon, authenticated;

-- Tiempo real: avisar a los teléfonos abiertos cuando alguien marca.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'checklist_marcas'
  ) then
    alter publication supabase_realtime add table public.checklist_marcas;
  end if;
end;
$$;
