-- ============================================================
-- Ronda Hospitalar · preparação do banco compartilhado (Supabase)
-- Cole este arquivo inteiro em: Supabase > SQL Editor > New query > Run
-- ANTES de executar, troque  TROQUE-ESTE-CODIGO  na última linha
-- por um código longo (16 caracteres ou mais) que só a equipe conhece.
-- ============================================================

create extension if not exists pgcrypto with schema extensions;

create sequence if not exists public.rh_seq;

create table if not exists public.rh_docs (
  p       text primary key,                 -- caminho do registro: colecao/id
  c       text not null,                    -- coleção
  d       jsonb not null default '{}'::jsonb,
  seq     bigint not null default nextval('public.rh_seq'),
  deleted boolean not null default false
);
create index if not exists rh_docs_seq_idx on public.rh_docs (seq);

create table if not exists public.rh_secret (
  id        int primary key check (id = 1),
  code_hash text not null
);

-- Nenhum acesso direto às tabelas: tudo passa pelas funções abaixo, que exigem o código da equipe.
alter table public.rh_docs   enable row level security;
alter table public.rh_secret enable row level security;
revoke all on public.rh_docs, public.rh_secret from anon, authenticated;
revoke all on sequence public.rh_seq from anon, authenticated;

create or replace function public.rh_auth(p_code text) returns void
language plpgsql security definer set search_path = public, extensions as $$
begin
  if p_code is null or not exists (
       select 1 from public.rh_secret s where s.code_hash = crypt(p_code, s.code_hash)) then
    perform pg_sleep(0.7);
    raise exception 'codigo_invalido' using errcode = '28000';
  end if;
end $$;
revoke all on function public.rh_auth(text) from public, anon, authenticated;

create or replace function public.rh_check(p_code text) returns boolean
language plpgsql security definer set search_path = public, extensions as $$
begin perform public.rh_auth(p_code); return true; end $$;

-- Alterações desde a posição p_since (p_fotos = true devolve só as fotos).
create or replace function public.rh_pull(p_code text, p_since bigint default 0, p_fotos boolean default false)
returns table (seq bigint, p text, d jsonb, deleted boolean)
language plpgsql security definer set search_path = public, extensions as $$
begin
  perform public.rh_auth(p_code);
  return query
    select t.seq, t.p, t.d, t.deleted from public.rh_docs t
    where t.seq > coalesce(p_since, 0)
      and ((p_fotos and t.c = 'fotos') or (not p_fotos and t.c <> 'fotos'))
      and (coalesce(p_since, 0) > 0 or not t.deleted)
    order by t.seq limit 1000;
end $$;

create or replace function public.rh_get(p_code text, p_path text) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare r jsonb;
begin
  perform public.rh_auth(p_code);
  select t.d into r from public.rh_docs t where t.p = p_path and not t.deleted;
  return r;
end $$;

-- Grava vários registros de uma vez. Item: {"p":"colecao/id","d":{...}}; d = null apaga.
create or replace function public.rh_put_many(p_code text, p_items jsonb) returns bigint
language plpgsql security definer set search_path = public, extensions as $$
declare it jsonb; v_p text; v_last bigint := 0;
begin
  perform public.rh_auth(p_code);
  for it in select * from jsonb_array_elements(p_items) loop
    v_p := it->>'p';
    if v_p is null or position('/' in v_p) = 0 or length(v_p) > 400 then continue; end if;
    if it->'d' is null or jsonb_typeof(it->'d') <> 'object' then
      insert into public.rh_docs (p, c, d, deleted, seq)
        values (v_p, split_part(v_p, '/', 1), '{}'::jsonb, true, nextval('public.rh_seq'))
        on conflict (p) do update set d = '{}'::jsonb, deleted = true, seq = nextval('public.rh_seq');
    else
      insert into public.rh_docs (p, c, d, deleted, seq)
        values (v_p, split_part(v_p, '/', 1), it->'d', false, nextval('public.rh_seq'))
        on conflict (p) do update set d = excluded.d, deleted = false, seq = nextval('public.rh_seq');
    end if;
  end loop;
  select coalesce(max(t.seq), 0) into v_last from public.rh_docs t;
  return v_last;
end $$;

revoke all on function public.rh_check(text), public.rh_pull(text,bigint,boolean), public.rh_get(text,text), public.rh_put_many(text,jsonb) from public;
grant execute on function public.rh_check(text), public.rh_pull(text,bigint,boolean), public.rh_get(text,text), public.rh_put_many(text,jsonb) to anon, authenticated;

-- Código de acesso da equipe (troque o texto entre aspas e execute de novo para mudar o código).
insert into public.rh_secret (id, code_hash) values (1, extensions.crypt('TROQUE-ESTE-CODIGO', extensions.gen_salt('bf')))
on conflict (id) do update set code_hash = excluded.code_hash;
