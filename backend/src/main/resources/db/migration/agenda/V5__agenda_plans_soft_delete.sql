-- ============================================================================
-- V5__agenda_plans_soft_delete.sql
-- Agrega soft delete a agenda_plans, consistente con agenda_businesses y
-- agenda_services que ya usan deleted_at.
-- ============================================================================
ALTER TABLE agenda_plans
    ADD COLUMN deleted_at TIMESTAMP NULL;

-- Índice para filtrar planes no eliminados en listados.
CREATE INDEX idx_agenda_plans_deleted_at
    ON agenda_plans (business_id, activo)
    WHERE deleted_at IS NULL;
