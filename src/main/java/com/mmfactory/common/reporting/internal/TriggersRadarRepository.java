package com.mmfactory.common.reporting.internal;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface TriggersRadarRepository extends JpaRepository<TriggersRadar, Long> {

    Page<TriggersRadar> findAllByTriggerId(UUID triggerId, Pageable pageable);
}