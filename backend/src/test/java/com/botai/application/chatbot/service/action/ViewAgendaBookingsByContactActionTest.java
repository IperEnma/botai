package com.botai.application.chatbot.service.action;

import com.botai.domain.chatbot.ConversationContextKeys;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.infrastructure.chatbot.channel.whatsapp.WhatsAppAdapter;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class ViewAgendaBookingsByContactActionTest {

    @Test
    void tryParsePhone_extractsDigits() {
        ViewAgendaBookingsByContactAction.Contact c =
            ViewAgendaBookingsByContactAction.tryParsePhone("099 123 456");
        assertThat(c).isNotNull();
        assertThat(c.phoneNormalized()).isEqualTo("099123456");
    }

    @Test
    void tryParsePhone_ignoresEmailOnly() {
        assertThat(ViewAgendaBookingsByContactAction.tryParsePhone("ana@test.com")).isNull();
    }

    @Test
    void contactFromWhatsAppChannel_usesUserId() {
        var state = ConversationState.builder()
            .conversationId("5491123456789@whatsapp")
            .userId("5491123456789")
            .channelId(WhatsAppAdapter.CHANNEL_ID)
            .context(Map.of(ConversationContextKeys.TENANT_ID, "tenant-1"))
            .build();
        ViewAgendaBookingsByContactAction.Contact c =
            ViewAgendaBookingsByContactAction.contactFromWhatsAppChannel(state);
        assertThat(c).isNotNull();
        assertThat(c.phoneNormalized()).isEqualTo("5491123456789");
    }

    @Test
    void contactFromWhatsAppChannel_nonWhatsAppReturnsNull() {
        var state = ConversationState.builder()
            .conversationId("x")
            .userId("5491123456789")
            .channelId("web")
            .build();
        assertThat(ViewAgendaBookingsByContactAction.contactFromWhatsAppChannel(state)).isNull();
    }
}
