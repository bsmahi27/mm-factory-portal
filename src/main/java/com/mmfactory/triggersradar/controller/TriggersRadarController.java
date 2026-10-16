package com.mmfactory.triggersradar.controller;

import com.mmfactory.common.ingestion.TriggersIngestionService;
import com.mmfactory.common.reporting.TriggersRadarService;
import com.mmfactory.common.reporting.TriggersRadarModel;
import com.mmfactory.common.util.AppConstants;
import com.mmfactory.common.util.AppUtils;
import com.mmfactory.triggersradar.dto.TriggersRadarResponse;
import com.mmfactory.triggersradar.dto.TriggersRadarUploadResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.util.UUID;

@RestController
@RequestMapping(value = "/trigger-radars", version = "1")
@RequiredArgsConstructor
@Tag(
        name = "Triggers Radar",
        description = "Trigger radar APIs"
)
public class TriggersRadarController {

    private final TriggersIngestionService triggersIngestionService;
    private final TriggersRadarService triggersRadarService;

    @GetMapping
    @Operation(
            summary = "List trigger radar records",
            description = "Returns processed trigger radar records in upload order, optionally filtered by triggerId, with paging."
    )
    public TriggersRadarResponse getAllTriggerRadarDetails(
            @RequestParam(value = "triggerId", required = false) UUID triggerId,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "20") int size) {

        var result = triggersRadarService.findAll(triggerId, PageRequest.of(Math.max(page, 0), Math.clamp(size, 1, 200),
                Sort.by(Sort.Direction.ASC, "id")));

        return new TriggersRadarResponse(
                result.getContent(),
                result.getNumber(),
                result.getSize(),
                result.getTotalElements(),
                result.getTotalPages());
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a trigger radar record by id")
    public TriggersRadarModel getByTriggerId(@PathVariable Long id) {
        return triggersRadarService.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Trigger radar record not found: " + id));
    }

    @PostMapping(path = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.ACCEPTED)
    @Operation(
            summary = "Upload trigger radar Excel document",
            description = "Uploads a .xlsx document, imports trigger rows, and starts read-model processing."
    )
    public TriggersRadarUploadResponse uploadExcelDocument(
            @RequestParam("file") MultipartFile file) {

        AppUtils.validateFile(file);

        try (var inputStream = file.getInputStream()) {
            var importedEvent = triggersIngestionService.importExcel(inputStream);

            return new TriggersRadarUploadResponse(
                    importedEvent.triggerId(),
                    file.getOriginalFilename(),
                    importedEvent.recordCount(),
                    AppConstants.SUCCESS_STATUS
            );
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (IOException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Unable to read the uploaded Excel document.", exception);
        }
    }


}

