package com.mmfactory.common.ingestion.internal;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface TriggersIngestionRepository extends JpaRepository<TriggersRadarIngestion, Long> {

	List<TriggersRadarIngestion> findAllByTriggerId(UUID triggerId);
}
