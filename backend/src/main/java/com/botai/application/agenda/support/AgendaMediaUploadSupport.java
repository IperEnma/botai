package com.botai.application.agenda.support;

import com.botai.domain.agenda.service.AgendaMediaStorageKeys;
import org.springframework.web.multipart.MultipartFile;

/**
 * Utilidades compartidas para controllers de upload (extensión, content-type).
 */
public final class AgendaMediaUploadSupport {

    private AgendaMediaUploadSupport() {}

    public static String fileExtension(String originalFilename) {
        if (originalFilename != null && originalFilename.contains(".")) {
            return originalFilename.substring(originalFilename.lastIndexOf('.') + 1).toLowerCase();
        }
        return "jpg";
    }

    public static String resolveContentType(MultipartFile file, String storageKey) {
        if (file.getContentType() != null && !file.getContentType().isBlank()) {
            return file.getContentType();
        }
        return AgendaMediaStorageKeys.contentTypeFromPath(storageKey);
    }
}
