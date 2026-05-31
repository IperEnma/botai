package com.botai.infrastructure.agenda.config;

import com.botai.infrastructure.config.AppUrlProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "uploads")
public class AgendaUploadProperties {

    private final AppUrlProperties appUrls;

    private String dir = "uploads";

    public AgendaUploadProperties(AppUrlProperties appUrls) {
        this.appUrls = appUrls;
    }

    public String getDir() {
        return dir;
    }

    public void setDir(String dir) {
        this.dir = dir;
    }

    /** {@code urls.backend}/uploads */
    public String getBaseUrl() {
        return appUrls.uploadsBaseUrl();
    }
}
