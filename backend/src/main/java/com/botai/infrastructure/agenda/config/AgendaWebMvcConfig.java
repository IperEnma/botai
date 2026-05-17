package com.botai.infrastructure.agenda.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Registro del {@link AgendaFeatureGuard} como interceptor de MVC sobre las
 * rutas sensibles de AGENDA (tenant y usuario final).
 */
@Configuration
public class AgendaWebMvcConfig implements WebMvcConfigurer {

    private final AgendaFeatureGuard agendaFeatureGuard;
    private final AgendaRateLimitInterceptor rateLimitInterceptor;
    private final AgendaUploadProperties uploadProperties;

    public AgendaWebMvcConfig(AgendaFeatureGuard agendaFeatureGuard,
                               AgendaRateLimitInterceptor rateLimitInterceptor,
                               AgendaUploadProperties uploadProperties) {
        this.agendaFeatureGuard = agendaFeatureGuard;
        this.rateLimitInterceptor = rateLimitInterceptor;
        this.uploadProperties = uploadProperties;
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String uploadDir = uploadProperties.getDir();
        String uploadPath = uploadDir.endsWith("/") ? uploadDir : uploadDir + "/";
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:" + uploadPath);
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(agendaFeatureGuard)
                .addPathPatterns("/api/agenda/me/**")
                .excludePathPatterns("/api/agenda/me/tenant-admin", "/api/agenda/me/tenant-admin/**");

        registry.addInterceptor(rateLimitInterceptor)
                .addPathPatterns("/api/agenda/public/search");
    }
}
