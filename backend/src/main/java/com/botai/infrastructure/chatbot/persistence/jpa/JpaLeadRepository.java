package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.domain.chatbot.model.Lead;
import com.botai.domain.chatbot.repository.LeadRepository;
import com.botai.infrastructure.chatbot.persistence.entity.LeadEntity;
import org.springframework.stereotype.Repository;

@Repository
public class JpaLeadRepository implements LeadRepository {

    private final LeadJpaRepository jpaRepository;

    public JpaLeadRepository(LeadJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public Lead save(Lead lead) {
        LeadEntity entity = new LeadEntity();
        entity.setName(lead.getName());
        entity.setEmail(lead.getEmail());
        entity.setSource(lead.getSource());
        entity.setUserId(lead.getUserId());
        entity = jpaRepository.save(entity);
        return new Lead(entity.getName(), entity.getEmail(), entity.getSource(), entity.getUserId());
    }
}
