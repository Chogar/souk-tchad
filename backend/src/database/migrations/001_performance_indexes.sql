-- Indexes production (à appliquer si synchronize=false)
-- Usage: psql $DATABASE_URL -f backend/src/database/migrations/001_performance_indexes.sql

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
