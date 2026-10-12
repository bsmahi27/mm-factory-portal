package com.mmfactory.solutions.dto;

import java.util.List;

public record CreateSolutionRequest(
        String name,
        String solutionClass,
        List<String> tags,
        String maturity,
        String certificationStatus,
        Integer reuseCount
) {
}