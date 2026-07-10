-- Paramètres paiement admin (numéros Airtel/Moov + alertes e-mail)
-- psql $DATABASE_URL -f backend/src/database/migrations/004_payment_settings.sql

CREATE TABLE IF NOT EXISTS payment_settings (
  id varchar PRIMARY KEY DEFAULT 'default',
  airtel_money_number varchar NULL,
  moov_money_number varchar NULL,
  notification_email varchar NULL,
  notify_on_payment boolean NOT NULL DEFAULT true,
  momo_label varchar NOT NULL DEFAULT 'Souk Tchad',
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO payment_settings (id)
VALUES ('default')
ON CONFLICT (id) DO NOTHING;
