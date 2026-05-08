package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.OutboxEvent;

import java.util.List;

public interface OutboxEventRepository {

    OutboxEvent save(OutboxEvent event);

    List<OutboxEvent> findPending();
}
