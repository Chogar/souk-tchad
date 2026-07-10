-- Indexes + table paiements (prod, synchronize=false)
-- psql $DATABASE_URL -f backend/src/database/migrations/001_performance_indexes.sql
-- puis ce fichier si besoin

CREATE INDEX IF NOT EXISTS "IDX_listings_status_created"
  ON listings (status, created_at DESC);

CREATE INDEX IF NOT EXISTS "IDX_listings_category_status"
  ON listings (category_id, status);

CREATE INDEX IF NOT EXISTS "IDX_listings_user_status"
  ON listings (user_id, status);

CREATE INDEX IF NOT EXISTS "IDX_messages_conversation_created"
  ON messages (conversation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS "IDX_messages_conversation_read_sender"
  ON messages (conversation_id, read, sender_id);

CREATE INDEX IF NOT EXISTS "IDX_conversations_buyer"
  ON conversations (buyer_id);

CREATE INDEX IF NOT EXISTS "IDX_conversations_seller"
  ON conversations (seller_id);

CREATE INDEX IF NOT EXISTS "IDX_registration_otps_email"
  ON registration_otps (email);

-- Table ordres de paiement (si pas créée par synchronize)
CREATE TABLE IF NOT EXISTS payment_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  plan varchar NOT NULL,
  amount int NOT NULL,
  currency varchar NOT NULL DEFAULT 'XAF',
  status varchar NOT NULL DEFAULT 'PENDING',
  payer_reference varchar NULL,
  provider varchar NOT NULL DEFAULT 'manual_momo',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS "IDX_payment_orders_user_status"
  ON payment_orders (user_id, status);
