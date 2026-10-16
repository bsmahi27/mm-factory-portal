package com.mmfactory.triggersradar.dto;

import com.mmfactory.common.reporting.TriggersRadarModel;

import java.util.List;

public record TriggersRadarResponse(
        List<TriggersRadarModel> content,
        int page,
        int size,
        long totalElements,
        int totalPages) {
}

