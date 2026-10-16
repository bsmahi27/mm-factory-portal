package com.mmfactory.common.reporting.internal;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "trigger_read_model", schema = "mmf_portal")
@Getter
@Setter
public class TriggersRadar {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private UUID triggerId;

    private String country;

    private String accountName;

    private String sector;

    private String triggerCategory;

    private String relevance;

    @Column(length = 2000)
    private String newsHeadline;

    @Column(length = 5000)
    private String newsSummary;

    private String sourceName;

    @Column(length = 2000)
    private String sourceUrl;

    private LocalDate publishedDate;

    @Column(length = 5000)
    private String recommendedAction;

    private String recommendedAgent;

    private String researcher;

    private String validationStatus;

    @Column(length = 5000)
    private String reviewerComments;

    private LocalDateTime processedAt;

    @PrePersist
    void prePersist() {
        if (processedAt == null) {
            processedAt = LocalDateTime.now();
        }
    }
}