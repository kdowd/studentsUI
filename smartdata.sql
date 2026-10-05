-- =====================================================================
--  Seed data for makers, screens and smartphones.
--  Run after smarttables.sql.
--
--  The phones are staged in a temporary table first so this script can
--  check that every maker and screen size it references actually exists
--  BEFORE inserting. A plain inner join would silently discard unmatched
--  rows, which is how two Samsung models previously went missing.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Lookup rows
--    Every maker and screen size referenced in step 2 must appear here.
-- ---------------------------------------------------------------------
insert into public.makers (maker_name) values
  ('Apple'),
  ('Samsung'),
  ('Huawei'),
  ('Oppo');

insert into public.screens (size_inches) values
  (6.1),
  (6.2),   -- Galaxy S24
  (6.3),
  (6.4),
  (6.5),
  (6.7),
  (6.8),
  (6.9),
  (7.6);   -- Galaxy Z Fold 6

-- ---------------------------------------------------------------------
-- 2. Stage the phones
--    Keeping the seed list in one place lets the checks below inspect
--    exactly what this script intends to insert.
-- ---------------------------------------------------------------------
create temp table if not exists phone_seed (
  model_name   text,
  maker_name   text,
  size_inches  numeric(3,1),
  release_year int,
  os           text
);

truncate phone_seed;

insert into phone_seed (model_name, maker_name, size_inches, release_year, os) values
  -- Apple (iOS) — 4 models
  ('iPhone 15 Pro',     'Apple',   6.1, 2023, 'iOS'),
  ('iPhone 15 Pro Max', 'Apple',   6.7, 2023, 'iOS'),
  ('iPhone 16 Pro',     'Apple',   6.3, 2024, 'iOS'),
  ('iPhone 16 Pro Max', 'Apple',   6.9, 2024, 'iOS'),

  -- Samsung (Android) — 3 models
  ('Galaxy S24',        'Samsung', 6.2, 2024, 'Android'),
  ('Galaxy S24 Ultra',  'Samsung', 6.8, 2024, 'Android'),
  ('Galaxy Z Fold 6',   'Samsung', 7.6, 2024, 'Android'),

  -- Huawei (Android-based) — 2 models
  ('P60 Pro',           'Huawei',  6.7, 2023, 'Android'),
  ('Mate 60 Pro',       'Huawei',  6.8, 2023, 'Android'),

  -- Oppo (Android) — 1 model
  ('Find X7 Ultra',     'Oppo',    6.8, 2024, 'Android');

-- ---------------------------------------------------------------------
-- 3. Refuse to insert anything if a lookup row is missing
-- ---------------------------------------------------------------------
do $$
declare
  v_missing text;
begin
  select string_agg(
           format('%s (maker=%s, size=%s)', p.model_name, p.maker_name, p.size_inches),
           '; ' order by p.model_name)
    into v_missing
  from phone_seed p
  left join public.makers  mk on mk.maker_name  = p.maker_name
  left join public.screens ss on ss.size_inches = p.size_inches
  where mk.maker_id is null
     or ss.screen_size_id is null;

  if v_missing is not null then
    raise exception 'Seed aborted — no lookup row for: %', v_missing;
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 4. Insert the phones
-- ---------------------------------------------------------------------
insert into public.smartphones (model_name, maker_id, screen_size_id, release_year, os)
select p.model_name, mk.maker_id, ss.screen_size_id, p.release_year, p.os
from phone_seed p
join public.makers  mk on mk.maker_name  = p.maker_name
join public.screens ss on ss.size_inches = p.size_inches;



drop table if exists phone_seed;
