create extension if not exists pgcrypto;

-- Zikos real-estate schema. This is the production schema used by the app.
create table if not exists public.zikos_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role text not null default 'buyer' check (role in ('buyer','owner','agent','admin')),
  avatar_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.zikos_listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.zikos_profiles(id) on delete cascade,
  title text not null,
  description text not null,
  listing_type text not null check (listing_type in ('sale','rent')),
  property_type text not null check (property_type in ('apartment','house','villa','land','commercial','office')),
  status text not null default 'draft' check (status in ('draft','published','sold','rented','rejected')),
  price numeric not null check (price >= 0),
  city text not null,
  neighborhood text,
  address text,
  latitude double precision,
  longitude double precision,
  bedrooms integer,
  bathrooms numeric,
  area_m2 numeric,
  featured boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.zikos_listing_photos (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.zikos_listings(id) on delete cascade,
  storage_path text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.zikos_favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  listing_id uuid not null references public.zikos_listings(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);

create table if not exists public.zikos_conversations (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.zikos_listings(id) on delete cascade,
  buyer_id uuid not null references auth.users(id) on delete cascade,
  seller_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (listing_id, buyer_id, seller_id),
  check (buyer_id <> seller_id)
);

create table if not exists public.zikos_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.zikos_conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (length(trim(body)) > 0),
  created_at timestamptz not null default now()
);

create table if not exists public.zikos_viewing_requests (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.zikos_listings(id) on delete cascade,
  requester_id uuid not null references auth.users(id) on delete cascade,
  requested_at timestamptz not null,
  note text,
  status text not null default 'pending' check (status in ('pending','approved','declined','cancelled')),
  responded_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists zikos_listings_city_idx on public.zikos_listings(city);
create index if not exists zikos_listings_price_idx on public.zikos_listings(price);
create index if not exists zikos_listings_type_idx on public.zikos_listings(property_type);
create index if not exists zikos_listings_status_idx on public.zikos_listings(status);
create index if not exists zikos_messages_conversation_idx on public.zikos_messages(conversation_id, created_at);
create index if not exists zikos_viewings_listing_idx on public.zikos_viewing_requests(listing_id, requested_at);

-- Keep updated_at current on listing edits.
create or replace function public.zikos_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists zikos_listings_updated_at on public.zikos_listings;
create trigger zikos_listings_updated_at
before update on public.zikos_listings
for each row execute function public.zikos_set_updated_at();

-- Automatically create a profile after signup.
create or replace function public.zikos_handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.zikos_profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_zikos on auth.users;
create trigger on_auth_user_created_zikos
after insert on auth.users
for each row execute function public.zikos_handle_new_user();

-- Admin check used by the moderation UI.
create or replace function public.is_zikos_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.zikos_profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

alter table public.zikos_profiles enable row level security;
alter table public.zikos_listings enable row level security;
alter table public.zikos_listing_photos enable row level security;
alter table public.zikos_favorites enable row level security;
alter table public.zikos_conversations enable row level security;
alter table public.zikos_messages enable row level security;
alter table public.zikos_viewing_requests enable row level security;

-- Re-runnable policy setup.
drop policy if exists "profiles self read" on public.zikos_profiles;
drop policy if exists "profiles self update" on public.zikos_profiles;
drop policy if exists "published listings readable" on public.zikos_listings;
drop policy if exists "owners manage listings" on public.zikos_listings;
drop policy if exists "admins manage listings" on public.zikos_listings;
drop policy if exists "listing photos readable" on public.zikos_listing_photos;
drop policy if exists "owners manage listing photos" on public.zikos_listing_photos;
drop policy if exists "users manage favorites" on public.zikos_favorites;
drop policy if exists "conversation participants read" on public.zikos_conversations;
drop policy if exists "buyers create conversations" on public.zikos_conversations;
drop policy if exists "conversation participants messages read" on public.zikos_messages;
drop policy if exists "participants send messages" on public.zikos_messages;
drop policy if exists "requesters create viewing requests" on public.zikos_viewing_requests;
drop policy if exists "viewing participants read" on public.zikos_viewing_requests;
drop policy if exists "viewing owners respond" on public.zikos_viewing_requests;
drop policy if exists "requesters cancel viewing" on public.zikos_viewing_requests;

create policy "profiles self read" on public.zikos_profiles
for select using (id = auth.uid() or public.is_zikos_admin());
create policy "profiles self update" on public.zikos_profiles
for update using (id = auth.uid()) with check (id = auth.uid());

create policy "published listings readable" on public.zikos_listings
for select using (status = 'published' or owner_id = auth.uid() or public.is_zikos_admin());
create policy "owners manage listings" on public.zikos_listings
for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "admins manage listings" on public.zikos_listings
for all using (public.is_zikos_admin()) with check (public.is_zikos_admin());

create policy "listing photos readable" on public.zikos_listing_photos
for select using (exists (
  select 1 from public.zikos_listings l
  where l.id = listing_id and (l.status = 'published' or l.owner_id = auth.uid() or public.is_zikos_admin())
));
create policy "owners manage listing photos" on public.zikos_listing_photos
for all using (exists (select 1 from public.zikos_listings l where l.id = listing_id and l.owner_id = auth.uid()))
with check (exists (select 1 from public.zikos_listings l where l.id = listing_id and l.owner_id = auth.uid()));

create policy "users manage favorites" on public.zikos_favorites
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "conversation participants read" on public.zikos_conversations
for select using (buyer_id = auth.uid() or seller_id = auth.uid());
create policy "buyers create conversations" on public.zikos_conversations
for insert with check (buyer_id = auth.uid() and buyer_id <> seller_id and exists (
  select 1 from public.zikos_listings l where l.id = listing_id and l.owner_id = seller_id
));

create policy "conversation participants messages read" on public.zikos_messages
for select using (exists (
  select 1 from public.zikos_conversations c
  where c.id = conversation_id and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
));
create policy "participants send messages" on public.zikos_messages
for insert with check (sender_id = auth.uid() and exists (
  select 1 from public.zikos_conversations c
  where c.id = conversation_id and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
));

create policy "requesters create viewing requests" on public.zikos_viewing_requests
for insert with check (requester_id = auth.uid());
create policy "viewing participants read" on public.zikos_viewing_requests
for select using (requester_id = auth.uid() or exists (
  select 1 from public.zikos_listings l where l.id = listing_id and l.owner_id = auth.uid()
));
create policy "viewing owners respond" on public.zikos_viewing_requests
for update using (exists (
  select 1 from public.zikos_listings l where l.id = listing_id and l.owner_id = auth.uid()
)) with check (exists (
  select 1 from public.zikos_listings l where l.id = listing_id and l.owner_id = auth.uid()
));
create policy "requesters cancel viewing" on public.zikos_viewing_requests
for update using (requester_id = auth.uid()) with check (requester_id = auth.uid());

-- Storage bucket for listing photos. Public read is intentional because listing photos are public marketplace assets.
insert into storage.buckets (id, name, public)
values ('zikos-listing-photos', 'zikos-listing-photos', true)
on conflict (id) do update set public = true;

drop policy if exists "Zikos public listing photos" on storage.objects;
drop policy if exists "Zikos owners upload listing photos" on storage.objects;
drop policy if exists "Zikos owners delete listing photos" on storage.objects;
create policy "Zikos public listing photos" on storage.objects
for select using (bucket_id = 'zikos-listing-photos');
create policy "Zikos owners upload listing photos" on storage.objects
for insert to authenticated with check (
  bucket_id = 'zikos-listing-photos' and (storage.foldername(name))[1] = auth.uid()::text
);
create policy "Zikos owners delete listing photos" on storage.objects
for delete to authenticated using (
  bucket_id = 'zikos-listing-photos' and (storage.foldername(name))[1] = auth.uid()::text
);
