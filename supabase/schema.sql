-- Zikos v2 additions
create table if not exists public.zikos_agents (id uuid primary key default gen_random_uuid(), user_id uuid unique not null references auth.users(id) on delete cascade, name text not null, bio text, phone text, email text, avatar_url text, created_at timestamptz not null default now());
alter table public.zikos_listings add column if not exists agent_id uuid references public.zikos_agents(id) on delete set null;
create index if not exists zikos_listings_agent_idx on public.zikos_listings(agent_id);
create table if not exists public.zikos_notifications (id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade, type text not null, title text not null, body text, href text, read_at timestamptz, created_at timestamptz not null default now());
create index if not exists zikos_notifications_user_idx on public.zikos_notifications(user_id,created_at desc);
create table if not exists public.zikos_saved_searches (id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade, name text not null, listing_type text check(listing_type in ('sale','rent')), property_type text, city text, neighborhood text, min_price numeric, max_price numeric, min_bedrooms integer, min_area_m2 numeric, amenities text[] default '{}', alerts_enabled boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create index if not exists zikos_saved_searches_user_idx on public.zikos_saved_searches(user_id);
alter table public.zikos_agents enable row level security; alter table public.zikos_notifications enable row level security; alter table public.zikos_saved_searches enable row level security;
drop policy if exists "public agent profiles" on public.zikos_agents; create policy "public agent profiles" on public.zikos_agents for select using(true);
drop policy if exists "agents manage own profile" on public.zikos_agents; create policy "agents manage own profile" on public.zikos_agents for all using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists "users read notifications" on public.zikos_notifications; create policy "users read notifications" on public.zikos_notifications for select using(user_id=auth.uid());
drop policy if exists "users update notifications" on public.zikos_notifications; create policy "users update notifications" on public.zikos_notifications for update using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists "users manage saved searches" on public.zikos_saved_searches; create policy "users manage saved searches" on public.zikos_saved_searches for all using(user_id=auth.uid()) with check(user_id=auth.uid());
-- Enable realtime for chat, notifications and viewing updates.
do $$ begin alter publication supabase_realtime add table public.zikos_messages; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.zikos_notifications; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.zikos_viewing_requests; exception when duplicate_object then null; end $$;
