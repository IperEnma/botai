package com.botai.infrastructure.chatbot.channel;

import com.botai.application.chatbot.dto.ProcessMessageResult;
import com.botai.application.chatbot.prompt.BotPrompts;
import com.botai.application.chatbot.support.InboundMetadata;
import com.botai.application.chatbot.usecase.ProcessInboundMessageUseCase;
import com.botai.domain.chatbot.model.InboundMessage;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.infrastructure.chatbot.channel.whatsapp.WhatsAppLogRedaction;
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
        log.info("[BUFFER] bufferAndProcess: convId={}, text={}",
                maskConversationId(conversationId), inbound.getText());
        
        buffers.compute(conversationId, (key, existing) -> {
            if (existing == null) {
                log.debug("[BUFFER] Creando nuevo buffer para {}", maskConversationId(conversationId));
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
                    boolean canSend = out.getTenantId() != null && !out.getTenantId().isBlank();
                    if (canSend) {
                        log.info("Response sent for {} buffered messages", toProcess.size());
                    } else {
                        log.warn("Response not sent (tenantId ausente): usuario no recibe respuesta. Configura el bot con WhatsApp Phone number ID en el panel.");
                    }
                }
            } catch (Exception e) {
                log.error("[BUFFER] Error processing messages for {}: {} — {}", conversationId, e.getMessage(), e.getClass().getSimpleName(), e);
                String tenantId = InboundMetadata.tenantId(first);
                OutboundMessage errorOut = OutboundMessage.builder()
                    .text(BotPrompts.UserFacing.RETRY_LATER)
                    .conversationId(conversationId)
                    .tenantId(tenantId)
                    .build();
                onResponse.accept(errorOut);
            }
        }
    }

    private static String maskConversationId(String conversationId) {
        if (conversationId == null || conversationId.isBlank()) {
            return "***";
        }
        int at = conversationId.indexOf('@');
        if (at <= 0) {
            return WhatsAppLogRedaction.maskPhone(conversationId);
        }
        return WhatsAppLogRedaction.maskPhone(conversationId.substring(0, at))
                + conversationId.substring(at);
    }
}
