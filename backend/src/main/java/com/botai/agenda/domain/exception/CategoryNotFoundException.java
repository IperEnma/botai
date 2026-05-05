package com.botai.agenda.domain.exception;

public class CategoryNotFoundException extends AgendaDomainException {
    public CategoryNotFoundException(String identifier) {
        super("Categoría no encontrada: " + identifier);
    }
}
