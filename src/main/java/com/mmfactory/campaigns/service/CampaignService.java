package com.mmfactory.campaigns.service;

import com.mmfactory.campaigns.dto.CampaignResponse;
import com.mmfactory.campaigns.dto.CampaignLookupsResponse;
import com.mmfactory.campaigns.dto.CampaignResponse;
import com.mmfactory.campaigns.dto.CreateCampaignRequest;
import com.mmfactory.campaigns.dto.UpdateCampaignRequest;
import java.util.List;

public interface CampaignService {

    List<CampaignResponse> getAllCampaigns();

    CampaignResponse getCampaignById(Long id);

    CampaignResponse createCampaign(CreateCampaignRequest request);

    CampaignResponse updateCampaign(Long id, UpdateCampaignRequest request);

    CampaignLookupsResponse getLookups();
}