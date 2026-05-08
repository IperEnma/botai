package com.botai.application.chatbot.service.inbound;

import com.botai.application.chatbot.service.conversation.common.MenuService;
import com.botai.domain.chatbot.feature.BotFeatures;
import com.botai.domain.chatbot.feature.FeatureFlagService;
import com.botai.infrastructure.agenda.persistence.entity.BusinessEntity;
import com.botai.infrastructure.agenda.persistence.entity.BusinessHoursEntity;
import com.botai.infrastructure.agenda.persistence.entity.ServiceEntity;
import com.botai.infrastructure.agenda.persistence.jpa.AgendaBusinessHoursJpaRepository;
import com.botai.infrastructure.agenda.persistence.jpa.BusinessJpaRepository;
import com.botai.infrastructure.agenda.persistence.jpa.ServiceJpaRepository;
import com.botai.infrastructure.chatbot.persistence.entity.KnowledgeChunkEntity;
import com.botai.infrastructure.chatbot.persistence.jpa.KnowledgeChunkJpaRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BotReadinessServiceTest {

    private static final String TENANT = "t1";

    @Mock
    private FeatureFlagService featureFlagService;
    @Mock
    private MenuService menuService;
    @Mock
    private BusinessJpaRepository agendaBusinessRepository;
    @Mock
    private AgendaBusinessHoursJpaRepository agendaBusinessHoursRepository;
    @Mock
    private ServiceJpaRepository agendaServiceRepository;
    @Mock
    private KnowledgeChunkJpaRepository knowledgeRepository;

    private BotReadinessService service;

    @BeforeEach
    void setUp() {
        when(featureFlagService.isEnabled(eq(BotFeatures.FAQ_ENABLED), anyString())).thenReturn(false);
        service = new BotReadinessService(
            featureFlagService,
            menuService,
            agendaBusinessRepository,
            agendaBusinessHoursRepository,
            agendaServiceRepository,
            knowledgeRepository);
    }

    @Test
    void aiEnabled_agendaHoursOnly_ready() {
        when(featureFlagService.isEnabled(eq(BotFeatures.AI_ENABLED), eq(TENANT))).thenReturn(true);
        when(knowledgeRepository.findByTenantIdAndActiveTrue(TENANT)).thenReturn(List.of());
        BusinessEntity b = activeBusiness();
        when(agendaBusinessRepository.findAllByTenantIdAndDeletedAtIsNull(TENANT)).thenReturn(List.of(b));
        when(agendaBusinessHoursRepository.findByBusinessId(b.getId())).thenReturn(List.of(new BusinessHoursEntity()));

        assertThat(service.getNotReadyMessage(TENANT)).isNull();
    }

    @Test
    void aiEnabled_agendaServicesOnly_ready() {
        when(featureFlagService.isEnabled(eq(BotFeatures.AI_ENABLED), eq(TENANT))).thenReturn(true);
        when(knowledgeRepository.findByTenantIdAndActiveTrue(TENANT)).thenReturn(List.of());
        BusinessEntity b = activeBusiness();
        when(agendaBusinessRepository.findAllByTenantIdAndDeletedAtIsNull(TENANT)).thenReturn(List.of(b));
        when(agendaBusinessHoursRepository.findByBusinessId(b.getId())).thenReturn(List.of());
        when(agendaServiceRepository.findAllByBusinessIdAndActivoTrueAndDeletedAtIsNull(b.getId()))
            .thenReturn(List.of(new ServiceEntity()));

        assertThat(service.getNotReadyMessage(TENANT)).isNull();
    }

    @Test
    void aiEnabled_knowledgeOnly_ready() {
        when(featureFlagService.isEnabled(eq(BotFeatures.AI_ENABLED), eq(TENANT))).thenReturn(true);
        when(knowledgeRepository.findByTenantIdAndActiveTrue(TENANT))
            .thenReturn(List.of(new KnowledgeChunkEntity()));

        assertThat(service.getNotReadyMessage(TENANT)).isNull();
        verifyNoInteractions(agendaBusinessRepository);
    }

    @Test
    void aiEnabled_emptyAgendaAndNoKnowledge_notReady() {
        when(featureFlagService.isEnabled(eq(BotFeatures.AI_ENABLED), eq(TENANT))).thenReturn(true);
        when(knowledgeRepository.findByTenantIdAndActiveTrue(TENANT)).thenReturn(List.of());
        when(agendaBusinessRepository.findAllByTenantIdAndDeletedAtIsNull(TENANT)).thenReturn(List.of());

        assertThat(service.getNotReadyMessage(TENANT)).isNotNull();
    }

    private static BusinessEntity activeBusiness() {
        BusinessEntity b = new BusinessEntity();
        b.setId(UUID.randomUUID());
        b.setActivo(true);
        return b;
    }
}
