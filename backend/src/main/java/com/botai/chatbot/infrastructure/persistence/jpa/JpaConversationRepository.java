package com.botai.chatbot.infrastructure.persistence.jpa;

import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.repository.ConversationRepository;
import com.botai.chatbot.infrastructure.persistence.entity.ConversationEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Repository;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Repository
public class JpaConversationRepository implements ConversationRepository {

    private static final Logger log = LoggerFactory.getLogger(JpaConversationRepository.class);

    private final ConversationJpaRepository jpaRepository;

    public JpaConversationRepository(ConversationJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public Optional<ConversationState> findByConversationId(String conversationId) {
        log.debug("[REPO] Finding conversation: {}", conversationId);
        var result = jpaRepository.findById(conversationId).map(this::toState);
        log.debug("[REPO] Found: {}, context={}", result.isPresent(), result.map(s -> s.getContext()).orElse(null));
        return result;
    }

    @Override
    public void save(ConversationState state) {
        if (state == null || state.getConversationId() == null || state.getConversationId().isBlank()) {
            log.warn("[REPO] save() omitido: state o conversationId nulo");
            return;
        }
        log.info("[REPO] Saving state for {}, currentIntent={}, context={}",
            state.getConversationId(), state.getCurrentIntent(), state.getContext());
        ConversationEntity entity = jpaRepository.findById(state.getConversationId())
            .orElse(new ConversationEntity());
        entity.setConversationId(state.getConversationId());
        entity.setUserId(state.getUserId());
        entity.setChannelId(state.getChannelId());
        entity.setCurrentIntent(state.getCurrentIntent());
        Map<String, String> ctx = new HashMap<>();
        state.getContext().forEach((k, v) -> ctx.put(k, v != null ? v.toString() : ""));
        entity.setContext(ctx);
        entity.setUpdatedAt(state.getUpdatedAt());
        jpaRepository.save(entity);
        log.info("[REPO] Saved successfully, entity context={}", entity.getContext());
    }

    @Override
    public void clearIntent(String conversationId) {
        jpaRepository.findById(conversationId).ifPresent(e -> {
            e.setCurrentIntent(null);
            // Conservar todo el contexto (chatSessionId, nombre, documento, step, etc.). Solo se limpia el intent
            // para salir del flujo CRM; borrar el mapa rompía continuidad y hacía que el siguiente turno
            // cargara context={tenantId} y perdiera datos del usuario.
            jpaRepository.save(e);
        });
    }

    private ConversationState toState(ConversationEntity e) {
        Map<String, Object> ctx = new HashMap<>(e.getContext());
        return ConversationState.builder()
            .conversationId(e.getConversationId())
            .userId(e.getUserId())
            .channelId(e.getChannelId())
            .currentIntent(e.getCurrentIntent())
            .context(ctx)
            .updatedAt(e.getUpdatedAt())
            .build();
    }
}
