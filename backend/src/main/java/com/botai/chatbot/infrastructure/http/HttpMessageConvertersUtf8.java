package com.botai.chatbot.infrastructure.http;

import org.springframework.http.converter.AbstractHttpMessageConverter;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.http.converter.StringHttpMessageConverter;

import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * Aplica UTF-8 a los conversores de texto/JSON de Spring Web (RFC 8259: JSON en UTF-8).
 * Evita que en Windows el charset por defecto del JVM (p. ej. windows-1252) corrompa cuerpos HTTP.
 */
public final class HttpMessageConvertersUtf8 {

    private HttpMessageConvertersUtf8() {}

    public static void applyTo(List<HttpMessageConverter<?>> converters) {
        for (HttpMessageConverter<?> c : converters) {
            if (c instanceof AbstractHttpMessageConverter<?> amc) {
                amc.setDefaultCharset(StandardCharsets.UTF_8);
            }
            if (c instanceof StringHttpMessageConverter smc) {
                smc.setWriteAcceptCharset(false);
            }
        }
    }
}
