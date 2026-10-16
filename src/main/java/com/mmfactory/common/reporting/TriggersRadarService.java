package com.mmfactory.common.reporting;

import com.mmfactory.common.ingestion.FileImportedEvent;
import com.mmfactory.common.ingestion.TriggersIngestionQueryService;
import com.mmfactory.common.ingestion.internal.TriggersRadarRow;
import com.mmfactory.common.reporting.internal.TriggersRadar;
import com.mmfactory.common.reporting.internal.TriggersRadarRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.modulith.events.ApplicationModuleListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TriggersRadarService {

    private final TriggersIngestionQueryService queryService;
    private final TriggersRadarRepository repository;

    @ApplicationModuleListener
    public void onExcelImported(FileImportedEvent event) {

        var records = queryService.findByTriggerId(event.triggerId());

        List<TriggersRadar> readModels =
                records.stream()
                        .map(this::toReadModel)
                        .toList();

        repository.saveAll(readModels);
    }

    @Transactional(readOnly = true)
    public Page<TriggersRadarModel> findAll(UUID triggerId, Pageable pageable) {
        var page = triggerId == null
                ? repository.findAll(pageable)
                : repository.findAllByTriggerId(triggerId, pageable);
        return page.map(this::toDto);
    }

    @Transactional(readOnly = true)
    public Optional<TriggersRadarModel> findById(Long id) {
        return repository.findById(id).map(this::toDto);
    }

    private TriggersRadarModel toDto(TriggersRadar view) {
        return new TriggersRadarModel(
                view.getId(),
                view.getTriggerId(),
                view.getCountry(),
                view.getAccountName(),
                view.getSector(),
                view.getTriggerCategory(),
                view.getRelevance(),
                view.getNewsHeadline(),
                view.getNewsSummary(),
                view.getSourceName(),
                view.getSourceUrl(),
                view.getPublishedDate(),
                view.getRecommendedAction(),
                view.getRecommendedAgent(),
                view.getResearcher(),
                view.getValidationStatus(),
                view.getReviewerComments(),
                view.getProcessedAt());
    }

    private TriggersRadar toReadModel(TriggersRadarRow record) {

        var readModelView = new TriggersRadar();

        readModelView.setTriggerId(record.triggerId());
        readModelView.setCountry(record.country());
        readModelView.setAccountName(record.accountName());
        readModelView.setSector(record.sector());
        readModelView.setTriggerCategory(record.triggerCategory());
        readModelView.setRelevance(record.relevance());
        readModelView.setNewsHeadline(record.newsHeadline());
        readModelView.setNewsSummary(record.newsSummary());
        readModelView.setSourceName(record.sourceName());
        readModelView.setSourceUrl(record.sourceUrl());
        readModelView.setPublishedDate(record.publishedDate());
        readModelView.setRecommendedAction(record.recommendedAction());
        readModelView.setRecommendedAgent(record.recommendedAgent());
        readModelView.setResearcher(record.researcher());
        readModelView.setValidationStatus(record.validationStatus());
        readModelView.setReviewerComments(record.reviewerComments());

        return readModelView;
    }
}