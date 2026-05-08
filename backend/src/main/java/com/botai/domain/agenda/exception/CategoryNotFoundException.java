package com.botai.domain.agenda.exception;

public class CategoryNotFoundException extends AgendaDomainException {
    public CategoryNotFoundException(String identifier) {
        super("Categoría no encontrada: " + identifier);
    }
}
