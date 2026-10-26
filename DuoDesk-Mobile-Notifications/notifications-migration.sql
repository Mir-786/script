-- DuoDesk notifications migration
-- Run this in Supabase Dashboard > SQL Editor.

CREATE TABLE IF NOT EXISTS public.duodesk_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  sender_name TEXT NOT NULL,
  sender_email TEXT NOT NULL,
  recipient_name TEXT NOT NULL,
  recipient_email TEXT NOT NULL,
  work_id UUID,
  work_title TEXT NOT NULL DEFAULT 'Shared work',
  message TEXT NOT NULL DEFAULT '',
  type TEXT NOT NULL DEFAULT 'share' CHECK (type IN ('share', 'progress')),
  from_stage TEXT,
  to_stage TEXT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS duodesk_notifications_recipient_created_idx
  ON public.duodesk_notifications (recipient_email, created_at DESC);
CREATE INDEX IF NOT EXISTS duodesk_notifications_sender_created_idx
  ON public.duodesk_notifications (sender_email, created_at DESC);

ALTER TABLE public.duodesk_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "DuoDesk users can read their notifications" ON public.duodesk_notifications;
CREATE POLICY "DuoDesk users can read their notifications"
ON public.duodesk_notifications FOR SELECT TO authenticated
USING (
  lower(auth.jwt() ->> 'email') IN ('miraj@duodesk.app', 'moyna@duodesk.app')
  AND (
    lower(recipient_email) = lower(auth.jwt() ->> 'email')
    OR lower(sender_email) = lower(auth.jwt() ->> 'email')
  )
);

DROP POLICY IF EXISTS "DuoDesk users can send notifications" ON public.duodesk_notifications;
CREATE POLICY "DuoDesk users can send notifications"
ON public.duodesk_notifications FOR INSERT TO authenticated
WITH CHECK (
  lower(auth.jwt() ->> 'email') IN ('miraj@duodesk.app', 'moyna@duodesk.app')
  AND lower(sender_email) = lower(auth.jwt() ->> 'email')
  AND lower(recipient_email) IN ('miraj@duodesk.app', 'moyna@duodesk.app')
  AND lower(recipient_email) <> lower(sender_email)
);

DROP POLICY IF EXISTS "Recipients can mark notifications read" ON public.duodesk_notifications;
CREATE POLICY "Recipients can mark notifications read"
ON public.duodesk_notifications FOR UPDATE TO authenticated
USING (lower(recipient_email) = lower(auth.jwt() ->> 'email'))
WITH CHECK (lower(recipient_email) = lower(auth.jwt() ->> 'email'));

-- Enable Realtime for live notifications (safe to run more than once).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'duodesk_notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.duodesk_notifications;
  END IF;
EXCEPTION WHEN undefined_object THEN
  RAISE NOTICE 'supabase_realtime publication was not found; enable it in Database > Publications.';
END $$;
