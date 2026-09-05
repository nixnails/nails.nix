-- Run this AFTER supabase_setup.sql
-- Replace YOUR_OWNER_EMAIL with the email you use to log into NIX Nails.

create or replace function public.is_owner()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'owner'
  );
$$;

revoke all on function public.is_owner() from public;
grant execute on function public.is_owner() to authenticated;

drop policy if exists "profiles own select" on public.profiles;
drop policy if exists "bookings customer read" on public.bookings;
drop policy if exists "bookings owner update" on public.bookings;
drop policy if exists "photos customer read" on public.booking_photos;
drop policy if exists "booking photos read own or owner" on storage.objects;

create policy "profiles own select" on public.profiles
for select to authenticated
using (id = auth.uid() or public.is_owner());

create policy "bookings customer read" on public.bookings
for select to authenticated
using (user_id = auth.uid() or public.is_owner());

create policy "bookings owner update" on public.bookings
for update to authenticated
using (public.is_owner())
with check (public.is_owner());

create policy "photos customer read" on public.booking_photos
for select to authenticated
using (user_id = auth.uid() or public.is_owner());

create policy "booking photos read own or owner" on storage.objects
for select to authenticated
using (
  bucket_id = 'booking-photos' and
  ((storage.foldername(name))[1] = auth.uid()::text or public.is_owner())
);

-- Make YOUR account the owner. Replace the email below before running.
update public.profiles
set role = 'owner'
where id = (select id from auth.users where email = 'YOUR_OWNER_EMAIL');
