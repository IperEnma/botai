package com.botai.agenda.infrastructure.config;

import com.botai.agenda.domain.context.AgendaTenantContext;
import com.botai.agenda.domain.feature.AgendaFeatureFlagService;
import com.botai.agenda.domain.feature.AgendaFeatures;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

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
    private AgendaFeatureGuard guard;

    @BeforeEach
    void setUp() {
        flagService = mock(AgendaFeatureFlagService.class);
        guard = new AgendaFeatureGuard(flagService);
    }

    @AfterEach
    void tearDown() {
        AgendaTenantContext.clear();
    }

    @Test
    void rutaDeTenantConFlagOnPermitePasar() throws Exception {
        HttpServletRequest req = mock(HttpServletRequest.class);
        HttpServletResponse res = mock(HttpServletResponse.class);
        when(req.getRequestURI()).thenReturn("/api/agenda/tenants/tenant-1/businesses");
        when(flagService.isEnabled(AgendaFeatures.AGENDA_ENABLED, "tenant-1")).thenReturn(true);

        assertTrue(guard.preHandle(req, res, new Object()));
        verify(res, never()).sendError(any(Integer.class));
    }

    @Test
    void rutaDeTenantConFlagOffResponde404() throws Exception {
        HttpServletRequest req = mock(HttpServletRequest.class);
        HttpServletResponse res = mock(HttpServletResponse.class);
        when(req.getRequestURI()).thenReturn("/api/agenda/tenants/tenant-1/businesses");
        when(flagService.isEnabled(AgendaFeatures.AGENDA_ENABLED, "tenant-1")).thenReturn(false);

        assertFalse(guard.preHandle(req, res, new Object()));
        verify(res).sendError(HttpServletResponse.SC_NOT_FOUND);
    }

    @Test
    void rutaMeConTenantIdEnPathYFlagOnPermitePasar() throws Exception {
        HttpServletRequest req = mock(HttpServletRequest.class);
        HttpServletResponse res = mock(HttpServletResponse.class);
        when(req.getRequestURI()).thenReturn("/api/agenda/me/tenants/tenant-2/businesses/some-id/bookings");
        when(flagService.isEnabled(AgendaFeatures.AGENDA_ENABLED, "tenant-2")).thenReturn(true);

        assertTrue(guard.preHandle(req, res, new Object()));
        verify(res, never()).sendError(any(Integer.class));
    }

    @Test
    void rutaMeConTenantIdEnPathYFlagOffResponde404() throws Exception {
        HttpServletRequest req = mock(HttpServletRequest.class);
        HttpServletResponse res = mock(HttpServletResponse.class);
        when(req.getRequestURI()).thenReturn("/api/agenda/me/tenants/tenant-2/businesses/some-id/bookings");
        when(flagService.isEnabled(AgendaFeatures.AGENDA_ENABLED, "tenant-2")).thenReturn(false);

        assertFalse(guard.preHandle(req, res, new Object()));
        verify(res).sendError(HttpServletResponse.SC_NOT_FOUND);
    }

    @Test
    void rutaPublicaNoPasaPorElGuard() throws Exception {
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
