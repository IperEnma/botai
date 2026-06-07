package com.botai.infrastructure.agenda.support;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Optional;

/**
 * Miniatura estática OSM para el perfil público (geocode + imagen vía servidor).
 * Evita CORS del navegador y respeta la política de uso de Nominatim.
 */
@Service
public class OpenStreetMapPreviewService {

    private static final String USER_AGENT = "BotaiAgenda/1.0 (public map preview; contact@konecta.app)";
    private static final Duration TIMEOUT = Duration.ofSeconds(8);

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(TIMEOUT)
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public Optional<byte[]> fetchPreviewPng(String address, int pixelSize) {
        if (address == null || address.isBlank()) {
            return Optional.empty();
        }
        int size = Math.max(64, Math.min(512, pixelSize));
        return geocode(address.trim())
                .flatMap(coords -> fetchStaticMapPng(coords.lat(), coords.lon(), size));
    }

    private Optional<Coords> geocode(String address) {
        for (String query : geocodeQueries(address)) {
            Optional<Coords> found = geocodeOnce(query);
            if (found.isPresent()) {
                return found;
            }
        }
        return Optional.empty();
    }

    private static String[] geocodeQueries(String address) {
        if (address.contains("Uruguay")) {
            return new String[]{address};
        }
        return new String[]{address, address + ", Uruguay"};
    }

    private Optional<Coords> geocodeOnce(String query) {
        try {
            String q = URLEncoder.encode(query, StandardCharsets.UTF_8);
            URI uri = URI.create(
                    "https://nominatim.openstreetmap.org/search?q=" + q + "&format=json&limit=1");
            HttpRequest request = HttpRequest.newBuilder(uri)
                    .timeout(TIMEOUT)
                    .header("User-Agent", USER_AGENT)
                    .header("Accept", "application/json")
                    .GET()
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200 || response.body() == null || response.body().isBlank()) {
                return Optional.empty();
            }
            JsonNode list = objectMapper.readTree(response.body());
            if (!list.isArray() || list.isEmpty()) {
                return Optional.empty();
            }
            JsonNode item = list.get(0);
            double lat = parseDouble(item.get("lat"));
            double lon = parseDouble(item.get("lon"));
            if (Double.isNaN(lat) || Double.isNaN(lon)) {
                return Optional.empty();
            }
            return Optional.of(new Coords(lat, lon));
        } catch (Exception ex) {
            return Optional.empty();
        }
    }

    private Optional<byte[]> fetchStaticMapPng(double lat, double lon, int size) {
        try {
            String center = lat + "," + lon;
            String url = "https://staticmap.openstreetmap.de/staticmap"
                    + "?center=" + center
                    + "&zoom=15"
                    + "&size=" + size + "x" + size
                    + "&markers=" + center + ",lightblue1";
            HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                    .timeout(TIMEOUT)
                    .header("User-Agent", USER_AGENT)
                    .GET()
                    .build();
            HttpResponse<byte[]> response = httpClient.send(request, HttpResponse.BodyHandlers.ofByteArray());
            if (response.statusCode() != 200 || response.body() == null || response.body().length == 0) {
                return Optional.empty();
            }
            return Optional.of(response.body());
        } catch (Exception ex) {
            return Optional.empty();
        }
    }

    private static double parseDouble(JsonNode node) {
        if (node == null || node.isNull()) {
            return Double.NaN;
        }
        try {
            return Double.parseDouble(node.asText());
        } catch (NumberFormatException ex) {
            return Double.NaN;
        }
    }

    private record Coords(double lat, double lon) {
    }
}
