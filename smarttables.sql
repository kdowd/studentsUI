-- =====================================================================
--  Smartphones schema: makers, screens, smartphones
--
--  Run in this order:
--      psql -d <database> -f smarttables.sql
--      psql -d <database> -f smartdata.sql
--
--  This file is re-runnable: it drops and recreates everything each time.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Clean up first, in dependency order (children before parents).
--
-- Note: no CASCADE. Dropping the tables explicitly means Postgres never
-- silently removes some other object that happens to depend on them.
-- ---------------------------------------------------------------------
drop table if exists public.smartphones;
drop table if exists public.screens;
drop table if exists public.makers;

-- ---------------------------------------------------------------------
-- 1. Makers (Apple, Samsung, Huawei, Oppo)
-- ---------------------------------------------------------------------
create table public.makers (
  maker_id   int  generated always as identity primary key,
  maker_name text not null unique
);

-- ---------------------------------------------------------------------
-- 2. Screen sizes (referenced lookup table)
--
--    size_cms is a generated column, so it can never drift out of sync
--    with size_inches. It needs no UNIQUE constraint of its own: it is
--    derived from size_inches, which is already UNIQUE.
-- ---------------------------------------------------------------------
create table public.screens (
  screen_size_id integer      generated always as identity primary key,
  size_inches    numeric(3,1) not null unique,
  size_cms       numeric(3,1) generated always as (size_inches * 2.54) stored,
  constraint screens_size_inches_check check (size_inches > 0)
);

-- ---------------------------------------------------------------------
-- 3. Smartphones (depends on both lookup tables)
-- ---------------------------------------------------------------------
create table public.smartphones (
  phone_id       int  generated always as identity primary key,
  model_name     text not null,
  maker_id       int  not null references public.makers  (maker_id),
  screen_size_id int  not null references public.screens (screen_size_id),
  release_year   int  not null check (release_year between 2007 and 2100),
  os             text not null check (os in ('Android', 'iOS'))
);

-- ---------------------------------------------------------------------
-- Postgres does not index foreign keys automatically, so joins on these
-- columns would otherwise fall back to sequential scans.
-- ---------------------------------------------------------------------
create index idx_smartphones_maker_id       on public.smartphones (maker_id);
create index idx_smartphones_screen_size_id on public.smartphones (screen_size_id);
