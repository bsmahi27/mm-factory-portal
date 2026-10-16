package com.mmfactory.common.reporting;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record TriggersRadarModel(
        Long id,
        UUID triggerId,
        String country,
        String accountName,
        String sector,
        String triggerCategory,
        String relevance,
        String newsHeadline,
        String newsSummary,
        String sourceName,
        String sourceUrl,
        LocalDate publishedDate,
        String recommendedAction,
        String recommendedAgent,
        String researcher,
        String validationStatus,
        String reviewerComments,
        LocalDateTime processedAt) {
}

