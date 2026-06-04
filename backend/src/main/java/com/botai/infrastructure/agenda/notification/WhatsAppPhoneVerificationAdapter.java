package com.botai.infrastructure.agenda.notification;

import com.botai.domain.agenda.service.PhoneVerificationDeliveryPort;
import com.botai.infrastructure.chatbot.channel.whatsapp.WhatsAppCloudApiClient;
import org.springframework.stereotype.Component;

@Component
public class WhatsAppPhoneVerificationAdapter implements PhoneVerificationDeliveryPort {

    private final WhatsAppCloudApiClient whatsAppCloudApiClient;

    public WhatsAppPhoneVerificationAdapter(WhatsAppCloudApiClient whatsAppCloudApiClient) {
        this.whatsAppCloudApiClient = whatsAppCloudApiClient;
    }

    @Override
    public boolean sendVerificationCode(String tenantId, String phoneNormalized, String code) {
        String body = "Tu código para confirmar la reserva es: " + code + ". Válido 10 minutos.";
        return whatsAppCloudApiClient.sendText(tenantId, phoneNormalized, body);
    }
}
