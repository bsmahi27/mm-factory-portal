package com.mmfactory.triggersradar.dto;

import java.util.UUID;

public record TriggersRadarUploadResponse(
        UUID triggerId,
        String fileName,
        long importedRecordCount,
        String status) {
}

