-- Flujo real: sin datos de prueba ni tenant por defecto.
-- Las tablas se rellenan al crear bots y configurar menús, triggers, FAQ y knowledge desde la app.
-- Opcional: TRUNCATE para limpiar al reconstruir (descomenta si quieres resetear).
-- TRUNCATE feature_config, faq, menu, menu_trigger, knowledge_chunk RESTART IDENTITY CASCADE;
SELECT 1;
