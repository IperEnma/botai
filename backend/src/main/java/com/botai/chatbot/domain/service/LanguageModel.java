package com.botai.chatbot.domain.service;

import com.botai.chatbot.domain.model.LlmRequest;
import com.botai.chatbot.domain.model.LlmResponse;

/**
 * Port for language models. The core depends only on this interface.
 * All concrete implementations (local, OpenAI, etc.) live in infrastructure/ai.
 */
public interface LanguageModel {

    LlmResponse generate(LlmRequest request);
}
