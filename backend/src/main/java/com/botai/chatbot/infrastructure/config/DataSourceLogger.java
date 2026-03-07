package com.botai.chatbot.infrastructure.config;

import jakarta.annotation.PostConstruct;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

/**
 * Al arranque, loguea host/puerto/BD que usará la app. Puerto por defecto 5444 (Docker).
 */
@Component
public class DataSourceLogger {

    private final Environment env;

    public DataSourceLogger(Environment env) {
        this.env = env;
    }

    @PostConstruct
    public void logConnectionInfo() {
        String host = env.getProperty("BOTAI_DB_HOST", "127.0.0.1");
        String port = env.getProperty("BOTAI_DB_PORT", "5444");
        String db = env.getProperty("BOTAI_DB_NAME", "chatbot");
        System.out.println("[chatbot-engine] Conexión BD: " + host + ":" + port + "/" + db);
    }
}
