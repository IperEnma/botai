package com.botai.domain.agenda.model;

/**
 * Value object: rating promedio + cantidad de reseñas de un negocio o profesional.
 * {@code average} es null cuando no hay reseñas ({@code count == 0}).
 */
public final class RatingSummary {

    private final Double average;
    private final int count;

    public RatingSummary(Double average, int count) {
        this.average = average;
        this.count = count;
    }

    public static RatingSummary empty() {
        return new RatingSummary(null, 0);
    }

    public Double getAverage() { return average; }
    public int getCount() { return count; }
}
