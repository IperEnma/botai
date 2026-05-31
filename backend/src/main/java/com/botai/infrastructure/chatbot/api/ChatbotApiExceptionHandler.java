package com.botai.infrastructure.chatbot.api;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

@RestControllerAdvice(basePackageClasses = AdminController.class)
public class ChatbotApiExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(ChatbotApiExceptionHandler.class);

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Map<String, String>> handleDataIntegrity(DataIntegrityViolationException ex) {
        String detail = ex.getMostSpecificCause() != null
                ? String.valueOf(ex.getMostSpecificCause().getMessage())
                : ex.getMessage();
        log.warn("[BOT-API] DataIntegrityViolation: {}", detail);

        if (detail != null && detail.toLowerCase().contains("too long")) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                    "code", "SCHEMA_MISMATCH",
                    "message",
                    "La base de datos no coincide con el schema del código. "
                            + "Recreá la instancia Postgres desde cero (greenfield) y volvé a configurar el bot."
            ));
        }

        return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                "code", "DATA_INTEGRITY",
                "message", "No se pudo guardar: conflicto con la base de datos."
        ));
    }
}
