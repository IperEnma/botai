package com.botai.chatbot.domain.repository;

import com.botai.chatbot.domain.model.Lead;

/**
 * Port for persisting leads (CRM). Implementation in infrastructure.
 */
public interface LeadRepository {

    Lead save(Lead lead);
}
