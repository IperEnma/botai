package com.botai.infrastructure.agenda.support;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

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
}
