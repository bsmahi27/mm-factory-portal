package com.mmfactory.solutions.service;

import com.mmfactory.common.exception.NotFoundException;
import com.mmfactory.solutions.dto.*;
import com.mmfactory.solutions.entity.Solution;
import com.mmfactory.solutions.mapper.SolutionMapper;
import com.mmfactory.solutions.repository.SolutionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class SolutionService {

    private final SolutionRepository repository;

    public List<SolutionResponse> getAll() {
        return repository.findAll()
                .stream()
                .map(SolutionMapper::toResponse)
                .toList();
    }

    public SolutionResponse getById(Long id) {

        var entity = repository.findById(id)
                .orElseThrow(() ->
                        new NotFoundException("Solution not found"));

        return SolutionMapper.toResponse(entity);
    }

    public SolutionResponse create(
            CreateSolutionRequest request) {

        var solution = Solution.builder()
                .name(request.name())
                .solutionClass(request.solutionClass())
                .tags(
                        request.tags() == null
                                ? new String[0]
                                : request.tags().toArray(new String[0])
                )
                .maturity(request.maturity())
                .certificationStatus(
                        request.certificationStatus()
                )
                .reuseCount(0)
                .build();

        solution = repository.save(solution);

        return SolutionMapper.toResponse(solution);
    }

    public SolutionResponse update(
            Long id,
            UpdateSolutionRequest request) {

        var solution = repository.findById(id)
                .orElseThrow(() ->
                        new NotFoundException("Solution not found"));

        solution.setSolutionClass(request.solutionClass());

        solution.setTags(
                request.tags() == null
                        ? new String[0]
                        : request.tags().toArray(new String[0])
        );

        solution.setMaturity(request.maturity());

        solution.setCertificationStatus(
                request.certificationStatus()
        );

        solution.setReuseCount(
                request.reuseCount()
        );

        solution = repository.save(solution);

        return SolutionMapper.toResponse(solution);
    }

    public SolutionResponse patchSolution(
            Long id,
            PatchSolutionRequest request) {

        var solution = repository.findById(id)
                .orElseThrow(() ->
                        new NotFoundException("Solution not found"));

        if (request.solutionClass() != null) {
            solution.setSolutionClass(
                    request.solutionClass());
        }

        if (request.tags() != null) {
            solution.setTags(
                    request.tags()
                            .toArray(new String[0]));
        }

        if (request.maturity() != null) {
            solution.setMaturity(
                    request.maturity());
        }

        if (request.certificationStatus() != null) {
            solution.setCertificationStatus(
                    request.certificationStatus());
        }

        if (request.reuseCount() != null) {
            solution.setReuseCount(
                    request.reuseCount());
        }

        solution = repository.save(solution);

        return SolutionMapper.toResponse(solution);
    }

    public SolutionResponse changeStatus(
            Long id,
            ChangeSolutionStatusRequest request) {

        var solution = repository.findById(id)
                .orElseThrow(() ->
                        new NotFoundException("Solution not found"));

        solution.setCertificationStatus(
                request.status());

        solution = repository.save(solution);

        return SolutionMapper.toResponse(solution);
    }

    public void delete(Long id) {
        repository.deleteById(id);
    }
}