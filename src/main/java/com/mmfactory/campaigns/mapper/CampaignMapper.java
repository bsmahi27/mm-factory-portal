package com.mmfactory.campaigns.mapper;

import com.mmfactory.campaigns.dto.CampaignResponse;
import com.mmfactory.campaigns.entity.Campaign;

public class CampaignMapper {

    private CampaignMapper() {
    }

    public static CampaignResponse toResponse(Campaign campaign) {

        return new CampaignResponse(
                campaign.getId(),
                campaign.getName(),
                campaign.getBusinessUnitCode(),
                campaign.getCountryName(),
                campaign.getStatus(),
                campaign.getOwnerName(),
                campaign.getApproverName(),
                campaign.getStartDate(),
                campaign.getEndDate(),
                campaign.getTargetAccountCount(),
                campaign.getAccountsReached(),
                campaign.getOutreachCount(),
                campaign.getMeetingCount(),
                campaign.getPipelineMillions(),
                campaign.getOpportunitiesGenerated(),
                campaign.getWinsMillions(),
                campaign.getSignalDriven(),
                campaign.getBusinessLine(),
                campaign.getTheme(),
                campaign.getPartnerName(),
                campaign.getCampaignDescription(),
                campaign.getMeetingsBooked(),
                campaign.getQualifiedLeads(),
                campaign.getCxoReach(),
                campaign.getInboundCount(),
                campaign.getAudienceReach(),
                campaign.getBookingsMillions(),
                campaign.getRevenueWonMillions(),
                campaign.getSolutionId(),
                campaign.getRadarEngineId(),
                campaign.getSponsorName(),
                campaign.getTargetIndustry(),
                campaign.getCampaignVisual(),
                campaign.getTargetAccountList(),
                campaign.getMarketInsights(),
                campaign.getSalesPlaybook(),
                campaign.getLinkedSolutionName()
        );
    }
}