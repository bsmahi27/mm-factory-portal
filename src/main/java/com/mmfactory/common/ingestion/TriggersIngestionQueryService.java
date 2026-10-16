package com.mmfactory.common.ingestion;

import com.mmfactory.common.ingestion.internal.TriggersRadarRow;

import java.util.List;
import java.util.UUID;

public interface TriggersIngestionQueryService {

    List<TriggersRadarRow> findByTriggerId(UUID triggerId);
}