package com.botai.infrastructure.agenda.config;

import com.botai.infrastructure.common.context.ThreadTenantContext;
import com.botai.domain.agenda.feature.AgendaFeatureFlagService;
import com.botai.domain.agenda.feature.AgendaFeatures;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
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
        ThreadTenantContext.clear();
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
        ThreadTenantContext.setTenantId("tenant-x");
        HttpServletRequest req = mock(HttpServletRequest.class);
        HttpServletResponse res = mock(HttpServletResponse.class);

        guard.afterCompletion(req, res, new Object(), null);

        assertTrue(ThreadTenantContext.getTenantId() == null,
                "afterCompletion debe limpiar el ThreadLocal");
    }
}
