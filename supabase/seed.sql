-- =============================================================
-- GAPP Seed Data for Testing
-- Run AFTER schema.sql and AFTER creating users in Supabase Auth
--
-- INSTRUCTIONS:
-- 1. Go to Supabase Dashboard > Authentication > Users
-- 2. Create these 6 users with "Add User" (email + password):
--
--    admin@gapp.es       / admin123
--    carlos@gapp.es      / gardener123
--    maria@gapp.es       / gardener123
--    ana@cliente.es      / client123
--    pedro@cliente.es    / client123
--    laura@cliente.es    / client123
--
-- 3. Copy the UUIDs from the Auth dashboard and paste them below
-- 4. Run this script in SQL Editor
-- =============================================================

-- !! REPLACE these with real UUIDs from your Supabase Auth dashboard !!
DO $$
DECLARE
  admin_id   uuid := '00000000-0000-0000-0000-000000000001'; -- admin@gapp.es
  carlos_id  uuid := '00000000-0000-0000-0000-000000000002'; -- carlos@gapp.es
  maria_id   uuid := '00000000-0000-0000-0000-000000000003'; -- maria@gapp.es
  ana_id     uuid := '00000000-0000-0000-0000-000000000004'; -- ana@cliente.es
  pedro_id   uuid := '00000000-0000-0000-0000-000000000005'; -- pedro@cliente.es
  laura_id   uuid := '00000000-0000-0000-0000-000000000006'; -- laura@cliente.es

  -- Profile IDs (auto-generated)
  carlos_gp  uuid := gen_random_uuid();
  maria_gp   uuid := gen_random_uuid();
  ana_cp     uuid := gen_random_uuid();
  pedro_cp   uuid := gen_random_uuid();
  laura_cp   uuid := gen_random_uuid();

  -- Garden IDs
  g_hortensia uuid := gen_random_uuid();
  g_canroca   uuid := gen_random_uuid();
  g_masdemar  uuid := gen_random_uuid();
  g_olivar    uuid := gen_random_uuid();
  g_mirador   uuid := gen_random_uuid();

  -- Visit IDs
  v1 uuid := gen_random_uuid();
  v2 uuid := gen_random_uuid();
  v3 uuid := gen_random_uuid();
  v4 uuid := gen_random_uuid();
  v5 uuid := gen_random_uuid();

  -- Conversation IDs
  conv1 uuid := gen_random_uuid();
  conv2 uuid := gen_random_uuid();
  conv3 uuid := gen_random_uuid();

BEGIN

-- =============================================================
-- 1. UPDATE USER PROFILES (created by trigger, update roles)
-- =============================================================

UPDATE public.user_profiles SET role = 'ADMIN', display_name = 'Admin GAPP'
  WHERE id = admin_id;

UPDATE public.user_profiles SET role = 'GARDENER', display_name = 'Carlos Martínez'
  WHERE id = carlos_id;

UPDATE public.user_profiles SET role = 'GARDENER', display_name = 'María López'
  WHERE id = maria_id;

UPDATE public.user_profiles SET role = 'CLIENT', display_name = 'Ana García', phone = '+34 634 567 890'
  WHERE id = ana_id;

UPDATE public.user_profiles SET role = 'CLIENT', display_name = 'Pedro Sánchez', phone = '+34 645 678 901'
  WHERE id = pedro_id;

UPDATE public.user_profiles SET role = 'CLIENT', display_name = 'Laura Fernández', phone = '+34 656 789 012'
  WHERE id = laura_id;

-- =============================================================
-- 2. GARDENER PROFILES
-- =============================================================

INSERT INTO public.gardener_profiles (id, user_id, display_name, phone, avatar_url) VALUES
  (carlos_gp, carlos_id, 'Carlos Martínez', '+34 612 345 678',
   'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face'),
  (maria_gp, maria_id, 'María López', '+34 623 456 789',
   'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&h=150&fit=crop&crop=face');

-- =============================================================
-- 3. CLIENT PROFILES
-- =============================================================

INSERT INTO public.client_profiles (id, user_id, display_name, phone) VALUES
  (ana_cp, ana_id, 'Ana García', '+34 634 567 890'),
  (pedro_cp, pedro_id, 'Pedro Sánchez', '+34 645 678 901'),
  (laura_cp, laura_id, 'Laura Fernández', '+34 656 789 012');

-- =============================================================
-- 4. GARDENS
-- =============================================================

INSERT INTO public.gardens (id, client_id, name, address, latitude, longitude, qr_code) VALUES
  (g_hortensia, ana_cp, 'Villa Hortensia', '122 Calle de las Rosas, Madrid',
   40.4168, -3.7038, 'GAPP-VH-001'),
  (g_canroca, ana_cp, 'Can Roca', 'Av. Diagonal 450, Barcelona',
   41.3874, 2.1686, 'GAPP-CR-002'),
  (g_masdemar, pedro_cp, 'Mas de Mar', 'Camí de Ronda s/n, Costa Brava',
   41.7220, 2.9330, 'GAPP-MM-003'),
  (g_olivar, pedro_cp, 'El Olivar', 'Plaza Mayor 12, Segovia',
   40.9429, -4.1088, 'GAPP-EO-004'),
  (g_mirador, laura_cp, 'El Mirador', 'Paseo Marítimo 8, Sitges',
   41.2371, 1.8058, 'GAPP-EM-005');

-- =============================================================
-- 5. GARDEN ASSIGNMENTS
-- =============================================================

INSERT INTO public.garden_assignments (garden_id, gardener_id, is_active, valid_from) VALUES
  (g_hortensia, carlos_gp, true, '2026-01-15'),
  (g_canroca, carlos_gp, true, '2026-02-01'),
  (g_masdemar, carlos_gp, true, '2026-02-10'),
  (g_olivar, maria_gp, true, '2026-03-01'),
  (g_mirador, maria_gp, true, '2026-03-15');

-- =============================================================
-- 6. VISITS (completed)
-- =============================================================

INSERT INTO public.visits (id, garden_id, gardener_id, status, verification_status, initiation_method, title, description, public_comment, started_at, ended_at) VALUES
  (v1, g_hortensia, carlos_gp, 'CLOSED', 'VERIFIED', 'QR_SCAN',
   'Poda y limpieza',
   'Poda de arbustos ornamentales del camino principal. Limpieza de residuos estacionales de los parterres.',
   'Poda completada y limpieza de zona de paso.',
   '2026-04-08 09:12:00+02', '2026-04-08 10:49:00+02'),

  (v2, g_canroca, carlos_gp, 'CLOSED', 'VERIFIED', 'MANUAL',
   'Corte de césped',
   'Mantenimiento estándar del césped. Bordes recortados y fertilización aplicada en el sector norte.',
   'Mantenimiento general del césped y bordes.',
   '2026-04-02 08:30:00+02', '2026-04-02 10:15:00+02'),

  (v3, g_masdemar, carlos_gp, 'CLOSED', 'NOT_VERIFIED', 'MANUAL',
   'Revisión de riego',
   'Verificación de todos los aspersores. Reemplazo de una válvula dañada en la zona 3.',
   'Revisión de riego y sustitución de válvula.',
   '2026-03-26 11:04:00+02', '2026-03-26 12:02:00+02'),

  (v4, g_olivar, maria_gp, 'CLOSED', 'VERIFIED', 'QR_SCAN',
   'Tratamiento de olivos',
   'Aplicación de tratamiento preventivo contra mosca del olivo. Poda de ramas bajas.',
   'Tratamiento preventivo aplicado a los 12 olivos.',
   '2026-04-05 10:00:00+02', '2026-04-05 12:30:00+02'),

  (v5, g_mirador, maria_gp, 'CLOSED', 'VERIFIED', 'QR_SCAN',
   'Plantación de temporada',
   'Plantación de flores de primavera en los parterres del jardín delantero. Geranios, petunias y lavanda.',
   'Plantación completada. Regar abundantemente los primeros 3 días.',
   '2026-04-07 08:00:00+02', '2026-04-07 11:15:00+02');

-- =============================================================
-- 7. VISIT PHOTOS
-- =============================================================

INSERT INTO public.visit_photos (visit_id, storage_path, thumbnail_path, label) VALUES
  (v1, 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800', '', 'PODA'),
  (v1, 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=800', '', 'ROSALES'),
  (v1, 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800', '', 'ABONO'),
  (v2, 'https://images.unsplash.com/photo-1592150621744-aca64f48394a?w=800', '', 'CÉSPED'),
  (v3, 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800', '', 'RIEGO'),
  (v4, 'https://images.unsplash.com/photo-1534710961216-75c88202f43e?w=800', '', 'OLIVOS'),
  (v4, 'https://images.unsplash.com/photo-1509587584298-0f3b3a3a1797?w=800', '', 'TRATAMIENTO'),
  (v5, 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800', '', 'GERANIOS'),
  (v5, 'https://images.unsplash.com/photo-1490750967868-88aa4f44baee?w=800', '', 'LAVANDA');

-- =============================================================
-- 8. CONVERSATIONS
-- =============================================================

INSERT INTO public.conversations (id, gardener_id, client_id, garden_id, status, last_message_at, unread_message_count) VALUES
  (conv1, carlos_gp, ana_cp, g_hortensia, 'ACTIVE', '2026-04-08 14:30:00+02', 2),
  (conv2, carlos_gp, pedro_cp, g_masdemar, 'ACTIVE', '2026-04-06 10:15:00+02', 0),
  (conv3, maria_gp, laura_cp, g_mirador, 'ACTIVE', '2026-04-07 16:00:00+02', 1);

-- =============================================================
-- 9. MESSAGES
-- =============================================================

-- Conversation 1: Carlos <-> Ana (Villa Hortensia)
INSERT INTO public.messages (conversation_id, sender_id, recipient_id, sender_role, content_type, content, requires_response, is_read, created_at) VALUES
  (conv1, carlos_id, ana_id, 'GARDENER', 'TEXT',
   'Buenos días Ana. He completado la poda de los arbustos del camino. Todo en buen estado.',
   false, true, '2026-04-08 11:00:00+02'),

  (conv1, ana_id, carlos_id, 'CLIENT', 'TEXT',
   'Perfecto Carlos, gracias! He visto las fotos, muy buen trabajo.',
   false, true, '2026-04-08 12:15:00+02'),

  (conv1, carlos_id, ana_id, 'GARDENER', 'TEXT',
   'He visto que el sistema de riego de la zona este necesita una revisión. Le paso presupuesto: 85€ por el cambio de 2 electroválvulas. ¿Le parece bien?',
   true, false, '2026-04-08 14:00:00+02'),

  (conv1, carlos_id, ana_id, 'GARDENER', 'TEXT',
   'También recomendaría añadir abono orgánico en los rosales la próxima visita. Coste adicional: 25€.',
   true, false, '2026-04-08 14:30:00+02');

-- Conversation 2: Carlos <-> Pedro (Mas de Mar)
INSERT INTO public.messages (conversation_id, sender_id, recipient_id, sender_role, content_type, content, requires_response, is_read, created_at) VALUES
  (conv2, carlos_id, pedro_id, 'GARDENER', 'TEXT',
   'Hola Pedro. He cambiado la válvula de la zona 3 del riego. Ahora funciona correctamente.',
   false, true, '2026-03-26 13:00:00+02'),

  (conv2, pedro_id, carlos_id, 'CLIENT', 'TEXT',
   'Gracias Carlos. ¿Cuándo sería la próxima visita programada?',
   false, true, '2026-03-27 09:00:00+02'),

  (conv2, carlos_id, pedro_id, 'GARDENER', 'TEXT',
   'La tengo prevista para el 15 de abril. ¿Le va bien por la mañana?',
   false, true, '2026-04-06 10:15:00+02');

-- Conversation 3: María <-> Laura (El Mirador)
INSERT INTO public.messages (conversation_id, sender_id, recipient_id, sender_role, content_type, content, requires_response, is_read, created_at) VALUES
  (conv3, maria_id, laura_id, 'GARDENER', 'TEXT',
   'Hola Laura! He plantado los geranios, petunias y lavanda como acordamos. Recuerde regar abundantemente los primeros 3 días.',
   false, true, '2026-04-07 11:30:00+02'),

  (conv3, laura_id, maria_id, 'CLIENT', 'TEXT',
   'Genial María! Me encanta cómo ha quedado. Una pregunta: ¿sería posible añadir un seto de boj en la entrada?',
   false, true, '2026-04-07 14:00:00+02'),

  (conv3, maria_id, laura_id, 'GARDENER', 'TEXT',
   'Claro! Le preparo un presupuesto. Para 6 metros lineales de boj: 320€ (plantas + mano de obra + sustrato). ¿Le interesa?',
   true, false, '2026-04-07 16:00:00+02');

-- =============================================================
-- 10. MESSAGE RESPONSES
-- =============================================================

-- (No responses yet — the pending requests are waiting for client approval)

END $$;
