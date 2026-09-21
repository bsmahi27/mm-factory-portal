package com.mmfactory.partnerplay.dto;

import java.util.List;

public record CreatePartnerPlayRequest(
        String name,
        String partnerName,
        String partnerTier,
        String businessLine,
        String theme,
        List<String> eligibleCountryCodes,
        String valueProposition,
        String ownerName
) {
}