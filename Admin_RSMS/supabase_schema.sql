-- ============================================================
-- RSMS Admin — Supabase Schema + Seed Data
-- Run this entire file in Supabase SQL Editor
-- ============================================================

-- ─────────────────────────────────────────────
-- 0. Extensions
-- ─────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────
-- 1. STORES TABLE
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.stores (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id         TEXT UNIQUE,
    name             TEXT NOT NULL,
    address          TEXT NOT NULL DEFAULT 'Address not set',
    manager_name     TEXT NOT NULL DEFAULT 'Unassigned',
    manager_initials TEXT NOT NULL DEFAULT '--',
    status           TEXT NOT NULL DEFAULT 'ACTIVE'
                         CHECK (status IN ('ACTIVE', 'MAINTENANCE', 'INVENTORY')),
    image_url        TEXT,
    latitude         DOUBLE PRECISION,
    longitude        DOUBLE PRECISION,
    is_archived      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- 2. STAFF MEMBERS TABLE
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.staff_members (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,
    email       TEXT NOT NULL DEFAULT '',
    role        TEXT NOT NULL,
    location    TEXT NOT NULL DEFAULT '',
    shift       TEXT NOT NULL DEFAULT '',
    image_name  TEXT,
    initials    TEXT NOT NULL DEFAULT '??',
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- 3. ACTIVITY LOG TABLE  (all CRUD operations)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.activity_log (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name  TEXT NOT NULL,
    operation   TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id   UUID NOT NULL,
    record_name TEXT,
    changed_by  TEXT DEFAULT 'Admin',
    payload     JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- 4. AUTO-UPDATE updated_at TRIGGER
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_stores_updated_at ON public.stores;
CREATE TRIGGER trg_stores_updated_at
    BEFORE UPDATE ON public.stores
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_staff_updated_at ON public.staff_members;
CREATE TRIGGER trg_staff_updated_at
    BEFORE UPDATE ON public.staff_members
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─────────────────────────────────────────────
-- 5. ACTIVITY LOG TRIGGER — STORES
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.log_store_activity()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.activity_log (table_name, operation, record_id, record_name, payload)
        VALUES ('stores', 'INSERT', NEW.id, NEW.name, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO public.activity_log (table_name, operation, record_id, record_name, payload)
        VALUES ('stores', 'UPDATE', NEW.id, NEW.name, jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW)));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO public.activity_log (table_name, operation, record_id, record_name, payload)
        VALUES ('stores', 'DELETE', OLD.id, OLD.name, to_jsonb(OLD));
        RETURN OLD;
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_stores_activity ON public.stores;
CREATE TRIGGER trg_stores_activity
    AFTER INSERT OR UPDATE OR DELETE ON public.stores
    FOR EACH ROW EXECUTE FUNCTION public.log_store_activity();

-- ─────────────────────────────────────────────
-- 6. ACTIVITY LOG TRIGGER — STAFF
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.log_staff_activity()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.activity_log (table_name, operation, record_id, record_name, payload)
        VALUES ('staff_members', 'INSERT', NEW.id, NEW.name, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO public.activity_log (table_name, operation, record_id, record_name, payload)
        VALUES ('staff_members', 'UPDATE', NEW.id, NEW.name, jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW)));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO public.activity_log (table_name, operation, record_id, record_name, payload)
        VALUES ('staff_members', 'DELETE', OLD.id, OLD.name, to_jsonb(OLD));
        RETURN OLD;
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_staff_activity ON public.staff_members;
CREATE TRIGGER trg_staff_activity
    AFTER INSERT OR UPDATE OR DELETE ON public.staff_members
    FOR EACH ROW EXECUTE FUNCTION public.log_staff_activity();

-- ─────────────────────────────────────────────
-- 7. ROW LEVEL SECURITY
-- ─────────────────────────────────────────────
ALTER TABLE public.stores         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_members  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log   ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allow_all_stores"        ON public.stores;
DROP POLICY IF EXISTS "allow_all_staff"         ON public.staff_members;
DROP POLICY IF EXISTS "allow_all_activity_log"  ON public.activity_log;

CREATE POLICY "allow_all_stores"       ON public.stores        FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_staff"        ON public.staff_members  FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_activity_log" ON public.activity_log   FOR ALL USING (true) WITH CHECK (true);

-- ─────────────────────────────────────────────
-- 8. SEED DATA — STORES
-- ─────────────────────────────────────────────
INSERT INTO public.stores
    (id, store_id, name, address, manager_name, manager_initials, status, latitude, longitude, is_archived)
VALUES
    ('11111111-0000-0000-0000-000000000001','GB-0001','London Flagship',
     '1 Oxford Street, London, W1D 1AN, United Kingdom','James Whitfield','JW','ACTIVE',51.5154,-0.1410,FALSE),
    ('11111111-0000-0000-0000-000000000002','US-0001','New York Midtown',
     '500 Fifth Avenue, New York, NY 10110, United States','Sarah Jenkins','SJ','ACTIVE',40.7549,-73.9840,FALSE),
    ('11111111-0000-0000-0000-000000000003','AE-0001','Dubai Mall Boutique',
     'Dubai Mall, Financial Centre Road, Dubai, UAE','Omar Al-Rashid','OA','ACTIVE',25.1972,55.2796,FALSE),
    ('11111111-0000-0000-0000-000000000004','JP-0001','Tokyo Ginza',
     '4-5-6 Ginza, Chuo City, Tokyo 104-0061, Japan','Yuki Tanaka','YT','MAINTENANCE',35.6717,139.7650,FALSE),
    ('11111111-0000-0000-0000-000000000005','FR-0001','Paris Flagship',
     '101 Avenue des Champs-Elysees, 75008 Paris, France','Claire Dubois','CD','ACTIVE',48.8731,2.2979,FALSE),
    ('11111111-0000-0000-0000-000000000006','SG-0001','Singapore Orchard',
     '391 Orchard Road, Ngee Ann City, Singapore 238872','Li Wei','LW','ACTIVE',1.3009,103.8363,FALSE),
    ('11111111-0000-0000-0000-000000000007','IN-0001','Mumbai Bandra',
     'Linking Road, Bandra West, Mumbai 400050, India','Priya Sharma','PS','ACTIVE',19.0596,72.8295,FALSE),
    ('11111111-0000-0000-0000-000000000008','AU-0001','Sydney CBD',
     '455 George Street, Sydney NSW 2000, Australia','Tom Hargreaves','TH','INVENTORY',-33.8731,151.2069,FALSE),
    ('11111111-0000-0000-0000-000000000009','DE-0001','Berlin Mitte',
     'Friedrichstrasse 76, 10117 Berlin, Germany','Hans Mueller','HM','ACTIVE',52.5170,13.3888,FALSE),
    ('11111111-0000-0000-0000-000000000010','CA-0001','Toronto Bloor',
     '100 Bloor Street West, Toronto, ON M5S 1M8, Canada','Emily Chan','EC','ACTIVE',43.6694,-79.3928,FALSE)
ON CONFLICT (id) DO NOTHING;

-- ─────────────────────────────────────────────
-- 9. SEED DATA — STAFF MEMBERS
-- ─────────────────────────────────────────────
INSERT INTO public.staff_members
    (id, name, email, role, location, shift, initials, is_archived)
VALUES
    ('22222222-0000-0000-0000-000000000001','James Whitfield','j.whitfield@rsms.com','Store Manager','London Flagship','Shift: 09:00 - 18:00','JW',FALSE),
    ('22222222-0000-0000-0000-000000000002','Sarah Jenkins','s.jenkins@rsms.com','Store Manager','New York Midtown','Shift: 08:00 - 17:00','SJ',FALSE),
    ('22222222-0000-0000-0000-000000000003','Omar Al-Rashid','o.alrashid@rsms.com','Store Manager','Dubai Mall Boutique','Shift: 10:00 - 22:00','OA',FALSE),
    ('22222222-0000-0000-0000-000000000004','Yuki Tanaka','y.tanaka@rsms.com','Store Manager','Tokyo Ginza','Shift: 09:00 - 18:00','YT',FALSE),
    ('22222222-0000-0000-0000-000000000005','Claire Dubois','c.dubois@rsms.com','Store Manager','Paris Flagship','Shift: 09:30 - 18:30','CD',FALSE),
    ('22222222-0000-0000-0000-000000000006','Li Wei','l.wei@rsms.com','Store Manager','Singapore Orchard','Shift: 10:00 - 19:00','LW',FALSE),
    ('22222222-0000-0000-0000-000000000007','Priya Sharma','p.sharma@rsms.com','Store Manager','Mumbai Bandra','Shift: 09:00 - 18:00','PS',FALSE),
    ('22222222-0000-0000-0000-000000000008','Tom Hargreaves','t.hargreaves@rsms.com','Store Manager','Sydney CBD','Shift: 08:30 - 17:30','TH',FALSE),
    ('22222222-0000-0000-0000-000000000009','Hans Mueller','h.mueller@rsms.com','Store Manager','Berlin Mitte','Shift: 09:00 - 18:00','HM',FALSE),
    ('22222222-0000-0000-0000-000000000010','Emily Chan','e.chan@rsms.com','Store Manager','Toronto Bloor','Shift: 09:00 - 17:00','EC',FALSE),
    ('22222222-0000-0000-0000-000000000011','Marcus Green','m.green@rsms.com','Administrator','London Flagship','Shift: 08:00 - 16:00','MG',FALSE),
    ('22222222-0000-0000-0000-000000000012','Aisha Patel','a.patel@rsms.com','Administrator','New York Midtown','Shift: 10:00 - 18:00','AP',FALSE),
    ('22222222-0000-0000-0000-000000000013','Luca Romano','l.romano@rsms.com','Sales Lead','Paris Flagship','Shift: 12:00 - 20:00','LR',FALSE),
    ('22222222-0000-0000-0000-000000000014','Fatima Al-Sayed','f.alsayed@rsms.com','Operations Lead','Dubai Mall Boutique','Shift: 14:00 - 22:00','FA',FALSE),
    ('22222222-0000-0000-0000-000000000015','Ryan Nakamura','r.nakamura@rsms.com','Sales Lead','Tokyo Ginza','Shift: 11:00 - 20:00','RN',FALSE)
ON CONFLICT (id) DO NOTHING;

-- ─────────────────────────────────────────────
-- Verify:
-- SELECT * FROM stores ORDER BY store_id;
-- SELECT * FROM staff_members ORDER BY name;
-- SELECT * FROM activity_log ORDER BY created_at DESC;
-- ─────────────────────────────────────────────
