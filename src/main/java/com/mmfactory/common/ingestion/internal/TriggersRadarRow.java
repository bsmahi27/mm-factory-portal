package com.mmfactory.common.ingestion.internal;

import java.time.LocalDate;
import java.util.UUID;

public record TriggersRadarRow(
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
        String reviewerComments) {
}
