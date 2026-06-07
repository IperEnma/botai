package com.botai.infrastructure.agenda.support;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertEquals;

class OpenStreetMapPreviewServiceTest {

    @Test
    void geocodeQueries_dropsLeadingNeighborhood() {
        List<String> queries = OpenStreetMapPreviewService.geocodeQueries(
                "Aguada, Agraciada 2526, Montevideo, Uruguay");

        assertThat(queries).contains(
                "Aguada, Agraciada 2526, Montevideo, Uruguay",
                "Agraciada 2526, Montevideo, Uruguay");
    }

    @Test
    void geocodeQueries_buildsStreetCityQuery() {
        List<String> queries = OpenStreetMapPreviewService.geocodeQueries(
                "Aguada, Agraciada 2526, Montevideo, Uruguay");

        assertThat(queries).contains("Agraciada 2526, Montevideo, Uruguay");
    }

    @Test
    void geocodeQueries_appendsUruguayWhenMissing() {
        List<String> queries = OpenStreetMapPreviewService.geocodeQueries("Agraciada 2526, Montevideo");

        assertThat(queries).contains("Agraciada 2526, Montevideo, Uruguay");
    }

    @Test
    void classifyPrecision_marcaExactoCasa() {
        assertEquals("EXACT", OpenStreetMapPreviewService.classifyPrecision("house", "building"));
    }

    @Test
    void classifyPrecision_marcaAreaCiudad() {
        assertEquals("AREA", OpenStreetMapPreviewService.classifyPrecision("city", "place"));
        assertEquals("AREA", OpenStreetMapPreviewService.classifyPrecision("suburb", "place"));
    }

    @Test
    void classifyPrecision_marcaAproximadoCalle() {
        assertEquals("APPROXIMATE", OpenStreetMapPreviewService.classifyPrecision("residential", "highway"));
    }
}
