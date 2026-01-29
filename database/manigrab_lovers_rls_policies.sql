-- Políticas RLS para permitir que los administradores gestionen suscripciones ManiGrabLovers
-- Ejecutar este script en el SQL Editor de Supabase

-- =================================================================
-- POLÍTICAS PARA ADMINISTRADORES EN user_subscriptions
-- =================================================================

-- Política: Los administradores pueden ver todas las suscripciones
CREATE POLICY "Admins can view all subscriptions"
  ON user_subscriptions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users_admin
      WHERE user_id = auth.uid()
    )
  );

-- Política: Los administradores pueden insertar suscripciones para cualquier usuario
CREATE POLICY "Admins can insert subscriptions for any user"
  ON user_subscriptions
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users_admin
      WHERE user_id = auth.uid()
    )
  );

-- Política: Los administradores pueden actualizar suscripciones de cualquier usuario
CREATE POLICY "Admins can update subscriptions for any user"
  ON user_subscriptions
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users_admin
      WHERE user_id = auth.uid()
    )
  );

-- Política: Los administradores pueden eliminar suscripciones de cualquier usuario
CREATE POLICY "Admins can delete subscriptions for any user"
  ON user_subscriptions
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.users_admin
      WHERE user_id = auth.uid()
    )
  );

-- =================================================================
-- COMENTARIOS Y DOCUMENTACIÓN
-- =================================================================

COMMENT ON POLICY "Admins can view all subscriptions" ON user_subscriptions IS 
'Permite a los administradores ver todas las suscripciones de usuarios';

COMMENT ON POLICY "Admins can insert subscriptions for any user" ON user_subscriptions IS 
'Permite a los administradores crear suscripciones ManiGrabLovers para cualquier usuario';

COMMENT ON POLICY "Admins can update subscriptions for any user" ON user_subscriptions IS 
'Permite a los administradores actualizar (activar/desactivar) suscripciones de cualquier usuario';

COMMENT ON POLICY "Admins can delete subscriptions for any user" ON user_subscriptions IS 
'Permite a los administradores eliminar suscripciones de cualquier usuario';
