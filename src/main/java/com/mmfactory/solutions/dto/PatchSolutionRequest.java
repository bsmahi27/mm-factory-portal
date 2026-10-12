package com.mmfactory.solutions.dto;

import org.jspecify.annotations.Nullable;

import java.util.List;

public record PatchSolutionRequest(

        @Nullable
        String solutionClass,

        @Nullable
        List<String> tags,

        @Nullable
        String maturity,

        @Nullable
        String certificationStatus,

        @Nullable
        Integer reuseCount

) {
}