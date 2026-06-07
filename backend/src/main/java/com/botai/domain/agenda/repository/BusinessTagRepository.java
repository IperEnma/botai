package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.SearchTag;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public interface BusinessTagRepository {

    List<SearchTag> findByBusinessId(UUID businessId);

    Map<UUID, List<SearchTag>> findByBusinessIds(Collection<UUID> businessIds);

    void replaceByBusinessId(UUID businessId, List<SearchTag> tags);
}
