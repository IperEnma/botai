package com.botai.infrastructure.chatbot.config;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

/**
 * Al arranque, loguea host/puerto/BD que usará la app. Puerto por defecto 5444 (Docker).
 * Usa SLF4J (mismo pipeline que Logback + {@code logging.charset.console}) en lugar de {@link System#out}.
 */
@Component
public class DataSourceLogger {

    private static final Logger log = LoggerFactory.getLogger(DataSourceLogger.class);

    private final Environment env;

    public DataSourceLogger(Environment env) {
        this.env = env;
    }

    @PostConstruct
    public void logConnectionInfo() {
        String host = env.getProperty("BOTAI_DB_HOST", "127.0.0.1");
        String port = env.getProperty("BOTAI_DB_PORT", "5444");
        String db = env.getProperty("BOTAI_DB_NAME", "chatbot");
        log.info("[chatbot-engine] Conexion BD: {}:{}/{}", host, port, db);
    }
}
