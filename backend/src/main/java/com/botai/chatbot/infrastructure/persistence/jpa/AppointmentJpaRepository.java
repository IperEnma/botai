package com.botai.chatbot.infrastructure.persistence.jpa;

import com.botai.chatbot.infrastructure.persistence.entity.AppointmentEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface AppointmentJpaRepository extends JpaRepository<AppointmentEntity, Long> {

    List<AppointmentEntity> findByTenantIdAndAppointmentDateBetweenOrderByAppointmentTimeAsc(
        String tenantId, LocalDate start, LocalDate end);

    List<AppointmentEntity> findByTenantIdAndAppointmentDateOrderByAppointmentTimeAsc(
        String tenantId, LocalDate appointmentDate);

    List<AppointmentEntity> findByTenantIdAndUserIdOrderByAppointmentDateAscAppointmentTimeAsc(
        String tenantId, String userId);
}
