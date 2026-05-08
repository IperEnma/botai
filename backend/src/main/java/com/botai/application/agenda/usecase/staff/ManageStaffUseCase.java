package com.botai.application.agenda.usecase.staff;

import com.botai.application.agenda.dto.CreateStaffMemberRequest;
import com.botai.application.agenda.dto.UpdateStaffMemberRequest;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.StaffMemberNotFoundException;
import com.botai.domain.agenda.model.StaffMember;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.StaffMemberRepository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@org.springframework.stereotype.Service
public class ManageStaffUseCase {

    private final BusinessRepository businessRepository;
    private final StaffMemberRepository staffMemberRepository;

    public ManageStaffUseCase(BusinessRepository businessRepository,
                               StaffMemberRepository staffMemberRepository) {
        this.businessRepository = businessRepository;
        this.staffMemberRepository = staffMemberRepository;
    }

    @Transactional(readOnly = true)
    public List<StaffMember> list(String tenantId, UUID businessId) {
        verifyBusiness(tenantId, businessId);
        return staffMemberRepository.findByBusinessId(businessId);
    }

    @Transactional
    public StaffMember create(String tenantId, UUID businessId, CreateStaffMemberRequest req) {
        verifyBusiness(tenantId, businessId);
        StaffMember sm = new StaffMember(
                null, businessId, req.nombre(), req.rol(), req.avatarUrl(),
                true, null, null, null);
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
        StaffMember updated = new StaffMember(
                existing.getId(),
                existing.getBusinessId(),
                req.nombre(),
                req.rol(),
                req.avatarUrl(),
                req.activo(),
                existing.getDeletedAt(),
                existing.getCreatedAt(),
                existing.getUpdatedAt()
        );
        return staffMemberRepository.save(updated);
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
}
