package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.User;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository {

    User save(User user);

    Optional<User> findById(UUID id);

    Optional<User> findByTenantIdAndEmail(String tenantId, String email);

    List<User> searchClients(String tenantId, String q);
}
