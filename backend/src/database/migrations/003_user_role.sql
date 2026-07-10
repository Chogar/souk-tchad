-- Ajout du rôle admin
DO $$ BEGIN
  CREATE TYPE users_role_enum AS ENUM ('USER', 'ADMIN');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS role users_role_enum NOT NULL DEFAULT 'USER';

UPDATE users SET role = 'ADMIN' WHERE email = 'admin@souk-tchad.com';
