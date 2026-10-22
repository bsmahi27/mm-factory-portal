package com.mmfactory.campaigns.service.impl;

import com.mmfactory.campaigns.dto.CampaignResponse;
import com.mmfactory.campaigns.dto.CreateCampaignRequest;
import com.mmfactory.campaigns.dto.BusinessUnitLookup;
import com.mmfactory.campaigns.dto.CampaignLookupOption;
import com.mmfactory.campaigns.dto.CampaignLookupsResponse;
import com.mmfactory.campaigns.dto.CountryLookup;
import com.mmfactory.campaigns.dto.CampaignAssetLookup;
import com.mmfactory.campaigns.dto.PartnerPlayLookup;
import com.mmfactory.campaigns.dto.RadarEngineLookup;
import com.mmfactory.campaigns.dto.SalesPlaybookLookup;
import com.mmfactory.campaigns.dto.TargetAccountListLookup;
import com.mmfactory.campaigns.dto.UpdateCampaignRequest;
import com.mmfactory.campaigns.entity.Campaign;
import com.mmfactory.campaigns.mapper.CampaignMapper;
import com.mmfactory.campaigns.repository.CampaignRepository;
import com.mmfactory.campaigns.service.CampaignService;
import com.mmfactory.common.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Arrays;
import java.math.BigDecimal;

@Service
@RequiredArgsConstructor
public class CampaignServiceImpl implements CampaignService {

    private static final Logger log = LoggerFactory.getLogger(CampaignServiceImpl.class);

    private final CampaignRepository campaignRepository;
    private final JdbcTemplate jdbcTemplate;

    @Override
    public List<CampaignResponse> getAllCampaigns() {
        log.info("Fetching all campaigns");
        List<CampaignResponse> campaigns = campaignRepository.findAll()
                .stream()
                .map(CampaignMapper::toResponse)
                .toList();
        log.debug("Found {} campaigns", campaigns.size());
        return campaigns;
    }

    @Override
    public CampaignResponse getCampaignById(Long id) {
        log.info("Fetching campaign with id={}", id);

        Campaign campaign = campaignRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Campaign not found with id=" + id));

        CampaignResponse response = CampaignMapper.toResponse(campaign);
        log.debug("Campaign details retrieved for id={}", id);
        return response;
    }

    @Override
    public CampaignResponse createCampaign(CreateCampaignRequest request) {
        Long solutionId = request.solutionId() != null
                ? request.solutionId()
                : findLookupId("mmf_portal.solutions", request.solutionName(), "solution");
        Long radarEngineId = request.radarEngineId() != null
                ? request.radarEngineId()
                : findOptionalLookupId("mmf_portal.radar_engines", request.radarEngineName(), "radar engine");
        String partnerName = request.partnerName();
        if (partnerName == null && request.partnerPlayNames() != null) {
            partnerName = request.partnerPlayNames().stream()
                    .filter(name -> name != null && !name.isBlank())
                    .map(String::trim)
                    .distinct()
                    .collect(java.util.stream.Collectors.joining(", "));
            if (partnerName.isBlank()) {
                partnerName = null;
            }
        }

        Campaign campaign = Campaign.builder()
                .name(request.name())
                .businessUnitCode(request.businessUnitCode())
                .countryName(request.countryName())
                .status(request.status())
                .ownerName(request.ownerName())
                .approverName(request.approverName())
                .startDate(request.startDate())
                .endDate(request.endDate())
                .targetAccountCount(defaultInteger(request.targetAccountCount()))
                .accountsReached(defaultInteger(request.accountsReached()))
                .outreachCount(defaultInteger(request.outreachCount()))
                .meetingCount(defaultInteger(request.meetingCount()))
                .pipelineMillions(defaultDecimal(request.pipelineMillions()))
                .opportunitiesGenerated(defaultInteger(request.opportunitiesGenerated()))
                .winsMillions(defaultDecimal(request.winsMillions()))
                .signalDriven(request.signalDriven() != null && request.signalDriven())
                .businessLine(request.businessLine())
                .theme(request.theme())
                .partnerName(partnerName)
                .campaignDescription(request.campaignDescription())
                .targetIndustry(request.targetIndustry())
                .meetingsBooked(defaultInteger(request.meetingsBooked()))
                .qualifiedLeads(defaultInteger(request.qualifiedLeads()))
                .cxoReach(defaultInteger(request.cxoReach()))
                .inboundCount(defaultInteger(request.inboundCount()))
                .audienceReach(defaultInteger(request.audienceReach()))
                .bookingsMillions(defaultDecimal(request.bookingsMillions()))
                .revenueWonMillions(defaultDecimal(request.revenueWonMillions()))
                .solutionId(solutionId)
                .radarEngineId(radarEngineId)
                .build();
        Campaign createdCampaign = campaignRepository.save(campaign);
        log.info("Created campaign with id={}", createdCampaign.getId());
        return CampaignMapper.toResponse(createdCampaign);
    }

    private Long findLookupId(String table, String name, String lookupLabel) {
        Long id = findOptionalLookupId(table, name, lookupLabel);
        if (id == null) {
            throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        lookupLabel + " name or ID is required"
            );
        }
        return id;
    }

    private Long findOptionalLookupId(String table, String name, String lookupLabel) {
        if (name == null || name.isBlank()) {
            return null;
        }
        List<Long> ids = jdbcTemplate.query(
                "SELECT id FROM " + table + " WHERE name = ?",
                (resultSet, rowNum) -> resultSet.getLong("id"),
                name.trim()
        );
        return ids.stream()
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Unknown " + lookupLabel + ": " + name
                ));
    }

    private Integer defaultInteger(Integer value) {
        return value != null ? value : 0;
    }

    private BigDecimal defaultDecimal(BigDecimal value) {
        return value != null ? value : BigDecimal.ZERO;
    }

    @Override
    public CampaignResponse updateCampaign(Long id, UpdateCampaignRequest request) {
        log.info("Updating campaign with id={}", id);

        Campaign campaign = campaignRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Campaign not found with id=" + id));

        if (request.name() != null) campaign.setName(request.name());
        if (request.businessUnitCode() != null) campaign.setBusinessUnitCode(request.businessUnitCode());
        if (request.countryName() != null) campaign.setCountryName(request.countryName());
        if (request.status() != null) campaign.setStatus(request.status());
        if (request.ownerName() != null) campaign.setOwnerName(request.ownerName());
        if (request.approverName() != null) campaign.setApproverName(request.approverName());
        if (request.startDate() != null) campaign.setStartDate(request.startDate());
        if (request.endDate() != null) campaign.setEndDate(request.endDate());
        if (request.targetAccountCount() != null) campaign.setTargetAccountCount(request.targetAccountCount());
        if (request.accountsReached() != null) campaign.setAccountsReached(request.accountsReached());
        if (request.outreachCount() != null) campaign.setOutreachCount(request.outreachCount());
        if (request.meetingCount() != null) campaign.setMeetingCount(request.meetingCount());
        if (request.pipelineMillions() != null) campaign.setPipelineMillions(request.pipelineMillions());
        if (request.opportunitiesGenerated() != null) campaign.setOpportunitiesGenerated(request.opportunitiesGenerated());
        if (request.winsMillions() != null) campaign.setWinsMillions(request.winsMillions());
        if (request.signalDriven() != null) campaign.setSignalDriven(request.signalDriven());
        if (request.businessLine() != null) campaign.setBusinessLine(request.businessLine());
        if (request.theme() != null) campaign.setTheme(request.theme());
        if (request.partnerName() != null) campaign.setPartnerName(request.partnerName());
        if (request.campaignDescription() != null) campaign.setCampaignDescription(request.campaignDescription());
        if (request.meetingsBooked() != null) campaign.setMeetingsBooked(request.meetingsBooked());
        if (request.qualifiedLeads() != null) campaign.setQualifiedLeads(request.qualifiedLeads());
        if (request.cxoReach() != null) campaign.setCxoReach(request.cxoReach());
        if (request.inboundCount() != null) campaign.setInboundCount(request.inboundCount());
        if (request.audienceReach() != null) campaign.setAudienceReach(request.audienceReach());
        if (request.bookingsMillions() != null) campaign.setBookingsMillions(request.bookingsMillions());
        if (request.revenueWonMillions() != null) campaign.setRevenueWonMillions(request.revenueWonMillions());
        if (request.solutionId() != null) campaign.setSolutionId(request.solutionId());
        if (request.radarEngineId() != null) campaign.setRadarEngineId(request.radarEngineId());

        Campaign updatedCampaign = campaignRepository.save(campaign);
        log.debug("Campaign updated for id={}", id);
        return CampaignMapper.toResponse(updatedCampaign);
    }
    @Override
    public CampaignLookupsResponse getLookups() {
        List<BusinessUnitLookup> businessUnits = jdbcTemplate.query(
                "SELECT code, name FROM mmf_portal.business_units ORDER BY name",
                (resultSet, rowNum) -> new BusinessUnitLookup(
                        resultSet.getString("code"),
                        resultSet.getString("name")
                )
        );
        List<CountryLookup> countries = jdbcTemplate.query(
                "SELECT name, business_unit_code FROM mmf_portal.countries ORDER BY name",
                (resultSet, rowNum) -> new CountryLookup(
                        resultSet.getString("name"),
                        resultSet.getString("business_unit_code")
                )
        );
        List<String> statuses = getReferenceValues("Campaign status");
        List<String> businessLines = getReferenceValues("Business Line");
        List<String> industries = getReferenceValues("Industry / sector");
        List<String> themes = jdbcTemplate.query(
                """
                SELECT theme FROM mmf_portal.partner_plays WHERE theme IS NOT NULL
                UNION
                SELECT theme FROM mmf_portal.campaigns WHERE theme IS NOT NULL
                ORDER BY theme
                """,
                (resultSet, rowNum) -> resultSet.getString("theme")
        );
        List<RadarEngineLookup> radarEngines = jdbcTemplate.query(
                "SELECT id, name, business_unit_code FROM mmf_portal.radar_engines ORDER BY name",
                (resultSet, rowNum) -> new RadarEngineLookup(
                        resultSet.getLong("id"),
                        resultSet.getString("name"),
                        resultSet.getString("business_unit_code")
                )
        );
        List<CampaignLookupOption> solutions = jdbcTemplate.query(
                "SELECT id, name FROM mmf_portal.solutions ORDER BY name",
                (resultSet, rowNum) -> new CampaignLookupOption(
                        resultSet.getLong("id"),
                        resultSet.getString("name")
                )
        );
        List<CampaignAssetLookup> assets = jdbcTemplate.query(
                "SELECT id, name, solution_id FROM mmf_portal.assets ORDER BY name",
                (resultSet, rowNum) -> new CampaignAssetLookup(
                        resultSet.getLong("id"),
                        resultSet.getString("name"),
                        resultSet.getLong("solution_id")
                )
        );
        List<TargetAccountListLookup> targetAccountLists = jdbcTemplate.query(
                """
                SELECT id, file_name, business_unit_code
                FROM mmf_portal.prospect_upload_batches
                WHERE status = 'Committed'
                ORDER BY file_name
                """,
                (resultSet, rowNum) -> new TargetAccountListLookup(
                        resultSet.getString("id"),
                        resultSet.getString("file_name"),
                        resultSet.getString("business_unit_code")
                )
        );
        List<SalesPlaybookLookup> salesPlaybooks = jdbcTemplate.query(
                "SELECT name, channel, step_count, solution_id FROM mmf_portal.play_templates ORDER BY name",
                (resultSet, rowNum) -> new SalesPlaybookLookup(
                        resultSet.getString("name"),
                        resultSet.getString("channel"),
                        resultSet.getInt("step_count"),
                        resultSet.getLong("solution_id")
                )
        );
        List<PartnerPlayLookup> partnerPlays = jdbcTemplate.query(
                """
                SELECT id, name, partner_name, business_line, theme
                FROM mmf_portal.partner_plays
                ORDER BY name
                """,
                (resultSet, rowNum) -> new PartnerPlayLookup(
                        resultSet.getLong("id"),
                        resultSet.getString("name"),
                        resultSet.getString("partner_name"),
                        resultSet.getString("business_line"),
                        resultSet.getString("theme")
                )
        );
        return new CampaignLookupsResponse(
                businessUnits,
                countries,
                statuses,
                businessLines,
                industries,
                themes,
                radarEngines,
                solutions,
                assets,
                targetAccountLists,
                salesPlaybooks,
                partnerPlays
        );
    }

    private List<String> getReferenceValues(String category) {
        return jdbcTemplate.query(
                "SELECT values_text FROM mmf_portal.reference_data WHERE category = ?",
                (resultSet, rowNum) -> resultSet.getString("values_text"),
                category
        ).stream()
                .findFirst()
                .map(values -> Arrays.stream(values.split("\\s*(?:·|Â·)\\s*"))
                        .map(String::trim)
                        .filter(value -> !value.isEmpty())
                        .toList())
                .orElseGet(List::of);
    }
}