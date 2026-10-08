-- ============================================================
-- CRM Isabella Almeida — Consórcios — schema do Supabase (v2)
-- Fluxo unificado Prospect → Lead → Carteira
--
-- Rode este script inteiro em: Supabase → SQL Editor → New query → Run
-- Seguro rodar mais de uma vez (idempotente) e seguro rodar sobre um
-- banco que já tinha a estrutura antiga (sales/leads separados) —
-- nada é apagado, apenas renomeado/complementado/migrado.
-- ============================================================

-- ------------------------------------------------------------
-- 1) TABELA CLIENTS (cadastro único: Prospect → Lead → Carteira)
-- ------------------------------------------------------------
create table if not exists clients (
  id text primary key,
  nome text not null,
  telefone text default '',
  email text default '',
  empresa text default '',
  cargo text default '',
  indicador text default '',
  origem text default 'Outro',
  primeiro_contato date,
  forma_contato text default 'WhatsApp',
  resultado_abordagem text default 'Ainda não contatado',
  ultimo_contato date,
  proxima_etapa text default '',
  data_proxima_etapa date,
  obs text default '',
  temperatura text default 'Morno',
  interesse text default 'Outro',
  objetivo text default '',
  faixa_credito text default 'Ainda não definido',
  credito_pretendido numeric default 0,
  parcela_estimada numeric default 0,
  estrategia text default '',
  condicao text default '',
  stage text not null default 'prospect',       -- prospect | lead | carteira
  status_lead text not null default 'Ativo',     -- Ativo | Perdido
  motivo_perda text default '',
  history jsonb not null default '[]'::jsonb,    -- histórico de contatos (timeline)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 2) TABELA SALES — ajusta a estrutura antiga para a nova (sem apagar dados)
-- ------------------------------------------------------------
create table if not exists sales (
  id text primary key,
  client_id text references clients(id) on delete set null,
  numero text default '',
  data date not null,
  cliente text not null,
  telefone text default '',
  email text default '',
  tipo text not null default 'Outro',
  credito numeric not null default 0,
  plano text default '100%',
  qtd int not null default 0,
  grupo text default '',
  cota text default '',
  parcela numeric default 0,
  forma_pagamento text default 'Boleto',
  seguro text not null default 'Não',
  status text not null default 'Emitida',
  pos text default '',
  created_at timestamptz not null default now()
);

-- Se a tabela "sales" já existia com os nomes antigos de coluna, renomeia
-- (cada bloco só executa se a coluna antiga existir e a nova ainda não).
do $$ begin
  if exists (select 1 from information_schema.columns where table_name='sales' and column_name='valor_credito')
     and not exists (select 1 from information_schema.columns where table_name='sales' and column_name='credito') then
    alter table sales rename column valor_credito to credito;
  end if;
end $$;
do $$ begin
  if exists (select 1 from information_schema.columns where table_name='sales' and column_name='qtd_parcelas')
     and not exists (select 1 from information_schema.columns where table_name='sales' and column_name='qtd') then
    alter table sales rename column qtd_parcelas to qtd;
  end if;
end $$;
do $$ begin
  if exists (select 1 from information_schema.columns where table_name='sales' and column_name='valor_parcela')
     and not exists (select 1 from information_schema.columns where table_name='sales' and column_name='parcela') then
    alter table sales rename column valor_parcela to parcela;
  end if;
end $$;
do $$ begin
  if exists (select 1 from information_schema.columns where table_name='sales' and column_name='seguro_prestamista')
     and not exists (select 1 from information_schema.columns where table_name='sales' and column_name='seguro') then
    alter table sales rename column seguro_prestamista to seguro;
  end if;
end $$;

-- Garante que todas as colunas novas existam, mesmo numa tabela antiga.
alter table sales add column if not exists client_id text references clients(id) on delete set null;
alter table sales add column if not exists numero text default '';
alter table sales add column if not exists telefone text default '';
alter table sales add column if not exists email text default '';
alter table sales add column if not exists forma_pagamento text default 'Boleto';
alter table sales add column if not exists pos text default '';
alter table sales alter column seguro set default 'Não';

-- ------------------------------------------------------------
-- 3) RECEIPT_OVERRIDES — uma linha por parcela marcada como recebida
-- ------------------------------------------------------------
create table if not exists receipt_overrides (
  id bigint generated always as identity primary key,
  sale_id text not null references sales(id) on delete cascade,
  parcela int not null,
  status text not null default 'recebido',
  data_recebido date,
  unique (sale_id, parcela)
);

-- ------------------------------------------------------------
-- 4) SETTINGS — configurações globais (uma única linha, id fixo = 1)
-- ------------------------------------------------------------
create table if not exists settings (
  id int primary key default 1,
  imposto_pct numeric not null default 20,
  admin text default ''
);
alter table settings add column if not exists admin text default '';
insert into settings (id, imposto_pct) values (1, 20)
  on conflict (id) do nothing;

-- ------------------------------------------------------------
-- 5) MIGRAÇÃO: leads antigos (tabela "leads") → clients
-- Só roda se a tabela "leads" existir e ainda não tiver sido migrada.
-- Os registros antigos de leads SEM venda viram clients com stage='lead';
-- os COM venda (sale_id preenchido) viram stage='carteira'.
-- A tabela "leads" antiga não é apagada — fica preservada como histórico.
-- ------------------------------------------------------------
do $$
begin
  if exists (select 1 from information_schema.tables where table_name='leads') then
    insert into clients (id, nome, telefone, email, origem, interesse, obs, stage, status_lead, history, created_at, updated_at)
    select
      l.id, l.nome, coalesce(l.telefone,''), coalesce(l.email,''),
      coalesce(l.origem,'Outro'), coalesce(l.tipo_interesse,'Outro'), coalesce(l.observacoes,''),
      case when l.sale_id is not null then 'carteira' else 'lead' end,
      case when l.status = 'Perdido' then 'Perdido' else 'Ativo' end,
      '[]'::jsonb,
      coalesce(l.created_at, now()), coalesce(l.created_at, now())
    from leads l
    where not exists (select 1 from clients c where c.id = l.id);

    -- Vincula vendas antigas geradas a partir de um lead ao client migrado
    update sales s set client_id = l.id
    from leads l
    where l.sale_id = s.id and s.client_id is null;
  end if;
end $$;

-- ------------------------------------------------------------
-- 6) Row Level Security
-- Como só você e sua namorada vão usar o app, as políticas abaixo
-- liberam leitura e escrita para quem tiver a URL + chave "anon" do
-- projeto (a mesma chave que já vai dentro do index.html). É o mesmo
-- nível de proteção de um link "não listado": quem não tem o link/chave
-- não acessa; quem tem, acessa tudo.
-- ------------------------------------------------------------
alter table clients enable row level security;
alter table sales enable row level security;
alter table receipt_overrides enable row level security;
alter table settings enable row level security;

drop policy if exists "allow all clients" on clients;
create policy "allow all clients" on clients for all using (true) with check (true);

drop policy if exists "allow all sales" on sales;
create policy "allow all sales" on sales for all using (true) with check (true);

drop policy if exists "allow all receipt_overrides" on receipt_overrides;
create policy "allow all receipt_overrides" on receipt_overrides for all using (true) with check (true);

drop policy if exists "allow all settings" on settings;
create policy "allow all settings" on settings for all using (true) with check (true);

-- ------------------------------------------------------------
-- 7) Realtime (para o app sincronizar sozinho entre os dois aparelhos)
-- ------------------------------------------------------------
do $$ begin
  alter publication supabase_realtime add table clients;
exception when duplicate_object then null;
end $$;
do $$ begin
  alter publication supabase_realtime add table sales;
exception when duplicate_object then null;
end $$;
do $$ begin
  alter publication supabase_realtime add table receipt_overrides;
exception when duplicate_object then null;
end $$;
do $$ begin
  alter publication supabase_realtime add table settings;
exception when duplicate_object then null;
end $$;
