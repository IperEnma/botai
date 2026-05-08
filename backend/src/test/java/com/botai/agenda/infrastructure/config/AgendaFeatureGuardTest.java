package com.botai.agenda.infrastructure.config;

import com.botai.agenda.domain.context.AgendaTenantContext;
import com.botai.agenda.domain.feature.AgendaFeatureFlagService;
import com.botai.agenda.domain.feature.AgendaFeatures;
import com.botai.agenda.infrastructure.security.AgendaCurrentTenantService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AgendaFeatureGuardTest {

    private AgendaFeatureFlagService flagService;
    private AgendaCurrentTenantService currentTenant;
    private AgendaFeatureGuard guard;

    @BeforeEach
    void setUp() {
        flagService = mock(AgendaFeatureFlagService.class);
        currentTenant = mock(AgendaCurrentTenantService.class);
        guard = new AgendaFeatureGuard(flagService, currentTenant);
    }

    @AfterEach
    void tearDown() {
        AgendaTenantContext.clear();
    }

    @Test
    void rutaMeConTenantYFlagOnPermitePasar() throws Exception {
        HttpServletRequest req = mock(HttpServletRequest.class);
        HttpServletResponse res = mock(HttpServletResponse.class);
        when(req.getRequestURI()).thenReturn("/api/agenda/me/businesses");
        when(currentTenant.findTenantId()).thenReturn(Optional.of("tenant-1"));
        when(flagService.isEnabled(AgendaFeatures.AGENDA_ENABLED, "tenant-1")).thenReturn(true);

        assertTrue(guard.preHandle(req, res, new Object()));
        verify(res, never()).sendError(any(Integer.class));
    }

    @Test
    void rutaMeConTenantYFlagOffResponde404() throws Exception {
        HttpServletRequest req = mock(HttpServletRequest.class);
        HttpServletResponse res = mock(HttpServletResponse.class);
        when(req.getRequestURI()).thenReturn("/api/agenda/me/businesses");
        when(currentTenant.findTenantId()).thenReturn(Optional.of("tenant-1"));
        when(flagService.isEnabled(AgendaFeatures.AGENDA_ENABLED, "tenant-1")).thenReturn(false);

        assertFalse(guard.preHandle(req, res, new Object()));
        verify(res).sendError(HttpServletResponse.SC_NOT_FOUND);
    }

    @Test
    void rutaMeSinTenantTodaviaPermitePasar() throws Exception {
        HttpServletRequest req = mock(HttpServletRequest.class);
        HttpServletResponse res = mock(HttpServletResponse.class);
        when(req.getRequestURI()).thenReturn("/api/agenda/me/tenant-admin");
        when(currentTenant.findTenantId()).thenReturn(Optional.empty());

        assertTrue(guard.preHandle(req, res, new Object()));
        verify(flagService, never()).isEnabled(any(), anyString());
        verify(res, never()).sendError(any(Integer.class));
    }

    @Test
    void rutaNoMeNoPasaPorElGuard() throws Exception {
        HttpServletRequest req = mock(HttpServletRequest.class);
        HttpServletResponse res = mock(HttpServletResponse.class);
        when(req.getRequestURI()).thenReturn("/api/agenda/public/search");

        assertTrue(guard.preHandle(req, res, new Object()));
        verify(flagService, never()).isEnabled(any(), anyString());
        verify(res, never()).sendError(any(Integer.class));
    }

    @Test
    void afterCompletionLimpiaElContexto() throws Exception {
        AgendaTenantContext.setTenantId("tenant-x");
        HttpServletRequest req = mock(HttpServletRequest.class);
        HttpServletResponse res = mock(HttpServletResponse.class);

        guard.afterCompletion(req, res, new Object(), null);

        assertTrue(AgendaTenantContext.getTenantId() == null,
                "afterCompletion debe limpiar el ThreadLocal");
    }
}
