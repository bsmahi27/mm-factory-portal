package com.mmfactory.campaigns.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record UpdateCampaignRequest(
        String name,
        String businessUnitCode,
        String countryName,
        String status,
        String ownerName,
        String approverName,
        LocalDate startDate,
        LocalDate endDate,
        Integer targetAccountCount,
        Integer accountsReached,
        Integer outreachCount,
        Integer meetingCount,
        BigDecimal pipelineMillions,
        Integer opportunitiesGenerated,
        BigDecimal winsMillions,
        Boolean signalDriven,
        String businessLine,
        String theme,
        String partnerName,
        String campaignDescription,
        Integer meetingsBooked,
        Integer qualifiedLeads,
        Integer cxoReach,
        Integer inboundCount,
        Integer audienceReach,
        BigDecimal bookingsMillions,
        BigDecimal revenueWonMillions,
        Long solutionId,
        Long radarEngineId
) {
}