package com.botai.application.chatbot.service.knowledge;

import com.botai.application.chatbot.prompt.BotPrompts;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Golden set ligero: reglas de respuesta cuando no hay datos (sin LLM).
 */
class RagGoldenSetRegressionTest {

    @Test
    void noInformationPhraseIsUserFriendlyNotTechnical() {
        String phrase = BotPrompts.RagChat.noInformationUserPhrase(
            "No tenemos esa información disponible. ¿En qué más podemos ayudarte?");
        assertThat(phrase).contains("No tenemos esa información disponible");
        assertThat(phrase).doesNotContain("CRAG");
        assertThat(phrase).doesNotContain("chunk");
        assertThat(phrase).doesNotContain("tool");
    }

    @Test
    void toolBudgetMessageIsAssistantVoice() {
        assertThat(BotPrompts.ToolsConsulta.ERR_TOOL_BUDGET_EXCEEDED)
            .doesNotContain("ThreadTenantContext")
            .contains("información");
    }
}
