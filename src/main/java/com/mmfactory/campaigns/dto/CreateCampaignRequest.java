package com.mmfactory.campaigns.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record CreateCampaignRequest(
        @NotBlank
        String name,
        @NotBlank
        String businessUnitCode,
        String countryName,
        @NotBlank
        String status,
        @NotBlank
        String ownerName,
        @NotBlank
        String approverName,
        @NotNull
        LocalDate startDate,
        @NotNull
        LocalDate endDate,
        @PositiveOrZero
        Integer targetAccountCount,
        @PositiveOrZero
        Integer accountsReached,
        @PositiveOrZero
        Integer outreachCount,
        @PositiveOrZero
        Integer meetingCount,
        @DecimalMin("0.0")
        BigDecimal pipelineMillions,
        @PositiveOrZero
        Integer opportunitiesGenerated,
        @DecimalMin("0.0")
        BigDecimal winsMillions,
        Boolean signalDriven,
        String businessLine,
        String theme,
        String partnerName,
        String campaignDescription,
        String targetIndustry,
        List<String> partnerPlayNames,
        String solutionName,
        String radarEngineName,
        @PositiveOrZero
        Integer meetingsBooked,
        @PositiveOrZero
        Integer qualifiedLeads,
        @PositiveOrZero
        Integer cxoReach,
        @PositiveOrZero
        Integer inboundCount,
        @PositiveOrZero
        Integer audienceReach,
        @DecimalMin("0.0")
        BigDecimal bookingsMillions,
        @DecimalMin("0.0")
        BigDecimal revenueWonMillions,
        @Positive
        Long solutionId,
        @Positive
        Long radarEngineId
) {
    @AssertTrue(message = "endDate must be on or after startDate")
    public boolean isDateRangeValid() {
        return startDate == null || endDate == null || !endDate.isBefore(startDate);
    }
}