-- IvyRehab Tasks: one-time database setup / upgrade.
-- Safe to run more than once. Paste into Supabase > SQL Editor > Run.

-- 1) Tasks table (creates it if missing, adds newer columns if it already exists)
CREATE TABLE IF NOT EXISTS public.tasks (
  id TEXT PRIMARY KEY,
  text TEXT NOT NULL,
  date TEXT,
  done BOOLEAN DEFAULT false,
  created TEXT,
  is_order BOOLEAN DEFAULT false,
  note TEXT DEFAULT ''
);
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS assignee   TEXT DEFAULT '';
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS urgent     BOOLEAN DEFAULT false;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS added_by   TEXT DEFAULT '';
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();

-- 2) Shared notes sections
CREATE TABLE IF NOT EXISTS public.notes (
  id TEXT PRIMARY KEY,
  title TEXT DEFAULT '',
  body TEXT DEFAULT '',
  updated_by TEXT DEFAULT '',
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3) OT waitlist
CREATE TABLE IF NOT EXISTS public.waitlist (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  details TEXT DEFAULT '',
  status TEXT DEFAULT 'waiting',
  added_by TEXT DEFAULT '',
  updated_by TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4) Access rules (anyone with the app can read and write)
ALTER TABLE public.tasks    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all" ON public.tasks;
DROP POLICY IF EXISTS "public_all" ON public.notes;
DROP POLICY IF EXISTS "public_all" ON public.waitlist;
CREATE POLICY "public_all" ON public.tasks    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON public.notes    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON public.waitlist FOR ALL USING (true) WITH CHECK (true);

-- 5) Turn on real-time broadcasting so changes appear instantly for everyone
DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['tasks', 'notes', 'waitlist'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = t) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
    END IF;
  END LOOP;
END $$;
