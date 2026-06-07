package com.botai.infrastructure.agenda.support;

import com.botai.application.agenda.dto.AddressGeocodeResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;

/**
 * Miniatura estática OSM para el perfil público (geocode + imagen vía servidor).
 * Evita CORS del navegador y respeta la política de uso de Nominatim.
 */
@Service
public class OpenStreetMapPreviewService {

    private static final String USER_AGENT = "BotaiAgenda/1.0 (public map preview; contact@konecta.app)";
    private static final Duration TIMEOUT = Duration.ofSeconds(8);
    private static final int MAX_GEOCODE_ATTEMPTS = 4;
    private static final int MAP_ZOOM = 15;

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
        return lookupAddress(address.trim())
                .flatMap(hit -> renderMapPng(hit.lat(), hit.lon(), size));
    }

    /** Geocodifica con las mismas variantes de consulta que el preview del mapa. */
    public Optional<GeocodeHit> lookupAddress(String address) {
        if (address == null || address.isBlank()) {
            return Optional.empty();
        }
        return geocodeDetailed(address.trim());
    }

    public AddressGeocodeResponse lookupAddressResponse(String address) {
        return lookupAddress(address)
                .map(hit -> new AddressGeocodeResponse(
                        true, hit.lat(), hit.lon(), hit.displayName(), hit.precision()))
                .orElseGet(AddressGeocodeResponse::notFound);
    }

    static List<String> geocodeQueries(String address) {
        String trimmed = address.trim();
        if (trimmed.isEmpty()) {
            return List.of();
        }

        Set<String> queries = new LinkedHashSet<>();
        addQuery(queries, trimmed);
        if (!trimmed.toLowerCase(Locale.ROOT).contains("uruguay")) {
            addQuery(queries, trimmed + ", Uruguay");
        }

        List<String> segments = splitSegments(trimmed);
        if (segments.size() >= 2) {
            addQuery(queries, String.join(", ", segments.subList(1, segments.size())));
            if (!containsUruguay(segments)) {
                addQuery(queries, String.join(", ", segments.subList(1, segments.size())) + ", Uruguay");
            }
        }

        int streetIdx = indexOfStreetSegment(segments);
        if (streetIdx >= 0) {
            String street = segments.get(streetIdx);
            String city = findCitySegment(segments, streetIdx);
            if (city != null) {
                addQuery(queries, street + ", " + city + ", Uruguay");
            } else {
                addQuery(queries, street + ", Montevideo, Uruguay");
            }
        }

        List<String> out = new ArrayList<>(queries);
        if (out.size() > MAX_GEOCODE_ATTEMPTS) {
            return out.subList(0, MAX_GEOCODE_ATTEMPTS);
        }
        return out;
    }

    private Optional<GeocodeHit> geocodeDetailed(String address) {
        List<String> queries = geocodeQueries(address);
        for (int i = 0; i < queries.size(); i++) {
            if (i > 0) {
                try {
                    Thread.sleep(1100);
                } catch (InterruptedException ex) {
                    Thread.currentThread().interrupt();
                    return Optional.empty();
                }
            }
            Optional<GeocodeHit> found = geocodeOnce(queries.get(i));
            if (found.isPresent()) {
                return found;
            }
        }
        return Optional.empty();
    }

    private Optional<GeocodeHit> geocodeOnce(String query) {
        try {
            String q = URLEncoder.encode(query, StandardCharsets.UTF_8);
            String countryCodes = query.toLowerCase(Locale.ROOT).contains("uruguay") ? "&countrycodes=uy" : "";
            URI uri = URI.create(
                    "https://nominatim.openstreetmap.org/search?q=" + q
                            + "&format=json&limit=1" + countryCodes);
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
            String displayName = item.hasNonNull("display_name")
                    ? item.get("display_name").asText()
                    : query;
            String type = item.hasNonNull("type") ? item.get("type").asText() : "";
            String osmClass = item.hasNonNull("class") ? item.get("class").asText() : "";
            String precision = classifyPrecision(type, osmClass);
            return Optional.of(new GeocodeHit(lat, lon, displayName, precision));
        } catch (Exception ex) {
            return Optional.empty();
        }
    }

    static String classifyPrecision(String type, String osmClass) {
        String t = type == null ? "" : type.toLowerCase(Locale.ROOT);
        String c = osmClass == null ? "" : osmClass.toLowerCase(Locale.ROOT);

        if ("house".equals(t) || "building".equals(t) || ("yes".equals(t) && "building".equals(c))) {
            return "EXACT";
        }
        if ("place".equals(c)) {
            if (Set.of("city", "town", "village", "suburb", "neighbourhood", "quarter", "locality", "municipality")
                    .contains(t)) {
                return "AREA";
            }
        }
        if ("boundary".equals(c) && ("administrative".equals(t) || "political".equals(t))) {
            return "AREA";
        }
        if ("highway".equals(c) || t.contains("road") || "pedestrian".equals(t) || "footway".equals(t)) {
            return "APPROXIMATE";
        }
        return "APPROXIMATE";
    }

    private Optional<byte[]> renderMapPng(double lat, double lon, int size) {
        try {
            BufferedImage image = new BufferedImage(size, size, BufferedImage.TYPE_INT_RGB);
            Graphics2D g = image.createGraphics();
            g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g.setColor(new Color(0xE7E4DC));
            g.fillRect(0, 0, size, size);

            double worldSize = 256.0 * (1 << MAP_ZOOM);
            double worldX = (lon + 180.0) / 360.0 * worldSize;
            double latRad = Math.toRadians(lat);
            double worldY = (1.0 - Math.log(Math.tan(latRad) + 1.0 / Math.cos(latRad)) / Math.PI) / 2.0 * worldSize;

            double topLeftX = worldX - size / 2.0;
            double topLeftY = worldY - size / 2.0;

            int tileMinX = (int) Math.floor(topLeftX / 256.0);
            int tileMinY = (int) Math.floor(topLeftY / 256.0);
            int tileMaxX = (int) Math.floor((topLeftX + size - 1) / 256.0);
            int tileMaxY = (int) Math.floor((topLeftY + size - 1) / 256.0);

            for (int tileX = tileMinX; tileX <= tileMaxX; tileX++) {
                for (int tileY = tileMinY; tileY <= tileMaxY; tileY++) {
                    BufferedImage tile = fetchTile(MAP_ZOOM, tileX, tileY);
                    if (tile == null) {
                        continue;
                    }
                    int destX = (int) Math.round(tileX * 256.0 - topLeftX);
                    int destY = (int) Math.round(tileY * 256.0 - topLeftY);
                    g.drawImage(tile, destX, destY, null);
                }
            }

            drawMarker(g, size / 2, size / 2 - 4);
            g.dispose();

            ByteArrayOutputStream output = new ByteArrayOutputStream();
            ImageIO.write(image, "png", output);
            return Optional.of(output.toByteArray());
        } catch (Exception ex) {
            return Optional.empty();
        }
    }

    private BufferedImage fetchTile(int zoom, int x, int y) {
        try {
            String url = String.format(Locale.ROOT, "https://tile.openstreetmap.org/%d/%d/%d.png", zoom, x, y);
            HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                    .timeout(TIMEOUT)
                    .header("User-Agent", USER_AGENT)
                    .GET()
                    .build();
            HttpResponse<byte[]> response = httpClient.send(request, HttpResponse.BodyHandlers.ofByteArray());
            if (response.statusCode() != 200 || response.body() == null || response.body().length == 0) {
                return null;
            }
            return ImageIO.read(new ByteArrayInputStream(response.body()));
        } catch (Exception ex) {
            return null;
        }
    }

    private static void drawMarker(Graphics2D g, int x, int y) {
        g.setColor(new Color(0x2563EB));
        g.fillOval(x - 7, y - 7, 14, 14);
        g.setColor(Color.WHITE);
        g.fillOval(x - 3, y - 3, 6, 6);
    }

    private static void addQuery(Set<String> queries, String value) {
        String trimmed = value.trim();
        if (!trimmed.isEmpty()) {
            queries.add(trimmed);
        }
    }

    private static List<String> splitSegments(String address) {
        List<String> segments = new ArrayList<>();
        for (String part : address.split(",")) {
            String trimmed = part.trim();
            if (!trimmed.isEmpty()) {
                segments.add(trimmed);
            }
        }
        return segments;
    }

    private static boolean containsUruguay(List<String> segments) {
        return segments.stream().anyMatch(s -> "uruguay".equalsIgnoreCase(s));
    }

    private static int indexOfStreetSegment(List<String> segments) {
        for (int i = 0; i < segments.size(); i++) {
            if (segments.get(i).matches(".*\\d.*")) {
                return i;
            }
        }
        return -1;
    }

    private static String findCitySegment(List<String> segments, int streetIdx) {
        for (int i = segments.size() - 1; i >= 0; i--) {
            if (i == streetIdx) {
                continue;
            }
            String segment = segments.get(i);
            if ("uruguay".equalsIgnoreCase(segment)) {
                continue;
            }
            if (segment.matches(".*\\d.*")) {
                continue;
            }
            return segment;
        }
        return null;
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

    public record GeocodeHit(double lat, double lon, String displayName, String precision) {
    }
}
