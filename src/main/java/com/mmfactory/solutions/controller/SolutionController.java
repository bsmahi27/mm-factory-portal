package com.mmfactory.solutions.controller;

import com.mmfactory.solutions.dto.*;
import com.mmfactory.solutions.service.SolutionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;


@RestController
@RequestMapping(value = "/solutions", version = "1")
@CrossOrigin(origins = "http://localhost:3000")
@RequiredArgsConstructor
@Tag(
        name = "Solutions",
        description = "Solution Management APIs"
)
public class SolutionController {

    private final SolutionService solutionService;

    @GetMapping
    @ResponseStatus(HttpStatus.OK)
    @Operation(
            summary = "Get all solutions",
            description = "Returns all available solutions"
    )
    public List<SolutionResponse> getAllSolutions() {
        return solutionService.getAll();
    }

    @GetMapping("/{id}")
    @ResponseStatus(HttpStatus.OK)
    @Operation(
            summary = "Get solution by name",
            description = "Returns a single solution"
    )
    public SolutionResponse getSolution(
            @PathVariable Long id) {

        return solutionService.getById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(
            summary = "Create solution",
            description = "Creates a new solution"
    )
    public SolutionResponse createSolution(
            @RequestBody CreateSolutionRequest request) {

        return solutionService.create(request);
    }

    @PutMapping("/{id}")
    @ResponseStatus(HttpStatus.OK)
    @Operation(
            summary = "Update solution",
            description = "Updates an existing solution"
    )
    public SolutionResponse updateSolution(
            @PathVariable Long id,
            @RequestBody UpdateSolutionRequest request) {

        return solutionService.update(
                id,
                request
        );
    }

    @PatchMapping("/{id}")
    public SolutionResponse patchSolution(
            @PathVariable Long id,
            @RequestBody PatchSolutionRequest request
    ) {
        return solutionService.patchSolution(
                id,
                request
        );
    }

    @PatchMapping("/{id}/status")
    @ResponseStatus(HttpStatus.OK)
    @Operation(
            summary = "Change solution status",
            description = "Updates the status of a solution"
    )
    public SolutionResponse changeSolutionStatus(
            @PathVariable Long id,
            @RequestBody ChangeSolutionStatusRequest request) {

        return solutionService.changeStatus(
                id,
                request
        );
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(
            summary = "Delete solution",
            description = "Deletes a solution"
    )
    public void deleteSolution(
            @PathVariable Long id) {

        solutionService.delete(id);
    }
}