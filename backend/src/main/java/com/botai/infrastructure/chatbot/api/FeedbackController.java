package com.botai.infrastructure.chatbot.api;

import com.botai.application.chatbot.service.feedback.ConversationFeedbackService;
import com.botai.domain.chatbot.model.ConversationFeedback;
import com.botai.domain.chatbot.model.ConversationFeedbackRating;
import com.botai.infrastructure.chatbot.persistence.entity.FaqEntity;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/tenants/{tenantId}")
@CrossOrigin(origins = "*")
public class FeedbackController {

    private final ConversationFeedbackService feedbackService;

    public FeedbackController(ConversationFeedbackService feedbackService) {
        this.feedbackService = feedbackService;
    }

    @PostMapping("/conversations/{conversationId}/feedback")
    public ResponseEntity<?> submitFeedback(@PathVariable String tenantId,
                                            @PathVariable String conversationId,
                                            @RequestBody Map<String, String> body) {
        try {
            ConversationFeedbackRating rating = ConversationFeedbackRating.from(body.get("rating"));
            ConversationFeedback saved = feedbackService.recordFeedback(
                tenantId,
                conversationId,
                body.getOrDefault("sessionId", ""),
                body.getOrDefault("userMessage", ""),
                body.getOrDefault("botReply", ""),
                rating,
                body.getOrDefault("intentSource", "")
            );
            return ResponseEntity.ok(Map.of("id", saved.getId(), "status", "recorded"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/feedback")
    public ResponseEntity<List<ConversationFeedback>> listFeedback(@PathVariable String tenantId,
                                                                   @RequestParam(defaultValue = "50") int limit) {
        return ResponseEntity.ok(feedbackService.listRecent(tenantId, limit));
    }

    @PostMapping("/feedback/{feedbackId}/promote-to-faq")
    public ResponseEntity<?> promoteToFaq(@PathVariable String tenantId,
                                          @PathVariable long feedbackId,
                                          @RequestBody Map<String, String> body) {
        return feedbackService.promoteNegativeToFaq(
                tenantId,
                feedbackId,
                body.get("intent"),
                body.get("keywords"),
                body.get("response"))
            .<ResponseEntity<?>>map(faq -> ResponseEntity.ok(Map.of(
                "faqId", faq.getId(),
                "intent", faq.getIntent(),
                "promoted", true)))
            .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                "error", "Feedback no encontrado o ya promovido")));
    }
}
