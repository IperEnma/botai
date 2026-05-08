package com.botai.infrastructure.agenda.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

/**
 * Configuración de la caché in-memory de AGENDA usando Caffeine.
 *
 * <p>Caches registradas:
 * <ul>
 *   <li>{@code agenda-search} — resultados del buscador público (TTL configurable).</li>
 *   <li>{@code agenda-categories} — catálogo de categorías activas (TTL configurable).</li>
 * </ul>
 *
 * <p>Ambas se invalidan por expiración (TTL). El TTL se configura vía
 * {@code agenda.search.cache-ttl-seconds} (default 60 s).
 */
@Configuration
@EnableCaching
public class AgendaCacheConfig {

    public static final String CACHE_SEARCH     = "agenda-search";
    public static final String CACHE_CATEGORIES = "agenda-categories";

    @Value("${agenda.search.cache-ttl-seconds:60}")
    private long ttlSeconds;

    @Bean
    public CacheManager agendaCacheManager() {
        CaffeineCacheManager manager = new CaffeineCacheManager(CACHE_SEARCH, CACHE_CATEGORIES);
        manager.setCaffeine(Caffeine.newBuilder()
                .expireAfterWrite(ttlSeconds, TimeUnit.SECONDS)
                .maximumSize(500));
        return manager;
    }
}
