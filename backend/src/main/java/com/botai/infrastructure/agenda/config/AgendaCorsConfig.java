package com.botai.infrastructure.agenda.config;

import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.Ordered;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * CORS para el módulo AGENDA.
 * - addCorsMappings cubre los controllers (/api/agenda/**).
 * - uploadsCorsFilter cubre los recursos estáticos (/uploads/**) a nivel de
 *   servlet filter, ya que addCorsMappings no aplica a ResourceHttpRequestHandler.
 */
@Configuration
public class AgendaCorsConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/agenda/**")
                .allowedOriginPatterns("*")
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .exposedHeaders("Content-Type", "Authorization", "Idempotency-Key")
                .maxAge(3600);

        registry.addMapping("/uploads/**")
                .allowedOriginPatterns("*")
                .allowedMethods("GET", "OPTIONS")
                .allowedHeaders("*")
                .maxAge(3600);
    }

    @Bean
    public FilterRegistrationBean<CorsFilter> uploadsCorsFilter() {
        CorsConfiguration config = new CorsConfiguration();
        config.addAllowedOriginPattern("*");
        config.addAllowedMethod("GET");
        config.addAllowedMethod("OPTIONS");
        config.addAllowedHeader("*");
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/uploads/**", config);

        FilterRegistrationBean<CorsFilter> bean =
                new FilterRegistrationBean<>(new CorsFilter(source));
        bean.setOrder(Ordered.HIGHEST_PRECEDENCE);
        // /uploads/* cubre rutas anidadas (/uploads/businesses/…/file.jpg).
        bean.addUrlPatterns("/uploads/*");
        return bean;
    }
}
