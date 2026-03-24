package com.botai.chatbot.infrastructure.config;

import com.botai.chatbot.application.dto.ToolInputs;
import com.botai.chatbot.infrastructure.ai.AgendarTools;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Description;

import java.util.function.Function;

/**
 * Expone los métodos de AgendarTools como Function beans para que ChatClient
 * los registre como tools en el llamado final (3.º del flujo: guardrail → clasificador → modelo con tools).
 */
@Configuration
public class AiToolsConfig {

    @Bean
    @Description("Obtener las horas disponibles para agendar en una fecha. Fecha en formato YYYY-MM-DD (ej: 2025-03-25). Usar cuando el usuario pregunte por horarios disponibles, quiera agendar o elegir hora.")
    public Function<ToolInputs.GetSlotsDisponiblesInput, String> getSlotsDisponibles(AgendarTools agendarTools) {
        return input -> agendarTools.getSlotsDisponibles(input != null && input.fecha() != null ? input.fecha() : "");
    }

    @Bean
    @Description("Agendar una cita en BD. Obligatorio: servicio, fecha YYYY-MM-DD, hora HH:mm, nombre completo y cédula que el cliente escribió en el chat (puedes tomarlos de mensajes anteriores del historial). No llames si falta nombre o cédula: pregunta antes.")
    public Function<ToolInputs.AgendarCitaInput, String> agendarCita(AgendarTools agendarTools) {
        return input -> {
            if (input == null) {
                return "Faltan datos obligatorios: servicio, fecha, hora y nombre.";
            }
            return agendarTools.agendarCita(
                nullToEmpty(input.servicio()),
                nullToEmpty(input.fecha()),
                nullToEmpty(input.hora()),
                nullToEmpty(input.nombreCliente()),
                input.documento() != null ? input.documento() : ""
            );
        };
    }

    private static String nullToEmpty(String s) {
        return s != null ? s : "";
    }
}
