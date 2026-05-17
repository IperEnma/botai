package com.botai.infrastructure.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Normaliza {@code DATABASE_URL} de Neon/Render/Heroku para Spring + Hikari:
 * <ul>
 *   <li>Antepone {@code jdbc:} si falta.</li>
 *   <li>Separa usuario/contraseña en {@code spring.datasource.username/password}
 *       (Hikari falla si van embebidos en la URL).</li>
 *   <li>Quita {@code channel_binding} del query string (el driver JDBC no lo acepta en la URL).</li>
 * </ul>
 */
public class DatabaseUrlEnvironmentPostProcessor implements EnvironmentPostProcessor {

    static final String ENV_DATABASE_URL = "DATABASE_URL";
    static final String PROP_SPRING_DATASOURCE_URL = "spring.datasource.url";
    static final String PROP_SPRING_DATASOURCE_USERNAME = "spring.datasource.username";
    static final String PROP_SPRING_DATASOURCE_PASSWORD = "spring.datasource.password";

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        String raw = environment.getProperty(ENV_DATABASE_URL);
        if (raw == null || raw.isBlank()) {
            return;
        }
        Normalized normalized = normalize(raw.trim());
        Map<String, Object> props = new LinkedHashMap<>();
        props.put(ENV_DATABASE_URL, normalized.jdbcUrl());
        props.put(PROP_SPRING_DATASOURCE_URL, normalized.jdbcUrl());
        if (normalized.username() != null) {
            props.put(PROP_SPRING_DATASOURCE_USERNAME, normalized.username());
            props.put(PROP_SPRING_DATASOURCE_PASSWORD, normalized.password() != null ? normalized.password() : "");
        }
        environment.getPropertySources().addFirst(new MapPropertySource("normalizedDatabaseUrl", props));
    }

    /**
     * @param username null si la URL no trae credenciales embebidas (user:pass@host)
     */
    record Normalized(String jdbcUrl, String username, String password) {}

    static Normalized normalize(String url) {
        String withoutJdbc = stripJdbcPrefix(url);
        if (!withoutJdbc.startsWith("postgresql://") && !withoutJdbc.startsWith("postgres://")) {
            return new Normalized(url, null, null);
        }

        String remainder = withoutJdbc.replaceFirst("^postgres(ql)?://", "");
        int at = remainder.lastIndexOf('@');
        if (at < 0) {
            return new Normalized(withJdbcPrefix(withoutJdbc), null, null);
        }

        String userInfo = remainder.substring(0, at);
        String hostPart = remainder.substring(at + 1);

        int colon = userInfo.indexOf(':');
        if (colon < 0) {
            return new Normalized(withJdbcPrefix(withoutJdbc), null, null);
        }

        String username = decodeComponent(userInfo.substring(0, colon));
        String password = decodeComponent(userInfo.substring(colon + 1));

        HostAndDatabase hostDb = parseHostPart(hostPart);
        String jdbcUrl = "jdbc:postgresql://" + hostDb.hostPort() + "/" + hostDb.database()
                + formatQuery(hostDb.queryParams());

        return new Normalized(jdbcUrl, username, password);
    }

    private static String stripJdbcPrefix(String url) {
        if (url.regionMatches(true, 0, "jdbc:", 0, 5)) {
            return url.substring(5);
        }
        return url;
    }

    private static String withJdbcPrefix(String urlWithoutJdbc) {
        return urlWithoutJdbc.startsWith("jdbc:") ? urlWithoutJdbc : "jdbc:" + urlWithoutJdbc;
    }

    private static String decodeComponent(String value) {
        return URLDecoder.decode(value, StandardCharsets.UTF_8);
    }

    private record HostAndDatabase(String hostPort, String database, List<String> queryParams) {}

    private static HostAndDatabase parseHostPart(String hostPart) {
        String pathAndQuery = hostPart;
        int slash = hostPart.indexOf('/');
        String hostPort;
        if (slash >= 0) {
            hostPort = hostPart.substring(0, slash);
            pathAndQuery = hostPart.substring(slash + 1);
        } else {
            hostPort = hostPart;
            pathAndQuery = "";
        }

        int q = pathAndQuery.indexOf('?');
        String database = q >= 0 ? pathAndQuery.substring(0, q) : pathAndQuery;
        String query = q >= 0 ? pathAndQuery.substring(q + 1) : "";

        List<String> params = new ArrayList<>();
        if (!query.isBlank()) {
            for (String pair : query.split("&")) {
                if (pair.isBlank()) {
                    continue;
                }
                String key = pair.contains("=") ? pair.substring(0, pair.indexOf('=')) : pair;
                if (!"channel_binding".equalsIgnoreCase(key)) {
                    params.add(pair);
                }
            }
        }

        if (!hostPort.contains(":")) {
            hostPort = hostPort + ":5432";
        }

        return new HostAndDatabase(hostPort, database.isEmpty() ? "postgres" : database, params);
    }

    private static String formatQuery(List<String> params) {
        if (params.isEmpty()) {
            return "";
        }
        return "?" + params.stream().collect(Collectors.joining("&"));
    }
}
