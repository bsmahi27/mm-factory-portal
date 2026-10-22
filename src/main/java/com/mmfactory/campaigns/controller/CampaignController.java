package com.mmfactory.campaigns.controller;

import com.mmfactory.campaigns.dto.CampaignResponse;
import com.mmfactory.campaigns.dto.CampaignLookupsResponse;
import com.mmfactory.campaigns.dto.CreateCampaignRequest;
import com.mmfactory.campaigns.dto.UpdateCampaignRequest;
import com.mmfactory.campaigns.service.CampaignService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping(value = "/campaigns", version = "1")
@RequiredArgsConstructor
public class CampaignController {

    private static final Logger log = LoggerFactory.getLogger(CampaignController.class);

    private final CampaignService campaignService;

    @GetMapping
    public List<CampaignResponse> getAllCampaigns() {
        log.info("Request received: getAllCampaigns");
        List<CampaignResponse> campaigns = campaignService.getAllCampaigns();
        log.debug("Returning {} campaigns from getAllCampaigns", campaigns.size());
        return campaigns;
    }
    @GetMapping("/lookups")
    public CampaignLookupsResponse getLookups() {
        return campaignService.getLookups();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CampaignResponse createCampaign(@Valid @RequestBody CreateCampaignRequest request) {
        log.info("Request received: createCampaign with name={}", request.name());
        return campaignService.createCampaign(request);
    }

    @GetMapping("/{id}")
    public CampaignResponse getCampaignById(@PathVariable Long id) {
        log.info("Request received: getCampaignById with id={}", id);
        CampaignResponse campaign = campaignService.getCampaignById(id);
        log.debug("Returning campaign details for id={}", id);
        return campaign;
    }

    @PatchMapping("/{id}")
    public CampaignResponse updateCampaign(
            @PathVariable Long id,
            @RequestBody UpdateCampaignRequest request) {
        log.info("Request received: updateCampaign with id={}", id);
        return campaignService.updateCampaign(id, request);
    }
}