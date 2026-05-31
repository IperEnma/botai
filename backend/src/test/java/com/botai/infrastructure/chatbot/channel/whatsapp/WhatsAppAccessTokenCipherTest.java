package com.botai.infrastructure.chatbot.channel.whatsapp;

import com.botai.infrastructure.chatbot.config.BotWhatsAppConfig;
import com.botai.infrastructure.config.AppUrlProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class WhatsAppAccessTokenCipherTest {

    BotWhatsAppConfig config;
    WhatsAppAccessTokenCipher cipher;

    @BeforeEach
    void setUp() {
        config = new BotWhatsAppConfig(new AppUrlProperties());
        config.setEncryptionSecret("test-encryption-secret-32-chars!!");
        cipher = new WhatsAppAccessTokenCipher(config);
    }

    @Test
    void encrypt_decrypt_roundTrip() {
        String plain = "EAAtest-access-token-xyz";
        String enc = cipher.encrypt(plain);

        assertTrue(WhatsAppAccessTokenCipher.isEncrypted(enc));
        assertNotEquals(plain, enc);
        assertEquals(plain, cipher.decrypt(enc));
    }

    @Test
    void decrypt_legacyPlaintext() {
        assertEquals("EAAlegacy", cipher.decrypt("EAAlegacy"));
    }

    @Test
    void encryptedMetaTokenExceedsVarchar255() {
        // Meta suele emitir tokens largos (~200–500+ chars).
        String metaLike = "EAA" + "x".repeat(380);
        String enc = cipher.encrypt(metaLike);

        assertTrue(enc.length() > 255, "ciphertext debe ser >255 para forzar TEXT en BD");
        assertEquals(metaLike, cipher.decrypt(enc));
    }

    @Test
    void migratePlaintextIfNeeded_encryptsLegacy() {
        String migrated = cipher.migratePlaintextIfNeeded("EAAlegacy");
        assertTrue(WhatsAppAccessTokenCipher.isEncrypted(migrated));
        assertEquals("EAAlegacy", cipher.decrypt(migrated));
    }
}
