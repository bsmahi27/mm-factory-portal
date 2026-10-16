package com.mmfactory.solutions.mapper;

import com.mmfactory.solutions.dto.SolutionResponse;
import com.mmfactory.solutions.entity.Solution;

import java.util.Arrays;

public final class SolutionMapper {

    private SolutionMapper() {
    }

    public static SolutionResponse toResponse(Solution entity) {

        return new SolutionResponse(
                entity.getId(),
                entity.getName(),
                entity.getSolutionClass(),
                Arrays.asList(entity.getTags()),
                entity.getMaturity(),
                entity.getCertificationStatus(),
                entity.getReuseCount()
        );
    }
}