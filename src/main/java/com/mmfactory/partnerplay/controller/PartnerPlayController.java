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
@Tag(
        name = "Partner Plays",
        description = "Partner Play Management APIs"
)
public class PartnerPlayController {

    private final PartnerPlayService partnerPlayService;

    @GetMapping
    @ResponseStatus(HttpStatus.OK)
    @Operation(
            summary = "Get all partner plays",
            description = "Returns all available partner plays"
    )
    public List<PartnerPlayResponse> getAllPartnerPlays() {

        return partnerPlayService.getAll();
    }

    @GetMapping(path = "/{name}")
    @ResponseStatus(HttpStatus.OK)
    @Operation(
            summary = "Get partner play by name",
            description = "Returns a single partner play"
    )
    public PartnerPlayResponse getPartnerPlay(
            @PathVariable String name) {

        return partnerPlayService.getById(name);
    }

    @PostMapping(version = "1")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(
            summary = "Create partner play",
            description = "Creates a new partner play"
    )
    public PartnerPlayResponse createPartnerPlay(
            @RequestBody CreatePartnerPlayRequest request) {

        return partnerPlayService.create(request);
    }

    @PutMapping(path = "/{name}")
    @ResponseStatus(HttpStatus.OK)
    @Operation(
            summary = "Update partner play",
            description = "Updates an existing partner play"
    )
    public PartnerPlayResponse updatePartnerPlay(
            @PathVariable String name,
            @RequestBody UpdatePartnerPlayRequest request) {

        return partnerPlayService.update(
                name,
                request
        );
    }

    @PatchMapping("/{name}")
    public PartnerPlayResponse patchPartnerPlay(
            @PathVariable String name,
            @RequestBody PatchPartnerPlayRequest request
    ) {
        return partnerPlayService.patchPartnerPlay(name, request);
    }

    @PatchMapping(path = "/{name}/status")
    @ResponseStatus(HttpStatus.OK)
    @Operation(
            summary = "Change partner play status",
            description = "Updates the status of a partner play"
    )
    public PartnerPlayResponse changePartnerPlayStatus(
            @PathVariable String name,
            @RequestBody ChangePartnerPlayStatusRequest request) {

        return partnerPlayService.changeStatus(
                name,
                request
        );
    }

    @DeleteMapping(path = "/{name}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(
            summary = "Delete partner play",
            description = "Deletes a partner play"
    )
    public void deletePartnerPlay(@PathVariable String name) {

        partnerPlayService.delete(name);
    }
}
