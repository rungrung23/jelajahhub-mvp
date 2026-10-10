-- JelajahHub MVP schema. Run once in Supabase SQL Editor.
create extension if not exists pgcrypto;
create type public.user_role as enum ('agent','admin');
create type public.approval_status as enum ('pending','approved','rejected','suspended');
create type public.travel_category as enum ('umroh','haji','domestik','internasional');

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text,
 role public.user_role not null default 'agent',
 created_at timestamptz not null default now()
);
create table public.travel_companies (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null unique references auth.users(id) on delete cascade,
 name text not null,
 slug text not null unique,
 description text,
 whatsapp text not null,
 city text not null,
 website text,
 logo_url text,
 legal_document_url text,
 status public.approval_status not null default 'pending',
 review_note text,
 reviewed_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.travel_packages (
 id uuid primary key default gen_random_uuid(),
 company_id uuid not null references public.travel_companies(id) on delete cascade,
 title text not null,
 slug text not null unique,
 category public.travel_category not null,
 destination text not null,
 price numeric(14,2) not null check(price >= 0),
 duration_days integer not null check(duration_days > 0),
 summary text,
 cover_image text,
 status public.approval_status not null default 'pending',
 review_note text,
 reviewed_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.landing_pages (
 id uuid primary key default gen_random_uuid(),
 company_id uuid not null references public.travel_companies(id) on delete cascade,
 package_id uuid references public.travel_packages(id) on delete set null,
 title text not null,
 slug text not null unique,
 headline text not null,
 body text not null,
 cta_text text not null default 'Hubungi via WhatsApp',
 status public.approval_status not null default 'pending',
 review_note text,
 reviewed_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.approval_logs (
 id uuid primary key default gen_random_uuid(),
 reviewer_id uuid references auth.users(id) on delete set null,
 entity_type text not null check(entity_type in ('company','package','landing_page')),
 entity_id uuid not null,
 old_status public.approval_status,
 new_status public.approval_status not null,
 note text,
 created_at timestamptz not null default now()
);
create table public.page_views (
 id bigint generated always as identity primary key,
 landing_page_id uuid references public.landing_pages(id) on delete cascade,
 package_id uuid references public.travel_packages(id) on delete cascade,
 viewed_at timestamptz not null default now(),
 check ((case when landing_page_id is not null then 1 else 0 end) + (case when package_id is not null then 1 else 0 end) = 1)
);
create index travel_packages_public_idx on public.travel_packages(status,category,created_at desc);
create index landing_pages_public_idx on public.landing_pages(status,created_at desc);
create index companies_status_idx on public.travel_companies(status,created_at desc);

-- New auth users are always agents. Never trust a client-supplied role.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id, full_name, role) values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name',''), 'agent') on conflict (id) do nothing;
 return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin');
$$;
create or replace function public.owns_company(company_uuid uuid) returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.travel_companies c where c.id = company_uuid and c.owner_id = (select auth.uid()));
$$;

alter table public.profiles enable row level security;
alter table public.travel_companies enable row level security;
alter table public.travel_packages enable row level security;
alter table public.landing_pages enable row level security;
alter table public.approval_logs enable row level security;
alter table public.page_views enable row level security;

create policy "profiles read self or admin" on public.profiles for select to authenticated using (id=(select auth.uid()) or public.is_admin());
create policy "agents update own profile without role change" on public.profiles for update to authenticated using (id=(select auth.uid()) and role='agent') with check (id=(select auth.uid()) and role='agent');
create policy "admins manage profiles" on public.profiles for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "public sees approved companies" on public.travel_companies for select to anon, authenticated using (status='approved' or owner_id=(select auth.uid()) or public.is_admin());
create policy "agent submits own company" on public.travel_companies for insert to authenticated with check (owner_id=(select auth.uid()) and status='pending' and not public.is_admin());
-- Company profile edits are admin-only in this MVP so an owner cannot self-approve by changing status.
create policy "admins manage companies" on public.travel_companies for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "public sees approved packages from approved companies" on public.travel_packages for select to anon, authenticated using (status='approved' and exists(select 1 from public.travel_companies c where c.id=company_id and c.status='approved') or public.owns_company(company_id) or public.is_admin());
create policy "approved agents submit pending packages" on public.travel_packages for insert to authenticated with check (public.owns_company(company_id) and status='pending' and exists(select 1 from public.travel_companies c where c.id=company_id and c.owner_id=(select auth.uid()) and c.status='approved'));
create policy "owners edit own packages" on public.travel_packages for update to authenticated using (public.owns_company(company_id) or public.is_admin()) with check ((public.owns_company(company_id) and status='pending') or public.is_admin());
create policy "owners delete own packages" on public.travel_packages for delete to authenticated using (public.owns_company(company_id) or public.is_admin());
create policy "admins manage packages" on public.travel_packages for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "public sees approved landing pages" on public.landing_pages for select to anon, authenticated using (status='approved' and exists(select 1 from public.travel_companies c where c.id=company_id and c.status='approved') or public.owns_company(company_id) or public.is_admin());
create policy "approved agents submit pending landing pages" on public.landing_pages for insert to authenticated with check (public.owns_company(company_id) and status='pending' and exists(select 1 from public.travel_companies c where c.id=company_id and c.owner_id=(select auth.uid()) and c.status='approved'));
create policy "owners edit own landing pages" on public.landing_pages for update to authenticated using (public.owns_company(company_id) or public.is_admin()) with check ((public.owns_company(company_id) and status='pending') or public.is_admin());
create policy "owners delete own landing pages" on public.landing_pages for delete to authenticated using (public.owns_company(company_id) or public.is_admin());
create policy "admins manage landing pages" on public.landing_pages for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "admins read approval logs" on public.approval_logs for select to authenticated using (public.is_admin());
create policy "admins create approval logs" on public.approval_logs for insert to authenticated with check (public.is_admin() and reviewer_id=(select auth.uid()));
create policy "public may record page views" on public.page_views for insert to anon, authenticated with check ((landing_page_id is not null and exists(select 1 from public.landing_pages l join public.travel_companies c on c.id=l.company_id where l.id=landing_page_id and l.status='approved' and c.status='approved')) or (package_id is not null and exists(select 1 from public.travel_packages p join public.travel_companies c on c.id=p.company_id where p.id=package_id and p.status='approved' and c.status='approved')));
create policy "admins read page views" on public.page_views for select to authenticated using (public.is_admin());

-- After registering with your own account, promote it to admin in SQL Editor:
-- update public.profiles set role = 'admin' where id = (select id from auth.users where email = 'YOUR_EMAIL');
