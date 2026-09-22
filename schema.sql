-- ============================================================
-- Carteira Consórcio — schema do Supabase
-- Rode este script inteiro em: Supabase → SQL Editor → New query → Run
-- ============================================================

-- Tabela de vendas
create table if not exists sales (
  id text primary key,
  data date not null,
  cliente text not null,
  tipo text not null default 'Outro',
  valor_credito numeric not null,
  plano text default '',
  qtd_parcelas int not null,
  grupo text default '',
  cota text default '',
  valor_parcela numeric default 0,
  seguro_prestamista text not null default 'Não',
  status text not null default 'Em andamento',
  created_at timestamptz not null default now()
);

-- Caso a tabela "sales" já existisse antes (instalação anterior), garante a
-- coluna nova sem apagar nada que já está cadastrado.
alter table sales add column if not exists seguro_prestamista text not null default 'Não';

-- Uma linha por parcela marcada como recebida (o resto é calculado no app)
create table if not exists receipt_overrides (
  id bigint generated always as identity primary key,
  sale_id text not null references sales(id) on delete cascade,
  parcela int not null,
  status text not null default 'recebido',
  data_recebido date,
  unique (sale_id, parcela)
);

-- Configurações globais (uma única linha, id fixo = 1)
create table if not exists settings (
  id int primary key default 1,
  imposto_pct numeric not null default 20
);
insert into settings (id, imposto_pct) values (1, 20)
  on conflict (id) do nothing;

-- Leads (funil de vendas / CRM)
create table if not exists leads (
  id text primary key,
  nome text not null,
  telefone text default '',
  email text default '',
  origem text default 'Outro',
  tipo_interesse text default 'Outro',
  valor_estimado numeric default 0,
  status text not null default 'Novo lead',
  proximo_followup date,
  observacoes text default '',
  sale_id text references sales(id) on delete set null,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Row Level Security
-- Como só você e sua namorada vão usar o app, as políticas abaixo
-- liberam leitura e escrita para quem tiver a URL + chave "anon"
-- do projeto (a mesma chave que já vai dentro do index.html).
-- É o mesmo nível de proteção de um link "não listado": quem não
-- tem o link/chave não acessa; quem tem, acessa tudo.
-- Se um dia quiser login de verdade (email/senha) para os dois,
-- me avise que troco essas políticas por outras baseadas em auth.uid().
-- ------------------------------------------------------------
alter table sales enable row level security;
alter table receipt_overrides enable row level security;
alter table settings enable row level security;
alter table leads enable row level security;

drop policy if exists "allow all sales" on sales;
create policy "allow all sales" on sales
  for all using (true) with check (true);

drop policy if exists "allow all receipt_overrides" on receipt_overrides;
create policy "allow all receipt_overrides" on receipt_overrides
  for all using (true) with check (true);

drop policy if exists "allow all settings" on settings;
create policy "allow all settings" on settings
  for all using (true) with check (true);

drop policy if exists "allow all leads" on leads;
create policy "allow all leads" on leads
  for all using (true) with check (true);

-- ------------------------------------------------------------
-- Realtime (para o app sincronizar sozinho entre os dois aparelhos)
-- Os blocos abaixo ignoram o erro caso a tabela já tenha sido
-- adicionada antes (seguro rodar este script mais de uma vez).
-- ------------------------------------------------------------
do $$
begin
  alter publication supabase_realtime add table sales;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table receipt_overrides;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table settings;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table leads;
exception when duplicate_object then null;
end $$;
