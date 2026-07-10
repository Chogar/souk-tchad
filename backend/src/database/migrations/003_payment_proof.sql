-- Preuve de paiement (capture d'écran) sur payment_orders
-- psql $DATABASE_URL -f backend/src/database/migrations/003_payment_proof.sql

ALTER TABLE payment_orders
  ADD COLUMN IF NOT EXISTS proof_image_url varchar NULL;
