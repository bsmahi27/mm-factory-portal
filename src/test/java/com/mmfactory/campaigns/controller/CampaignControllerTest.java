package com.mmfactory.campaigns.controller;

import com.mmfactory.campaigns.dto.CampaignResponse;
import com.mmfactory.campaigns.dto.CreateCampaignRequest;
import com.mmfactory.campaigns.entity.Campaign;
import com.mmfactory.campaigns.mapper.CampaignMapper;
import com.mmfactory.campaigns.service.CampaignService;
import com.mmfactory.common.config.ApiVersionConfig;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(CampaignController.class)
@Import({ApiVersionConfig.class, CampaignControllerTest.TestConfig.class})
class CampaignControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private CampaignService campaignService;

    @BeforeEach
    void setUp() {
        Mockito.reset(campaignService);
    }

    @Test
    void createCampaignReturnsCreatedCampaignAtVersionedEndpoint() throws Exception {
        CampaignResponse response = CampaignMapper.toResponse(Campaign.builder()
                .id(42L)
                .name("New campaign")
                .status("Draft")
                .build());
        when(campaignService.createCampaign(any(CreateCampaignRequest.class))).thenReturn(response);

        mockMvc.perform(post("/api/v1/campaigns")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "New campaign",
                                  "businessUnitCode": "UK",
                                  "status": "Draft",
                                  "ownerName": "Owner",
                                  "approverName": "Approver",
                                  "startDate": "2026-10-01",
                                  "endDate": "2026-12-31",
                                  "signalDriven": false,
                                  "solutionName": "Cyber Baseline for Mid-Market",
                                  "radarEngineName": null,
                                  "partnerPlayNames": []
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(42))
                .andExpect(jsonPath("$.name").value("New campaign"));

        verify(campaignService).createCampaign(any(CreateCampaignRequest.class));
    }

    @Test
    void createCampaignRejectsInvalidRequest() throws Exception {
        mockMvc.perform(post("/api/v1/campaigns")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());

        verifyNoInteractions(campaignService);
    }

    @TestConfiguration
    static class TestConfig {
        @Bean
        CampaignService campaignService() {
            return Mockito.mock(CampaignService.class);
        }
    }
}
