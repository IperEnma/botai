package com.botai.domain.chatbot.repository;

import com.botai.domain.chatbot.model.Lead;

/**
 * Port for persisting leads (CRM). Implementation in infrastructure.
 */
public interface LeadRepository {

    Lead save(Lead lead);
}
