package com.mmfactory.common.ingestion.internal;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "trigger_ingestion", schema = "mmf_portal")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TriggersRadarIngestion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "trigger_id", nullable = false)
    private UUID triggerId;

    private String country;

    @Column(name = "account_name")
    private String accountName;

    private String sector;

    @Column(name = "trigger_category")
    private String triggerCategory;

    private String relevance;

    @Column(name = "news_headline", length = 2000)
    private String newsHeadline;

    @Column(name = "news_summary", length = 5000)
    private String newsSummary;

    @Column(name = "source_name")
    private String sourceName;

    @Column(name = "source_url", length = 2000)
    private String sourceUrl;

    private LocalDate publishedDate;

    @Column(name = "recommended_action", length = 5000)
    private String recommendedAction;

    private String recommendedAgent;

    private String researcher;

    private String validationStatus;

    @Column(length = 5000)
    private String reviewerComments;

    private LocalDateTime importedAt;

    @PrePersist
    void prePersist() {
        importedAt = LocalDateTime.now();
    }

}
