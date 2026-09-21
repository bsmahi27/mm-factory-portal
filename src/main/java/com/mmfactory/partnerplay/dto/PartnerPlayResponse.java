package com.mmfactory.partnerplay.dto;

import java.math.BigDecimal;
import java.util.List;

public record PartnerPlayResponse(
        String name,
        String partnerName,
        String partnerTier,
        String businessLine,
        String theme,
        List<String> eligibleCountryCodes,
        String status,
        String valueProposition,
        BigDecimal influencedPipelineMillions,
        Integer linkedCampaignCount,
        String ownerName) {
}
