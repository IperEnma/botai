package com.botai.infrastructure.chatbot.ai;

import com.botai.domain.chatbot.model.LlmRequest;
import com.botai.domain.chatbot.model.LlmResponse;
import com.botai.domain.chatbot.service.LanguageModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Language model implementation using Spring AI's ChatModel (Ollama, OpenAI, etc.).
 * Bean creado en OllamaModelConfig para evitar orden de inicialización.
 */
public class SpringAiLanguageModel implements LanguageModel {

    private static final Logger log = LoggerFactory.getLogger(SpringAiLanguageModel.class);

    private final ChatModel chatModel;

    public SpringAiLanguageModel(ChatModel chatModel) {
        this.chatModel = chatModel;
    }

    @Override
    public LlmResponse generate(LlmRequest request) {
        String userMessage = request.getUserMessage();
        if (userMessage == null || userMessage.isBlank()) {
            return LlmResponse.error("Empty user message");
        }

        List<org.springframework.ai.chat.messages.Message> messages = new ArrayList<>();
        String systemContent = request.getSystemPromptLines().stream()
            .filter(s -> s != null && !s.isBlank())
            .collect(Collectors.joining(" "));
        if (!systemContent.isBlank()) {
            messages.add(new SystemMessage(systemContent));
        }
        messages.add(new UserMessage(userMessage));

        try {
            var prompt = new Prompt(messages);
            var response = chatModel.call(prompt);
            String text = response.getResult() != null && response.getResult().getOutput() != null
                ? response.getResult().getOutput().getText()
                : "";
            if (text == null) text = "";
            return LlmResponse.ok(text.strip());
        } catch (Exception e) {
            log.error("[LLM] Ollama/chat falló: {}. ¿Ollama está corriendo? (ollama serve o base-url en .env)", e.getMessage());
            return LlmResponse.error("Error al conectar con el modelo: " + e.getMessage());
        }
    }
}
