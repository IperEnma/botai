package com.botai.application.chatbot.dto;

/**
 * POJOs para que Spring AI deserialice los argumentos de las tool calls del modelo.
 * Los nombres de los campos deben coincidir con los que envía el LLM.
 */
public final class ToolInputs {

    /** Entrada para getSlotsDisponibles(fecha). Fecha en YYYY-MM-DD. */
    public record GetSlotsDisponiblesInput(String fecha) {}

    /** Entrada para agendarCita(servicio, fecha, hora, nombreCliente, documento). */
    public record AgendarCitaInput(String servicio, String fecha, String hora, String nombreCliente, String documento) {}

    private ToolInputs() {}
}
