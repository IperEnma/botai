package com.botai.agenda;

// La configuración de Flyway (locations, table, baseline-on-migrate, etc.)
// se inyecta vía AgendaEnvironmentPostProcessor antes de que arranque el contexto.
// FlywayAutoConfiguration de Spring Boot crea el bean flyway con esas propiedades.
// Esta clase se conserva vacía para no romper referencias de git.
