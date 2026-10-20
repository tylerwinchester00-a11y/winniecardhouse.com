-- WinnieCardHouse inventory setup
-- Run in Supabase Dashboard > SQL Editor > New query.
-- Owner access is limited to tyler@winniecardhouse.com.
create table if not exists public.cards (
  id uuid primary key default gen_random_uuid(),
  player text not null,
  card_name text not null,
  year text,
  set_name text,
  condition text,
  description text,
  price numeric(10,2) not null default 0 check (price >= 0),
  image_url text,
  status text not null default 'available' check (status in ('available','sold','hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.cards enable row level security;
drop policy if exists "Public can view available cards" on public.cards;
create policy "Public can view available cards" on public.cards for select to anon, authenticated using (status = 'available');
drop policy if exists "Owner can manage all cards" on public.cards;
create policy "Owner can manage all cards" on public.cards for all to authenticated
using ((auth.jwt() ->> 'email') = 'tyler@winniecardhouse.com')
with check ((auth.jwt() ->> 'email') = 'tyler@winniecardhouse.com');
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('card-photos','card-photos',true,10485760,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=true,file_size_limit=10485760,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists "Public can view card photos" on storage.objects;
create policy "Public can view card photos" on storage.objects for select to anon, authenticated using (bucket_id='card-photos');
drop policy if exists "Owner can upload card photos" on storage.objects;
create policy "Owner can upload card photos" on storage.objects for insert to authenticated
with check (bucket_id='card-photos' and (auth.jwt() ->> 'email')='tyler@winniecardhouse.com');
drop policy if exists "Owner can update card photos" on storage.objects;
create policy "Owner can update card photos" on storage.objects for update to authenticated
using (bucket_id='card-photos' and (auth.jwt() ->> 'email')='tyler@winniecardhouse.com')
with check (bucket_id='card-photos' and (auth.jwt() ->> 'email')='tyler@winniecardhouse.com');
drop policy if exists "Owner can delete card photos" on storage.objects;
create policy "Owner can delete card photos" on storage.objects for delete to authenticated
using (bucket_id='card-photos' and (auth.jwt() ->> 'email')='tyler@winniecardhouse.com');
grant select on public.cards to anon, authenticated;
grant insert,update,delete on public.cards to authenticated;
