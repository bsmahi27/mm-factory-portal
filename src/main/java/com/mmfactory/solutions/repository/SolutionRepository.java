package com.mmfactory.solutions.repository;

import com.mmfactory.solutions.entity.Solution;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SolutionRepository extends JpaRepository<Solution, Long> {
}