package com.botai.application.agenda.usecase.staff;

import com.botai.application.agenda.dto.CreateStaffMemberRequest;
import com.botai.application.agenda.dto.UpdateStaffMemberRequest;
import com.botai.application.agenda.dto.UpdateStaffServicesRequest;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.StaffMemberNotFoundException;
import com.botai.domain.agenda.model.BusinessHours;
import com.botai.domain.agenda.model.StaffMember;
import com.botai.domain.agenda.repository.BusinessHoursRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.StaffMemberRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

@org.springframework.stereotype.Service
public class ManageStaffUseCase {

    private final BusinessRepository businessRepository;
    private final StaffMemberRepository staffMemberRepository;
    private final BusinessHoursRepository businessHoursRepository;
    private final ObjectMapper objectMapper;

    public ManageStaffUseCase(BusinessRepository businessRepository,
                               StaffMemberRepository staffMemberRepository,
                               BusinessHoursRepository businessHoursRepository,
                               ObjectMapper objectMapper) {
        this.businessRepository = businessRepository;
        this.staffMemberRepository = staffMemberRepository;
        this.businessHoursRepository = businessHoursRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public List<StaffMember> list(String tenantId, UUID businessId) {
        verifyBusiness(tenantId, businessId);
        return staffMemberRepository.findByBusinessId(businessId);
    }

    @Transactional
    public StaffMember create(String tenantId, UUID businessId, CreateStaffMemberRequest req) {
        verifyBusiness(tenantId, businessId);
        StaffMember sm = StaffMember.builder()
                .businessId(businessId)
                .nombre(req.nombre())
                .rol(req.rol())
                .avatarUrl(req.avatarUrl())
                .telefono(req.telefono())
                .color(req.color())
                .status("ACTIVO")
                .build();
        return staffMemberRepository.save(sm);
    }

    @Transactional
    public StaffMember update(String tenantId, UUID businessId, UUID staffId,
                               UpdateStaffMemberRequest req) {
        verifyBusiness(tenantId, businessId);
        StaffMember existing = staffMemberRepository.findById(staffId)
                .orElseThrow(() -> new StaffMemberNotFoundException(staffId));
        if (!existing.getBusinessId().equals(businessId)) {
            throw new StaffMemberNotFoundException(staffId);
        }
        String customScheduleJson = req.customSchedule() != null
                ? sanitizeSchedule(businessId, req.customSchedule())
                : null;
        StaffMember updated = StaffMember.builder()
                .id(existing.getId())
                .businessId(existing.getBusinessId())
                .nombre(req.nombre())
                .rol(req.rol())
                .avatarUrl(req.avatarUrl())
                .telefono(req.telefono())
                .email(req.email())
                .bio(req.bio())
                .color(req.color())
                .status(req.status())
                .customSchedule(customScheduleJson)
                .serviceIds(existing.getServiceIds())
                .deletedAt(existing.getDeletedAt())
                .createdAt(existing.getCreatedAt())
                .updatedAt(existing.getUpdatedAt())
                .build();
        return staffMemberRepository.save(updated);
    }

    @Transactional
    public StaffMember updateServices(String tenantId, UUID businessId, UUID staffId,
                                      UpdateStaffServicesRequest req) {
        verifyBusiness(tenantId, businessId);
        if (!staffMemberRepository.existsByIdAndBusinessId(staffId, businessId)) {
            throw new StaffMemberNotFoundException(staffId);
        }
        return staffMemberRepository.updateServiceIds(staffId, req.serviceIds());
    }

    @Transactional
    public void deactivate(String tenantId, UUID businessId, UUID staffId) {
        verifyBusiness(tenantId, businessId);
        if (!staffMemberRepository.existsByIdAndBusinessId(staffId, businessId)) {
            throw new StaffMemberNotFoundException(staffId);
        }
        staffMemberRepository.softDelete(staffId);
    }

    private void verifyBusiness(String tenantId, UUID businessId) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));
    }

    private String sanitizeSchedule(UUID businessId, JsonNode schedule) {
        List<BusinessHours> bizHours = businessHoursRepository.findByBusinessId(businessId);
        String[] dayKeys = {"lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo"};
        ObjectNode result = objectMapper.createObjectNode();

        for (int i = 0; i < dayKeys.length; i++) {
            String key = dayKeys[i];
            final int dayIndex = i;
            JsonNode dayNode = schedule.get(key);

            BusinessHours bh = bizHours.stream()
                    .filter(h -> h.getDiaSemana() == dayIndex)
                    .findFirst().orElse(null);

            ObjectNode closed = objectMapper.createObjectNode().put("open", false);

            if (dayNode == null || bh == null || bh.isCerrado()) {
                result.set(key, closed);
                continue;
            }

            boolean staffOpen = dayNode.path("open").asBoolean(false);
            if (!staffOpen) {
                result.set(key, closed);
                continue;
            }

            LocalTime bizApertura = bh.getApertura() != null ? bh.getApertura() : LocalTime.of(0, 0);
            LocalTime bizCierre = bh.getCierre() != null ? bh.getCierre() : LocalTime.of(23, 59);

            String fromStr = dayNode.path("from").asText(null);
            String toStr = dayNode.path("to").asText(null);

            LocalTime from = (fromStr != null && !fromStr.isEmpty()) ? LocalTime.parse(fromStr) : bizApertura;
            LocalTime to = (toStr != null && !toStr.isEmpty()) ? LocalTime.parse(toStr) : bizCierre;

            // Clamp within business hours
            if (from.isBefore(bizApertura)) from = bizApertura;
            if (to.isAfter(bizCierre)) to = bizCierre;

            if (!from.isBefore(to)) {
                result.set(key, closed);
                continue;
            }

            ObjectNode dayResult = objectMapper.createObjectNode();
            dayResult.put("open", true);
            dayResult.put("from", from.toString());
            dayResult.put("to", to.toString());
            result.set(key, dayResult);
        }
        return result.toString();
    }
}
