package com.mmfactory.common.ingestion;

import com.mmfactory.common.ingestion.internal.ExcelParser;
import com.mmfactory.common.ingestion.internal.TriggersIngestionRepository;
import com.mmfactory.common.ingestion.internal.TriggersRadarIngestion;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TriggersIngestionService {

    private final TriggersIngestionRepository repository;
    private final ExcelParser excelParser;
    private final ApplicationEventPublisher eventPublisher;

    @Transactional
    public FileImportedEvent importExcel(InputStream inputStream) throws IOException {
        var triggerId = UUID.randomUUID();

        List<TriggersRadarIngestion> entities = excelParser.parse(inputStream, triggerId);
        repository.saveAll(entities);

        var importedEvent = new FileImportedEvent(triggerId, entities.size());
        eventPublisher.publishEvent(importedEvent);

        return importedEvent;
    }

}
