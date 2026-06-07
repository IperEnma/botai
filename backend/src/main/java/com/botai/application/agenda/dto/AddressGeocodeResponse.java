package com.botai.application.agenda.dto;

/**
 * Resultado de geocodificar una dirección para mapa público.
 *
 * @param precision {@code EXACT} (número/casa), {@code APPROXIMATE} (calle), {@code AREA} (barrio/ciudad)
 */
public record AddressGeocodeResponse(
        boolean found,
        Double lat,
        Double lon,
        String displayName,
        String precision
) {
    public static AddressGeocodeResponse notFound() {
        return new AddressGeocodeResponse(false, null, null, null, "NONE");
    }
}
