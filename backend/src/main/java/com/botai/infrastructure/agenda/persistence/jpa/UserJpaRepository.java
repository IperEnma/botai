package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.UserEntity;
import com.botai.infrastructure.agenda.persistence.projection.ClientStatsRow;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserJpaRepository extends JpaRepository<UserEntity, UUID> {

    Optional<UserEntity> findByTenantIdAndEmail(String tenantId, String email);

    /**
     * Resuelve un usuario por email global (sin scope de tenant). Útil para el
     * {@code AgendaPrincipalLoader} cuando el JWT no matchea ningún
     * {@code TenantAccount} pero sí un User invitado.
     *
     * <p>Si por desconfiguración hay dos Users con el mismo email en distintos
     * tenants, {@link #findFirstByEmailOrderByCreatedAtAsc} devuelve el más
     * antiguo — la validación de invitación previene esto en alta normal.</p>
     */
    Optional<UserEntity> findFirstByEmailOrderByCreatedAtAsc(String email);

    @Query("SELECT u FROM UserEntity u WHERE u.tenantId = :tenantId AND u.tipoUsuario = 'CLIENT' " +
           "AND (:q = '' OR LOWER(u.nombre) LIKE LOWER(CONCAT('%', :q, '%')) OR u.telefono LIKE CONCAT('%', :q, '%')) " +
           "ORDER BY u.nombre ASC")
    List<UserEntity> searchClients(@Param("tenantId") String tenantId, @Param("q") String q);

    @Query("SELECT u FROM UserEntity u WHERE u.tenantId = :tenantId AND u.tipoUsuario = 'CLIENT' " +
           "AND u.activo = true AND u.telefono IS NOT NULL AND u.telefono <> ''")
    List<UserEntity> findActiveClientsWithTelefono(@Param("tenantId") String tenantId);

    @Query("""
            SELECT new com.botai.infrastructure.agenda.persistence.projection.ClientStatsRow(
                u.id, u.nombre, u.email, u.telefono, u.createdAt,
                SUM(CASE WHEN b.estado = com.botai.domain.agenda.model.BookingEstado.COMPLETED THEN 1L ELSE 0L END),
                SUM(CASE WHEN b.estado = com.botai.domain.agenda.model.BookingEstado.NO_SHOW   THEN 1L ELSE 0L END),
                MAX(CASE WHEN b.estado = com.botai.domain.agenda.model.BookingEstado.COMPLETED THEN b.fechaHoraInicio ELSE NULL END),
                COALESCE(SUM(CASE WHEN b.estado = com.botai.domain.agenda.model.BookingEstado.COMPLETED THEN COALESCE(s.precio, 0) ELSE 0 END), 0)
            )
            FROM UserEntity u
            LEFT JOIN BookingEntity b ON b.userId = u.id
            LEFT JOIN AgendaService  s ON s.id = b.serviceId
            WHERE u.tenantId = :tenantId AND u.tipoUsuario = 'CLIENT'
              AND (:q = '' OR LOWER(u.nombre) LIKE LOWER(CONCAT('%', :q, '%')) OR u.telefono LIKE CONCAT('%', :q, '%'))
            GROUP BY u.id, u.nombre, u.email, u.telefono, u.createdAt
            ORDER BY u.nombre ASC
            """)
    List<ClientStatsRow> searchClientsWithStats(@Param("tenantId") String tenantId, @Param("q") String q);
}
