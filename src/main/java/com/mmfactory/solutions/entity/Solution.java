package com.mmfactory.solutions.entity;


import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
@Entity
@Table(
        name = "solutions",
        schema = "mmf_portal"
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Solution {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;

    @Column(name = "solution_class")
    private String solutionClass;

    @Column(name = "tags")
    private String[] tags;

    private String maturity;

    @Column(name = "certification_status")
    private String certificationStatus;

    @Column(name = "reuse_count")
    private Integer reuseCount;
}