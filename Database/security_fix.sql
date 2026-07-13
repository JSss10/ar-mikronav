-- AR-Mikronavigation – Security-Fix für Supabase Advisor Warnungen
-- Stand: 13.07.2026
--
-- Behebt: "rls_disabled_in_public" (Tabelle öffentlich zugreifbar)
-- Ausführen im Supabase Dashboard → SQL Editor (einmalig, idempotent).
--
-- Hintergrund:
--   1. CREATE EXTENSION postgis legt die Tabelle public.spatial_ref_sys
--      ohne RLS an → der Security Advisor meldet sie als öffentlich.
--   2. Falls die App-Tabellen ohne den RLS-Abschnitt aus schema.sql
--      angelegt wurden, sind sie ebenfalls offen.
--   3. Ab 30.10.2026 vergibt Supabase keine impliziten Grants mehr für
--      Data-API-Rollen → explizite GRANTs hier mit dabei.

-- ============================================================
-- 1. RLS auf allen App-Tabellen aktivieren (idempotent)
-- ============================================================

ALTER TABLE public.barriers          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poi_accessibility ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_areas        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_feedback     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_places      ENABLE ROW LEVEL SECURITY;

-- Policies neu anlegen (DROP + CREATE, da CREATE POLICY kein IF NOT EXISTS kennt)

-- barriers: öffentliche Referenzdaten, nur lesen
DROP POLICY IF EXISTS "barriers_read" ON public.barriers;
CREATE POLICY "barriers_read" ON public.barriers
    FOR SELECT USING (true);

-- poi_accessibility: öffentliche Referenzdaten, nur lesen
DROP POLICY IF EXISTS "poi_read" ON public.poi_accessibility;
CREATE POLICY "poi_read" ON public.poi_accessibility
    FOR SELECT USING (true);

-- test_areas: öffentliche Referenzdaten, nur lesen
DROP POLICY IF EXISTS "test_areas_read" ON public.test_areas;
CREATE POLICY "test_areas_read" ON public.test_areas
    FOR SELECT USING (true);

-- user_feedback: nur eigene Zeilen
DROP POLICY IF EXISTS "feedback_insert" ON public.user_feedback;
CREATE POLICY "feedback_insert" ON public.user_feedback
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "feedback_select" ON public.user_feedback;
CREATE POLICY "feedback_select" ON public.user_feedback
    FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- saved_places: nur eigene Zeilen
DROP POLICY IF EXISTS "saved_insert" ON public.saved_places;
CREATE POLICY "saved_insert" ON public.saved_places
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "saved_select" ON public.saved_places;
CREATE POLICY "saved_select" ON public.saved_places
    FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "saved_delete" ON public.saved_places;
CREATE POLICY "saved_delete" ON public.saved_places
    FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- ============================================================
-- 2. Explizite Grants für die Data-API-Rollen
--    (Pflicht für neue Tabellen ab 30.10.2026, schadet jetzt nicht)
-- ============================================================

-- Lesende Referenzdaten: anon + authenticated dürfen lesen
GRANT SELECT ON public.barriers, public.poi_accessibility, public.test_areas
    TO anon, authenticated;

-- Nutzerdaten: nur authenticated (RLS-Policies schränken auf eigene Zeilen ein)
GRANT SELECT, INSERT ON public.user_feedback TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.saved_places TO authenticated;

-- service_role (Server-seitige Jobs, z. B. OSM-Import) braucht Vollzugriff
GRANT SELECT, INSERT, UPDATE, DELETE
    ON public.barriers, public.poi_accessibility, public.test_areas,
       public.user_feedback, public.saved_places
    TO service_role;

-- ============================================================
-- 3. PostGIS: spatial_ref_sys absichern
-- ============================================================
-- spatial_ref_sys enthält nur öffentliche SRID-Referenzdaten (keine
-- Nutzerdaten). RLS mit einer Lese-Policy genügt, um die Warnung zu
-- beheben, ohne PostGIS-Funktionen zu beeinträchtigen.
--
-- Hinweis: Falls hier "must be owner of table spatial_ref_sys" erscheint,
-- wurde die Extension von supabase_admin angelegt. Dann ist die Warnung
-- laut Supabase-Doku unkritisch und kann im Security Advisor als
-- "ignored" markiert werden – oder PostGIS wird ins Schema "extensions"
-- verschoben (erfordert DROP/CREATE der Extension, siehe schema.sql).

DO $$
BEGIN
    EXECUTE 'ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "spatial_ref_sys_read" ON public.spatial_ref_sys';
    EXECUTE 'CREATE POLICY "spatial_ref_sys_read" ON public.spatial_ref_sys FOR SELECT USING (true)';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'Keine Owner-Rechte auf spatial_ref_sys – Warnung im Security Advisor als "ignored" markieren oder PostGIS ins Schema "extensions" verschieben.';
END $$;

-- ============================================================
-- 4. Kontrolle: alle Tabellen in public ohne RLS auflisten
--    (Ergebnis sollte leer sein bzw. nur spatial_ref_sys zeigen,
--     falls Schritt 3 mangels Rechten übersprungen wurde)
-- ============================================================

SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = false;
