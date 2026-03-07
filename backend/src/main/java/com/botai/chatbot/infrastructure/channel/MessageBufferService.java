package com.botai.chatbot.infrastructure.channel;

import com.botai.chatbot.application.dto.ProcessMessageResult;
import com.botai.chatbot.application.usecase.ProcessInboundMessageUseCase;
import com.botai.chatbot.domain.model.InboundMessage;
import com.botai.chatbot.domain.model.OutboundMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.*;
import java.util.function.Consumer;
import java.util.stream.Collectors;

/**
 * Buffers incoming messages per conversation.
 * Waits for a quiet period before processing all accumulated messages together.
 * This prevents multiple responses when users send several messages quickly.
 */
@Service
public class MessageBufferService {

    private static final Logger log = LoggerFactory.getLogger(MessageBufferService.class);

    private final ProcessInboundMessageUseCase processInboundMessageUseCase;
    private final long debounceMs;

    private final Map<String, BufferedConversation> buffers = new ConcurrentHashMap<>();
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);

    public MessageBufferService(
            ProcessInboundMessageUseCase processInboundMessageUseCase,
            @Value("${bot.buffer.debounce-ms:2500}") long debounceMs) {
        this.processInboundMessageUseCase = processInboundMessageUseCase;
        this.debounceMs = debounceMs;
    }

    /**
     * Buffers message and schedules processing.
     * @param inbound The incoming message
     * @param onResponse Callback to send the response (e.g., WhatsApp adapter.send)
     */
    public void bufferAndProcess(InboundMessage inbound, Consumer<OutboundMessage> onResponse) {
        String conversationId = inbound.getConversationId();
        log.info("[BUFFER] bufferAndProcess: convId={}, text={}", conversationId, inbound.getText());
        
        buffers.compute(conversationId, (key, existing) -> {
            if (existing == null) {
                log.info("[BUFFER] Creando nuevo buffer para {}", conversationId);
                existing = new BufferedConversation(conversationId, onResponse);
            }
            existing.addMessage(inbound);
            existing.scheduleProcessing();
            return existing;
        });
    }

    private class BufferedConversation {
        private final String conversationId;
        private final Consumer<OutboundMessage> onResponse;
        private final List<InboundMessage> messages = new ArrayList<>();
        private ScheduledFuture<?> scheduledTask;

        BufferedConversation(String conversationId, Consumer<OutboundMessage> onResponse) {
            this.conversationId = conversationId;
            this.onResponse = onResponse;
        }

        synchronized void addMessage(InboundMessage msg) {
            messages.add(msg);
            log.debug("Buffered message for {}: {} (total: {})", conversationId, msg.getText(), messages.size());
        }

        synchronized void scheduleProcessing() {
            if (scheduledTask != null && !scheduledTask.isDone()) {
                scheduledTask.cancel(false);
                log.debug("Cancelled previous task for {}, rescheduling", conversationId);
            }
            scheduledTask = scheduler.schedule(this::processBufferedMessages, debounceMs, TimeUnit.MILLISECONDS);
        }

        void processBufferedMessages() {
            List<InboundMessage> toProcess;
            synchronized (this) {
                toProcess = new ArrayList<>(messages);
                messages.clear();
            }
            buffers.remove(conversationId);

            if (toProcess.isEmpty()) {
                return;
            }

            log.info("Processing {} buffered messages for {}", toProcess.size(), conversationId);

            String combinedText = toProcess.stream()
                .map(InboundMessage::getText)
                .filter(t -> t != null && !t.isBlank())
                .collect(Collectors.joining("\n"));

            if (combinedText.isBlank()) {
                return;
            }

            InboundMessage first = toProcess.get(0);
            InboundMessage combined = InboundMessage.builder()
                .channelId(first.getChannelId())
                .userId(first.getUserId())
                .conversationId(first.getConversationId())
                .text(combinedText)
                .metadata(first.getMetadata())
                .build();

            try {
                ProcessMessageResult result = processInboundMessageUseCase.execute(combined);
                OutboundMessage out = result.outboundMessage();
                if (out != null && out.getText() != null && !out.getText().isBlank()) {
                    onResponse.accept(out);
                    log.info("Sent single response for {} buffered messages", toProcess.size());
                }
            } catch (Exception e) {
                log.error("Error processing buffered messages for {}: {}", conversationId, e.getMessage());
            }
        }
    }
}
