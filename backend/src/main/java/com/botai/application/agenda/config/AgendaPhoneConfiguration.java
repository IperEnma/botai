package com.botai.application.agenda.config;

import com.botai.application.agenda.support.AgendaPhoneNormalizer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import jakarta.annotation.PostConstruct;

@Configuration
public class AgendaPhoneConfiguration {

    @Value("${agenda.phone.default-country-code:598}")
    private String defaultCountryCode;

    @PostConstruct
    void init() {
        AgendaPhoneNormalizer.configureDefaultCountryCode(defaultCountryCode);
    }
}
