package com.mmfactory.campaigns.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "campaigns", schema = "mmf_portal")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Campaign {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @Column(name = "business_unit_code")
    private String businessUnitCode;

    @Column(name = "country_name")
    private String countryName;

    private String status;

    @Column(name = "owner_name")
    private String ownerName;

    @Column(name = "approver_name")
    private String approverName;

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "target_account_count")
    private Integer targetAccountCount;

    @Column(name = "accounts_reached")
    private Integer accountsReached;

    @Column(name = "outreach_count")
    private Integer outreachCount;

    @Column(name = "meeting_count")
    private Integer meetingCount;

    @Column(name = "pipeline_millions")
    private BigDecimal pipelineMillions;

    @Column(name = "opportunities_generated")
    private Integer opportunitiesGenerated;

    @Column(name = "wins_millions")
    private BigDecimal winsMillions;

    @Column(name = "signal_driven")
    private Boolean signalDriven;

    @Column(name = "business_line")
    private String businessLine;

    private String theme;

    @Column(name = "partner_name")
    private String partnerName;

    @Column(name = "campaign_description")
    private String campaignDescription;

    @Column(name = "sponsor_name")
    private String sponsorName;

    @Column(name = "target_industry")
    private String targetIndustry;

    @Column(name = "campaign_visual", columnDefinition = "TEXT")
    private String campaignVisual;

    @Column(name = "target_account_list", columnDefinition = "TEXT")
    private String targetAccountList;

    @Column(name = "market_insights", columnDefinition = "TEXT")
    private String marketInsights;

    @Column(name = "sales_playbook", columnDefinition = "TEXT")
    private String salesPlaybook;

    @Column(name = "linked_solution_name")
    private String linkedSolutionName;

    @Column(name = "meetings_booked")
    private Integer meetingsBooked;

    @Column(name = "qualified_leads")
    private Integer qualifiedLeads;

    @Column(name = "cxo_reach")
    private Integer cxoReach;

    @Column(name = "inbound_count")
    private Integer inboundCount;

    @Column(name = "audience_reach")
    private Integer audienceReach;

    @Column(name = "bookings_millions")
    private BigDecimal bookingsMillions;

    @Column(name = "revenue_won_millions")
    private BigDecimal revenueWonMillions;

    @Column(name = "solution_id")
    private Long solutionId;

    @Column(name = "radar_engine_id")
    private Long radarEngineId;

}
