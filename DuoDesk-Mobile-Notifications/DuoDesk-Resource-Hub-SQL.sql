-- DuoDesk Resource Hub migration
-- Run in Supabase Dashboard > SQL Editor for an existing DuoDesk project.

CREATE TABLE IF NOT EXISTS public.resource_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'Other',
  url TEXT NOT NULL,
  notes TEXT NOT NULL DEFAULT '',
  platform TEXT NOT NULL DEFAULT 'Link',
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.resource_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Duo partners can read resources" ON public.resource_items;
DROP POLICY IF EXISTS "Duo partners can add resources" ON public.resource_items;
DROP POLICY IF EXISTS "Duo partners can update resources" ON public.resource_items;
DROP POLICY IF EXISTS "Duo partners can delete resources" ON public.resource_items;

CREATE POLICY "Duo partners can read resources"
ON public.resource_items FOR SELECT TO authenticated
USING ((auth.jwt() ->> 'email') IN ('miraj@duodesk.app', 'moyna@duodesk.app'));

CREATE POLICY "Duo partners can add resources"
ON public.resource_items FOR INSERT TO authenticated
WITH CHECK (
  (auth.jwt() ->> 'email') IN ('miraj@duodesk.app', 'moyna@duodesk.app')
  AND created_by = auth.uid()
);

CREATE POLICY "Duo partners can update resources"
ON public.resource_items FOR UPDATE TO authenticated
USING ((auth.jwt() ->> 'email') IN ('miraj@duodesk.app', 'moyna@duodesk.app'))
WITH CHECK ((auth.jwt() ->> 'email') IN ('miraj@duodesk.app', 'moyna@duodesk.app'));

CREATE POLICY "Duo partners can delete resources"
ON public.resource_items FOR DELETE TO authenticated
USING ((auth.jwt() ->> 'email') IN ('miraj@duodesk.app', 'moyna@duodesk.app'));

CREATE INDEX IF NOT EXISTS resource_items_created_at_idx
ON public.resource_items (created_at DESC);
CREATE INDEX IF NOT EXISTS resource_items_category_idx
ON public.resource_items (category);

CREATE OR REPLACE FUNCTION public.resource_items_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS resource_items_set_updated_at ON public.resource_items;
CREATE TRIGGER resource_items_set_updated_at
BEFORE UPDATE ON public.resource_items
FOR EACH ROW EXECUTE FUNCTION public.resource_items_set_updated_at();

-- Optional: enable resource_items in the supabase_realtime publication
-- using Database > Publications if you want immediate multi-device sync.
