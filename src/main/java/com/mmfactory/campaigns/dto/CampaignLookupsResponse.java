package com.mmfactory.campaigns.dto;

import java.util.List;

public record CampaignLookupsResponse(
        List<BusinessUnitLookup> businessUnits,
        List<CountryLookup> countries,
        List<String> statuses,
        List<String> businessLines,
        List<String> industries,
        List<String> themes,
        List<RadarEngineLookup> radarEngines,
        List<CampaignLookupOption> solutions,
        List<CampaignAssetLookup> assets,
        List<TargetAccountListLookup> targetAccountLists,
        List<SalesPlaybookLookup> salesPlaybooks,
        List<PartnerPlayLookup> partnerPlays
) {
}
