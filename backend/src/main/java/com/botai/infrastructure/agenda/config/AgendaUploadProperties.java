package com.botai.infrastructure.agenda.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "agenda.uploads")
public class AgendaUploadProperties {

    private String dir = "uploads";
    private String baseUrl = "http://localhost:8080/uploads";

    public String getDir() { return dir; }
    public void setDir(String dir) { this.dir = dir; }
    public String getBaseUrl() { return baseUrl; }
    public void setBaseUrl(String baseUrl) { this.baseUrl = baseUrl; }
}
