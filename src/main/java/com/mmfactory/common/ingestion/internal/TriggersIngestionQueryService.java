package com.mmfactory.common.ingestion.internal;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TriggersIngestionQueryService implements com.mmfactory.common.ingestion.TriggersIngestionQueryService {

    private final TriggersIngestionRepository repository;

    @Override
    public List<TriggersRadarRow> findByTriggerId(UUID triggerId) {
        return repository.findAllByTriggerId(triggerId)
                .stream()
                .map(entity -> new TriggersRadarRow(
                        entity.getTriggerId(),
                        entity.getCountry(),
                        entity.getAccountName(),
                        entity.getSector(),
                        entity.getTriggerCategory(),
                        entity.getRelevance(),
                        entity.getNewsHeadline(),
                        entity.getNewsSummary(),
                        entity.getSourceName(),
                        entity.getSourceUrl(),
                        entity.getPublishedDate(),
                        entity.getRecommendedAction(),
                        entity.getRecommendedAgent(),
                        entity.getResearcher(),
                        entity.getValidationStatus(),
                        entity.getReviewerComments()
                ))
                .toList();
    }
}

