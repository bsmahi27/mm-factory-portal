package com.mmfactory.partnerplay.mapper;

import com.mmfactory.partnerplay.dto.PartnerPlayResponse;
import com.mmfactory.partnerplay.entity.PartnerPlay;

import java.util.Arrays;

public final class PartnerPlayMapper {

    private PartnerPlayMapper() {
    }

    public static PartnerPlayResponse toResponse(PartnerPlay entity) {

        return new PartnerPlayResponse(
                entity.getName(),
                entity.getPartnerName(),
                entity.getPartnerTier(),
                entity.getBusinessLine(),
                entity.getTheme(),
                Arrays.asList(entity.getEligibleCountryCodes()),
                entity.getStatus(),
                entity.getValueProposition(),
                entity.getInfluencedPipelineMillions(),
                entity.getLinkedCampaignCount(),
                entity.getOwnerName()
        );
    }
}