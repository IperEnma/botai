package com.botai.agenda.domain.exception;

public class DuplicateCategorySlugException extends AgendaDomainException {
    public DuplicateCategorySlugException(String slug) {
        super("Ya existe una categoría con el slug: " + slug);
    }
}
