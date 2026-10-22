package com.mmfactory.campaigns.service.impl;

import com.mmfactory.campaigns.dto.BusinessUnitLookup;
import com.mmfactory.campaigns.dto.CampaignAssetLookup;
import com.mmfactory.campaigns.dto.CampaignLookupOption;
import com.mmfactory.campaigns.dto.CreateCampaignRequest;
import com.mmfactory.campaigns.dto.PartnerPlayLookup;
import com.mmfactory.campaigns.dto.CountryLookup;
import com.mmfactory.campaigns.dto.RadarEngineLookup;
import com.mmfactory.campaigns.dto.SalesPlaybookLookup;
import com.mmfactory.campaigns.dto.TargetAccountListLookup;
import com.mmfactory.campaigns.dto.UpdateCampaignRequest;
import com.mmfactory.campaigns.entity.Campaign;
import com.mmfactory.campaigns.repository.CampaignRepository;
import com.mmfactory.common.exception.NotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.doReturn;

class CampaignServiceImplTest {

    private final CampaignRepository campaignRepository = mock(CampaignRepository.class);
    private final JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
    private final CampaignServiceImpl campaignService = new CampaignServiceImpl(campaignRepository, jdbcTemplate);

    @Test
    void createCampaignPersistsCampaignWithDatabaseGeneratedIdAndMetricDefaults() {
        when(campaignRepository.save(any(Campaign.class))).thenAnswer(invocation -> {
            Campaign campaign = invocation.getArgument(0);
            campaign.setId(42L);
            return campaign;
        });
        var request = new CreateCampaignRequest(
                "New campaign",
                "UK",
                null,
                "Draft",
                "Owner",
                "Approver",
                LocalDate.of(2026, 10, 1),
                LocalDate.of(2026, 12, 31),
                10,
                null, null, null, null, null, null, null,
                null, null, null, null, null,
                List.of(),
                null,
                null,
                null, null, null, null, null, null, null,
                1L,
                null
        );

        var response = campaignService.createCampaign(request);

        assertEquals(42L, response.id());
        assertEquals("New campaign", response.name());
        assertEquals("Draft", response.status());
        assertEquals(0, response.accountsReached());
        assertEquals(0, response.outreachCount());
        assertEquals(0, response.meetingCount());
        assertEquals(BigDecimal.ZERO, response.pipelineMillions());
        assertEquals(false, response.signalDriven());
        verify(campaignRepository).save(any(Campaign.class));
    }

    @Test
    void createCampaignResolvesFrontendLookupNamesAndDefaultsMissingTargetCount() {
        when(jdbcTemplate.query(
                eq("SELECT id FROM mmf_portal.solutions WHERE name = ?"),
                org.mockito.ArgumentMatchers.<RowMapper<Long>>any(),
                eq("Cyber Baseline for Mid-Market")
        )).thenReturn(List.of(8L));
        when(campaignRepository.save(any(Campaign.class))).thenAnswer(invocation -> {
            Campaign campaign = invocation.getArgument(0);
            campaign.setId(43L);
            return campaign;
        });
        var request = new CreateCampaignRequest(
                "neha",
                "NL",
                null,
                "Draft",
                "dane",
                "TBC",
                LocalDate.of(2026, 10, 7),
                LocalDate.of(2026, 10, 14),
                null,
                null, null, null, null, null, null,
                false,
                null, null, null,
                "good",
                null,
                List.of(),
                "Cyber Baseline for Mid-Market",
                null,
                null, null, null, null, null, null, null,
                null,
                null
        );

        var response = campaignService.createCampaign(request);

        assertEquals(43L, response.id());
        assertEquals(8L, response.solutionId());
        assertEquals(0, response.targetAccountCount());
        verify(campaignRepository).save(any(Campaign.class));
    }

    @Test
    void getLookupsReturnsAllLookupCollections() {
        var businessUnits = List.of(new BusinessUnitLookup("UK", "UK"));
        var countries = List.of(new CountryLookup("Sweden", "NO"));
        var radarEngines = List.of(new RadarEngineLookup(1L, "UK Manufacturing", "UK"));
        var solutions = List.of(new CampaignLookupOption(2L, "SAP Migration"));
        var assets = List.of(new CampaignAssetLookup(3L, "Migration blueprint", 2L));
        var targetAccountLists = List.of(new TargetAccountListLookup("BATCH-1", "UK list.xlsx", "UK"));
        var salesPlaybooks = List.of(new SalesPlaybookLookup("Migration play", "Email", 3, 2L));
        var partnerPlays = List.of(new PartnerPlayLookup(4L, "SAP RISE", "SAP", "ADM", "Cloud"));
        doReturn(businessUnits).when(jdbcTemplate).query(
                eq("SELECT code, name FROM mmf_portal.business_units ORDER BY name"),
                org.mockito.ArgumentMatchers.<RowMapper<BusinessUnitLookup>>any()
        );
        doReturn(countries).when(jdbcTemplate).query(
                eq("SELECT name, business_unit_code FROM mmf_portal.countries ORDER BY name"),
                org.mockito.ArgumentMatchers.<RowMapper<CountryLookup>>any()
        );
        doReturn(List.of("Draft · Active")).when(jdbcTemplate).query(
                eq("SELECT values_text FROM mmf_portal.reference_data WHERE category = ?"),
                org.mockito.ArgumentMatchers.<RowMapper<String>>any(),
                eq("Campaign status")
        );
        doReturn(List.of("ADM · CIS")).when(jdbcTemplate).query(
                eq("SELECT values_text FROM mmf_portal.reference_data WHERE category = ?"),
                org.mockito.ArgumentMatchers.<RowMapper<String>>any(),
                eq("Business Line")
        );
        doReturn(List.of("Manufacturing · Retail")).when(jdbcTemplate).query(
                eq("SELECT values_text FROM mmf_portal.reference_data WHERE category = ?"),
                org.mockito.ArgumentMatchers.<RowMapper<String>>any(),
                eq("Industry / sector")
        );
        doReturn(List.of("Cloud")).when(jdbcTemplate).query(
                org.mockito.ArgumentMatchers.contains("SELECT theme FROM mmf_portal.partner_plays"),
                org.mockito.ArgumentMatchers.<RowMapper<String>>any()
        );
        doReturn(radarEngines).when(jdbcTemplate).query(
                eq("SELECT id, name, business_unit_code FROM mmf_portal.radar_engines ORDER BY name"),
                org.mockito.ArgumentMatchers.<RowMapper<RadarEngineLookup>>any()
        );
        doReturn(solutions).when(jdbcTemplate).query(
                eq("SELECT id, name FROM mmf_portal.solutions ORDER BY name"),
                org.mockito.ArgumentMatchers.<RowMapper<CampaignLookupOption>>any()
        );
        doReturn(assets).when(jdbcTemplate).query(
                eq("SELECT id, name, solution_id FROM mmf_portal.assets ORDER BY name"),
                org.mockito.ArgumentMatchers.<RowMapper<CampaignAssetLookup>>any()
        );
        doReturn(targetAccountLists).when(jdbcTemplate).query(
                org.mockito.ArgumentMatchers.contains("FROM mmf_portal.prospect_upload_batches"),
                org.mockito.ArgumentMatchers.<RowMapper<TargetAccountListLookup>>any()
        );
        doReturn(salesPlaybooks).when(jdbcTemplate).query(
                eq("SELECT name, channel, step_count, solution_id FROM mmf_portal.play_templates ORDER BY name"),
                org.mockito.ArgumentMatchers.<RowMapper<SalesPlaybookLookup>>any()
        );
        doReturn(partnerPlays).when(jdbcTemplate).query(
                org.mockito.ArgumentMatchers.contains("SELECT id, name, partner_name"),
                org.mockito.ArgumentMatchers.<RowMapper<PartnerPlayLookup>>any()
        );

        var lookups = campaignService.getLookups();

        assertEquals(businessUnits, lookups.businessUnits());
        assertEquals(countries, lookups.countries());
        assertEquals(List.of("Draft", "Active"), lookups.statuses());
        assertEquals(List.of("ADM", "CIS"), lookups.businessLines());
        assertEquals(List.of("Manufacturing", "Retail"), lookups.industries());
        assertEquals(List.of("Cloud"), lookups.themes());
        assertEquals(radarEngines, lookups.radarEngines());
        assertEquals(solutions, lookups.solutions());
        assertEquals(assets, lookups.assets());
        assertEquals(targetAccountLists, lookups.targetAccountLists());
        assertEquals(salesPlaybooks, lookups.salesPlaybooks());
        assertEquals(partnerPlays, lookups.partnerPlays());
    }

    @Test
    void updateCampaignChangesProvidedFieldsAndPreservesUnprovidedFields() {
        var campaign = Campaign.builder()
                .id(5L)
                .name("Old campaign")
                .theme("Existing theme")
                .build();
        when(campaignRepository.findById(5L)).thenReturn(Optional.of(campaign));
        when(campaignRepository.save(any(Campaign.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        var request = new UpdateCampaignRequest(
                "Updated campaign", null, null, "Active", null, null, null, null,
                null, null, null, null, null, null, null, null, null, null,
                null, null, null, null, null, null, null, null, null, null, null
        );

        var response = campaignService.updateCampaign(5L, request);

        assertEquals("Updated campaign", response.name());
        assertEquals("Active", response.status());
        assertEquals("Existing theme", response.theme());
        verify(campaignRepository).save(campaign);
    }

    @Test
    void updateCampaignThrowsNotFoundWhenCampaignDoesNotExist() {
        when(campaignRepository.findById(99L)).thenReturn(Optional.empty());

        assertThrows(
                NotFoundException.class,
                () -> campaignService.updateCampaign(99L, new UpdateCampaignRequest(
                        null, null, null, null, null, null, null, null,
                        null, null, null, null, null, null, null, null, null, null,
                        null, null, null, null, null, null, null, null, null, null, null
                ))
        );
    }
}
