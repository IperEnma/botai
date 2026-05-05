package com.botai.agenda.domain.repository;

import com.botai.agenda.domain.model.OutboxEvent;

import java.util.List;

public interface OutboxEventRepository {

    OutboxEvent save(OutboxEvent event);

    List<OutboxEvent> findPending();
}
