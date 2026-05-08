package com.botai.domain.chatbot.service;

import com.botai.domain.chatbot.model.LlmRequest;
import com.botai.domain.chatbot.model.LlmResponse;

/**
 * Port for language models. The core depends only on this interface.
 * All concrete implementations (local, OpenAI, etc.) live in infrastructure/ai.
 */
public interface LanguageModel {

    LlmResponse generate(LlmRequest request);
}
