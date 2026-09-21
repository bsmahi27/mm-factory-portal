package com.mmfactory.partnerplay.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "partner_plays")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PartnerPlay {

    @Id
    private String name;

    @Column(name = "partner_name")
    private String partnerName;

    @Column(name = "partner_tier")
    private String partnerTier;

    @Column(name = "business_line")
    private String businessLine;

    private String theme;

    @Column(name = "eligible_country_codes")
    private String[] eligibleCountryCodes;

    private String status;

    @Column(name = "value_proposition")
    private String valueProposition;

    @Column(name = "influenced_pipeline_millions")
    private BigDecimal influencedPipelineMillions;

    @Column(name = "linked_campaign_count")
    private Integer linkedCampaignCount;

    @Column(name = "owner_name")
    private String ownerName;
}

