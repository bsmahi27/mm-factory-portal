package com.mmfactory.partnerplay.controller;

import com.mmfactory.partnerplay.dto.*;
import com.mmfactory.partnerplay.service.PartnerPlayService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.RequiredArgsConstructor;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping(value = "/partner-plays", version = "1")
@RequiredArgsConstructor
@Tag(name = "Partner Plays", description = "Partner Play Management APIs")
public class PartnerPlayController {

    private final PartnerPlayService partnerPlayService;

    @GetMapping
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Get all partner plays", description = "Returns all available partner plays")
    public List<PartnerPlayResponse> getAllPartnerPlays() {
        return partnerPlayService.getAll();
    }

    @GetMapping(path = "/{name}")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Get partner play by name", description = "Returns a single partner play")
    public PartnerPlayResponse getPartnerPlay(@PathVariable Long id) {
        return partnerPlayService.getById(id);
    }

    @PostMapping(version = "1")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create partner play", description = "Creates a new partner play")
    public PartnerPlayResponse createPartnerPlay(@RequestBody CreatePartnerPlayRequest request) {
        return partnerPlayService.create(request);
    }

    @PutMapping(path = "/{name}")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Update partner play", description = "Updates an existing partner play")
    public PartnerPlayResponse updatePartnerPlay(@PathVariable Long id, @RequestBody UpdatePartnerPlayRequest request) {
        return partnerPlayService.update(id, request);
    }

    @PatchMapping("/{name}")
    public PartnerPlayResponse patchPartnerPlay(@PathVariable Long id, @RequestBody PatchPartnerPlayRequest request) {
        return partnerPlayService.patchPartnerPlay(id, request);
    }

    @PatchMapping(path = "/{name}/status")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Change partner play status", description = "Updates the status of a partner play")
    public PartnerPlayResponse changePartnerPlayStatus(@PathVariable Long id, @RequestBody ChangePartnerPlayStatusRequest request) {
        return partnerPlayService.changeStatus(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete partner play", description = "Deletes a partner play by ID")
    public void deletePartnerPlay(@PathVariable Long id) {
        partnerPlayService.delete(id);
    }
}
