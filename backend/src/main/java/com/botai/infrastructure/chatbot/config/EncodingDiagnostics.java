package com.botai.infrastructure.chatbot.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;

/**
 * Una sola línea al arranque para verificar encoding del JVM (útil en Windows si aparece mojibake en logs o en texto del LLM).
 */
@Component
public class EncodingDiagnostics implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(EncodingDiagnostics.class);

    @Override
    public void run(ApplicationArguments args) {
        log.info(
            "[ENCODING] defaultCharset={}, file.encoding={}, sun.jnu.encoding={}, sun.stdout.encoding={}, sun.stderr.encoding={}",
            Charset.defaultCharset(),
            System.getProperty("file.encoding"),
            System.getProperty("sun.jnu.encoding"),
            System.getProperty("sun.stdout.encoding"),
            System.getProperty("sun.stderr.encoding"));
        if (!StandardCharsets.UTF_8.equals(Charset.defaultCharset())) {
            log.warn(
                "[ENCODING] El charset por defecto no es UTF-8. Anade -Dfile.encoding=UTF-8 al JVM (IDE o java -jar).");
        }
        String jnu = System.getProperty("sun.jnu.encoding");
        if (jnu != null && !"UTF-8".equalsIgnoreCase(jnu) && !"UTF8".equalsIgnoreCase(jnu)) {
            log.warn(
                "[ENCODING] sun.jnu.encoding={} (rutas nativas en Windows suelen ser Cp1252). Opcional: -Dsun.jnu.encoding=UTF-8 junto con file.encoding; en consola: chcp 65001.",
                jnu);
        }
    }
}
