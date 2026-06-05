package com.botai.application.chatbot.service.feedback;

import com.botai.domain.chatbot.model.ConversationFeedback;
import com.botai.domain.chatbot.model.ConversationFeedbackRating;
import com.botai.domain.chatbot.model.FaqResponseMode;
import com.botai.domain.chatbot.repository.ConversationFeedbackRepository;
import com.botai.infrastructure.chatbot.persistence.entity.FaqEntity;
import com.botai.infrastructure.chatbot.persistence.jpa.FaqJpaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Service
public class ConversationFeedbackService {

    private final ConversationFeedbackRepository feedbackRepository;
    private final FaqJpaRepository faqJpaRepository;

    public ConversationFeedbackService(ConversationFeedbackRepository feedbackRepository,
                                       FaqJpaRepository faqJpaRepository) {
        this.feedbackRepository = feedbackRepository;
        this.faqJpaRepository = faqJpaRepository;
    }

    public ConversationFeedback recordFeedback(String tenantId, String conversationId, String sessionId,
                                               String userMessage, String botReply, ConversationFeedbackRating rating,
                                               String intentSource) {
        ConversationFeedback feedback = new ConversationFeedback(
            null,
            tenantId,
            conversationId,
            sessionId,
            userMessage,
            botReply,
            rating,
            intentSource,
            false,
            Instant.now()
        );
        return feedbackRepository.save(feedback);
    }

    public List<ConversationFeedback> listRecent(String tenantId, int limit) {
        return feedbackRepository.findByTenantIdOrderByCreatedAtDesc(tenantId, limit);
    }

    @Transactional
    public Optional<FaqEntity> promoteNegativeToFaq(String tenantId, long feedbackId, String intent,
                                                   String keywords, String correctedResponse) {
        Optional<ConversationFeedback> feedback = feedbackRepository.findByIdAndTenantId(feedbackId, tenantId);
        if (feedback.isEmpty() || feedback.get().isPromotedToFaq()) {
            return Optional.empty();
        }
        if (intent == null || intent.isBlank() || keywords == null || keywords.isBlank()) {
            return Optional.empty();
        }
        String responseText = correctedResponse != null && !correctedResponse.isBlank()
            ? correctedResponse.strip()
            : (feedback.get().getBotReply() != null ? feedback.get().getBotReply().strip() : "");
        if (responseText.isBlank()) {
            return Optional.empty();
        }
        FaqEntity faq = new FaqEntity();
        faq.setIntent(intent.strip());
        faq.setKeywords(keywords.strip());
        faq.setResponse(responseText);
        faq.setUseRegex(false);
        faq.setActive(true);
        faq.setResponseMode(FaqResponseMode.FIXED.name());
        FaqEntity saved = faqJpaRepository.save(faq);
        feedbackRepository.markPromotedToFaq(feedbackId, tenantId);
        return Optional.of(saved);
    }
}
