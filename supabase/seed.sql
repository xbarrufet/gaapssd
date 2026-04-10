-- =============================================================
-- GAPP Complete Seed Data
-- Run in Supabase SQL Editor AFTER schema.sql
-- Creates auth users + all test data in one go
-- =============================================================

-- Clean existing data (safe to re-run)
delete from public.message_responses;
delete from public.messages;
delete from public.conversations;
delete from public.visit_photos;
delete from public.visits;
delete from public.garden_assignments;
delete from public.gardens;
delete from public.gardener_profiles;
delete from public.client_profiles;
delete from public.user_profiles;
delete from auth.users where email in (
  'admin@gapp.es', 'carlos@gapp.es', 'maria@gapp.es',
  'ana@cliente.es', 'pedro@cliente.es', 'laura@cliente.es'
);

DO $$
DECLARE
  -- User IDs
  admin_id   uuid := gen_random_uuid();
  carlos_id  uuid := gen_random_uuid();
  maria_id   uuid := gen_random_uuid();
  ana_id     uuid := gen_random_uuid();
  pedro_id   uuid := gen_random_uuid();
  laura_id   uuid := gen_random_uuid();

  -- Profile IDs
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

  -- Shared password hash (bcrypt of 'Test1234!')
  pw_hash text := '$2a$10$PznXHEUJgNqFpOjMGQiIJOiSBEBhSNLGiJlg6iE4iSBJOiSBEBhS';

BEGIN

-- =============================================================
-- 1. AUTH USERS (inserted directly into auth.users)
-- Password for all users: Test1234!
-- =============================================================

INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, is_super_admin
) VALUES
  (admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'admin@gapp.es', crypt('Test1234!', gen_salt('bf')),
   now(), '{"provider":"email","providers":["email"]}',
   '{"display_name":"Admin GAPP","role":"ADMIN"}',
   now(), now(), '', false),

  (carlos_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'carlos@gapp.es', crypt('Test1234!', gen_salt('bf')),
   now(), '{"provider":"email","providers":["email"]}',
   '{"display_name":"Carlos Martínez","role":"GARDENER"}',
   now(), now(), '', false),

  (maria_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'maria@gapp.es', crypt('Test1234!', gen_salt('bf')),
   now(), '{"provider":"email","providers":["email"]}',
   '{"display_name":"María López","role":"GARDENER"}',
   now(), now(), '', false),

  (ana_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'ana@cliente.es', crypt('Test1234!', gen_salt('bf')),
   now(), '{"provider":"email","providers":["email"]}',
   '{"display_name":"Ana García","role":"CLIENT"}',
   now(), now(), '', false),

  (pedro_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'pedro@cliente.es', crypt('Test1234!', gen_salt('bf')),
   now(), '{"provider":"email","providers":["email"]}',
   '{"display_name":"Pedro Sánchez","role":"CLIENT"}',
   now(), now(), '', false),

  (laura_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'laura@cliente.es', crypt('Test1234!', gen_salt('bf')),
   now(), '{"provider":"email","providers":["email"]}',
   '{"display_name":"Laura Fernández","role":"CLIENT"}',
   now(), now(), '', false);

-- Auth identities (required for email login to work)
INSERT INTO auth.identities (
  id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) VALUES
  (admin_id, admin_id, 'admin@gapp.es',
   jsonb_build_object('sub', admin_id, 'email', 'admin@gapp.es'),
   'email', now(), now(), now()),
  (carlos_id, carlos_id, 'carlos@gapp.es',
   jsonb_build_object('sub', carlos_id, 'email', 'carlos@gapp.es'),
   'email', now(), now(), now()),
  (maria_id, maria_id, 'maria@gapp.es',
   jsonb_build_object('sub', maria_id, 'email', 'maria@gapp.es'),
   'email', now(), now(), now()),
  (ana_id, ana_id, 'ana@cliente.es',
   jsonb_build_object('sub', ana_id, 'email', 'ana@cliente.es'),
   'email', now(), now(), now()),
  (pedro_id, pedro_id, 'pedro@cliente.es',
   jsonb_build_object('sub', pedro_id, 'email', 'pedro@cliente.es'),
   'email', now(), now(), now()),
  (laura_id, laura_id, 'laura@cliente.es',
   jsonb_build_object('sub', laura_id, 'email', 'laura@cliente.es'),
   'email', now(), now(), now());

-- =============================================================
-- 2. USER PROFILES (trigger creates them, but we update roles)
-- The on_auth_user_created trigger already inserted rows.
-- Update them with correct roles and phones.
-- =============================================================

UPDATE public.user_profiles SET role = 'ADMIN', display_name = 'Admin GAPP'
  WHERE id = admin_id;
UPDATE public.user_profiles SET role = 'GARDENER', display_name = 'Carlos Martínez', phone = '+34 612 345 678'
  WHERE id = carlos_id;
UPDATE public.user_profiles SET role = 'GARDENER', display_name = 'María López', phone = '+34 623 456 789'
  WHERE id = maria_id;
UPDATE public.user_profiles SET role = 'CLIENT', display_name = 'Ana García', phone = '+34 634 567 890'
  WHERE id = ana_id;
UPDATE public.user_profiles SET role = 'CLIENT', display_name = 'Pedro Sánchez', phone = '+34 645 678 901'
  WHERE id = pedro_id;
UPDATE public.user_profiles SET role = 'CLIENT', display_name = 'Laura Fernández', phone = '+34 656 789 012'
  WHERE id = laura_id;

-- =============================================================
-- 3. GARDENER PROFILES
-- =============================================================

INSERT INTO public.gardener_profiles (id, user_id, display_name, phone, avatar_url) VALUES
  (carlos_gp, carlos_id, 'Carlos Martínez', '+34 612 345 678',
   'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face'),
  (maria_gp, maria_id, 'María López', '+34 623 456 789',
   'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&h=150&fit=crop&crop=face');

-- =============================================================
-- 4. CLIENT PROFILES
-- =============================================================

INSERT INTO public.client_profiles (id, user_id, display_name, phone) VALUES
  (ana_cp, ana_id, 'Ana García', '+34 634 567 890'),
  (pedro_cp, pedro_id, 'Pedro Sánchez', '+34 645 678 901'),
  (laura_cp, laura_id, 'Laura Fernández', '+34 656 789 012');

-- =============================================================
-- 5. GARDENS
-- =============================================================

INSERT INTO public.gardens (id, client_id, name, address, latitude, longitude, qr_code) VALUES
  (g_hortensia, ana_cp, 'Villa Hortensia', 'Calle de las Rosas 122, Madrid',
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
-- 6. GARDEN ASSIGNMENTS
-- =============================================================

INSERT INTO public.garden_assignments (garden_id, gardener_id, is_active, valid_from) VALUES
  (g_hortensia, carlos_gp, true, '2026-01-15'),
  (g_canroca, carlos_gp, true, '2026-02-01'),
  (g_masdemar, carlos_gp, true, '2026-02-10'),
  (g_olivar, maria_gp, true, '2026-03-01'),
  (g_mirador, maria_gp, true, '2026-03-15');

-- =============================================================
-- 7. VISITS
-- =============================================================

INSERT INTO public.visits (id, garden_id, gardener_id, status, verification_status, initiation_method, title, description, public_comment, started_at, ended_at) VALUES
  (v1, g_hortensia, carlos_gp, 'CLOSED', 'VERIFIED', 'QR_SCAN',
   'Poda y limpieza',
   'Poda de arbustos ornamentales del camino principal. Limpieza de residuos estacionales de los parterres perennes.',
   'Poda completada y limpieza de zona de paso.',
   '2026-04-08 07:12:00+00', '2026-04-08 08:49:00+00'),

  (v2, g_canroca, carlos_gp, 'CLOSED', 'VERIFIED', 'MANUAL',
   'Corte de césped',
   'Mantenimiento estándar del césped. Bordes recortados y fertilización aplicada en el sector norte.',
   'Mantenimiento general del césped y bordes.',
   '2026-04-02 06:30:00+00', '2026-04-02 08:15:00+00'),

  (v3, g_masdemar, carlos_gp, 'CLOSED', 'NOT_VERIFIED', 'MANUAL',
   'Revisión de riego',
   'Verificación de todos los aspersores para presión y radio correcto. Reemplazo de una válvula dañada en la zona 3.',
   'Revisión de riego y sustitución de válvula.',
   '2026-03-26 09:04:00+00', '2026-03-26 10:02:00+00'),

  (v4, g_olivar, maria_gp, 'CLOSED', 'VERIFIED', 'QR_SCAN',
   'Tratamiento de olivos',
   'Aplicación de tratamiento preventivo contra mosca del olivo en los 12 ejemplares. Poda de ramas bajas para facilitar acceso.',
   'Tratamiento preventivo aplicado a los 12 olivos.',
   '2026-04-05 08:00:00+00', '2026-04-05 10:30:00+00'),

  (v5, g_mirador, maria_gp, 'CLOSED', 'VERIFIED', 'QR_SCAN',
   'Plantación de temporada',
   'Plantación de flores de primavera en los parterres del jardín delantero: geranios, petunias y lavanda.',
   'Plantación completada. Regar abundantemente los primeros 3 días.',
   '2026-04-07 06:00:00+00', '2026-04-07 09:15:00+00');

-- =============================================================
-- 8. VISIT PHOTOS
-- =============================================================

INSERT INTO public.visit_photos (visit_id, storage_path, thumbnail_path, label) VALUES
  (v1, 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800', '', 'PODA'),
  (v1, 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=800', '', 'ROSALES'),
  (v1, 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800', '', 'ABONO'),
  (v2, 'https://images.unsplash.com/photo-1592150621744-aca64f48394a?w=800', '', 'CÉSPED'),
  (v3, 'https://images.unsplash.com/photo-1563514227147-6d2ff665a6a0?w=800', '', 'RIEGO'),
  (v4, 'https://images.unsplash.com/photo-1534710961216-75c88202f43e?w=800', '', 'OLIVOS'),
  (v4, 'https://images.unsplash.com/photo-1509587584298-0f3b3a3a1797?w=800', '', 'TRATAMIENTO'),
  (v5, 'https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?w=800', '', 'GERANIOS'),
  (v5, 'https://images.unsplash.com/photo-1490750967868-88aa4f44baee?w=800', '', 'LAVANDA');

-- =============================================================
-- 9. CONVERSATIONS
-- =============================================================

INSERT INTO public.conversations (id, gardener_id, client_id, garden_id, status, last_message_at, unread_message_count) VALUES
  (conv1, carlos_gp, ana_cp, g_hortensia, 'ACTIVE', '2026-04-08 12:30:00+00', 2),
  (conv2, carlos_gp, pedro_cp, g_masdemar, 'ACTIVE', '2026-04-06 08:15:00+00', 0),
  (conv3, maria_gp, laura_cp, g_mirador, 'ACTIVE', '2026-04-07 14:00:00+00', 1);

-- =============================================================
-- 10. MESSAGES
-- =============================================================

-- Conv 1: Carlos <-> Ana (Villa Hortensia) — presupuesto riego + abono
INSERT INTO public.messages (conversation_id, sender_id, recipient_id, sender_role, content_type, content, requires_response, is_read, created_at) VALUES
  (conv1, carlos_id, ana_id, 'GARDENER', 'TEXT',
   'Buenos días Ana. He completado la poda de los arbustos del camino principal. Todo en buen estado.',
   false, true, '2026-04-08 09:00:00+00'),
  (conv1, ana_id, carlos_id, 'CLIENT', 'TEXT',
   'Perfecto Carlos, gracias! He visto las fotos, muy buen trabajo.',
   false, true, '2026-04-08 10:15:00+00'),
  (conv1, carlos_id, ana_id, 'GARDENER', 'TEXT',
   'He detectado que el sistema de riego de la zona este necesita revisión. Presupuesto: 85€ por cambio de 2 electroválvulas. ¿Le parece bien?',
   true, false, '2026-04-08 12:00:00+00'),
  (conv1, carlos_id, ana_id, 'GARDENER', 'TEXT',
   'También recomendaría añadir abono orgánico en los rosales la próxima visita. Coste adicional: 25€.',
   true, false, '2026-04-08 12:30:00+00');

-- Conv 2: Carlos <-> Pedro (Mas de Mar) — seguimiento válvula
INSERT INTO public.messages (conversation_id, sender_id, recipient_id, sender_role, content_type, content, requires_response, is_read, created_at) VALUES
  (conv2, carlos_id, pedro_id, 'GARDENER', 'TEXT',
   'Hola Pedro. He cambiado la válvula de la zona 3 del riego. Ahora funciona correctamente.',
   false, true, '2026-03-26 11:00:00+00'),
  (conv2, pedro_id, carlos_id, 'CLIENT', 'TEXT',
   'Gracias Carlos. ¿Cuándo sería la próxima visita programada?',
   false, true, '2026-03-27 07:00:00+00'),
  (conv2, carlos_id, pedro_id, 'GARDENER', 'TEXT',
   'La tengo prevista para el 15 de abril. ¿Le va bien por la mañana?',
   false, true, '2026-04-06 08:15:00+00');

-- Conv 3: María <-> Laura (El Mirador) — presupuesto seto de boj
INSERT INTO public.messages (conversation_id, sender_id, recipient_id, sender_role, content_type, content, requires_response, is_read, created_at) VALUES
  (conv3, maria_id, laura_id, 'GARDENER', 'TEXT',
   'Hola Laura! He plantado los geranios, petunias y lavanda como acordamos. Recuerde regar abundantemente los primeros 3 días.',
   false, true, '2026-04-07 09:30:00+00'),
  (conv3, laura_id, maria_id, 'CLIENT', 'TEXT',
   'Genial María! Me encanta cómo ha quedado. ¿Sería posible añadir un seto de boj en la entrada?',
   false, true, '2026-04-07 12:00:00+00'),
  (conv3, maria_id, laura_id, 'GARDENER', 'TEXT',
   'Claro! Le preparo presupuesto: 6 metros lineales de boj → 320€ (plantas + mano de obra + sustrato). ¿Le interesa?',
   true, false, '2026-04-07 14:00:00+00');

RAISE NOTICE '✅ Seed data created successfully!';
RAISE NOTICE 'Users created (all with password Test1234!):';
RAISE NOTICE '  admin@gapp.es     (ADMIN)';
RAISE NOTICE '  carlos@gapp.es    (GARDENER) → Villa Hortensia, Can Roca, Mas de Mar';
RAISE NOTICE '  maria@gapp.es     (GARDENER) → El Olivar, El Mirador';
RAISE NOTICE '  ana@cliente.es    (CLIENT)   → Villa Hortensia, Can Roca';
RAISE NOTICE '  pedro@cliente.es  (CLIENT)   → Mas de Mar, El Olivar';
RAISE NOTICE '  laura@cliente.es  (CLIENT)   → El Mirador';

END $$;
