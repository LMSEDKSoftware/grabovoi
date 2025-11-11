-- Esquema de base de datos para suscripciones de usuarios
-- Ejecutar este SQL en Supabase SQL Editor

-- Tabla para almacenar suscripciones de usuarios
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL, -- 'subscription_monthly' o 'subscription_yearly'
  purchase_id TEXT, -- ID de la compra de Google Play
  transaction_date TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_is_active ON user_subscriptions(is_active);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_expires_at ON user_subscriptions(expires_at);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at
CREATE TRIGGER update_user_subscriptions_updated_at
  BEFORE UPDATE ON user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Política RLS: Los usuarios solo pueden ver sus propias suscripciones
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own subscriptions"
  ON user_subscriptions
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own subscriptions"
  ON user_subscriptions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own subscriptions"
  ON user_subscriptions
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Comentarios para documentación
COMMENT ON TABLE user_subscriptions IS 'Almacena las suscripciones activas y expiradas de los usuarios';
COMMENT ON COLUMN user_subscriptions.product_id IS 'ID del producto: subscription_monthly o subscription_yearly';
COMMENT ON COLUMN user_subscriptions.purchase_id IS 'ID único de la compra de Google Play Billing';
COMMENT ON COLUMN user_subscriptions.expires_at IS 'Fecha de expiración de la suscripción';

