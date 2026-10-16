package com.mmfactory.triggersradar.controller;

import com.mmfactory.common.config.ApiVersionConfig;
import com.mmfactory.common.ingestion.FileImportedEvent;
import com.mmfactory.common.ingestion.TriggersIngestionService;
import com.mmfactory.common.reporting.TriggersRadarModel;
import com.mmfactory.common.reporting.TriggersRadarService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

import java.io.InputStream;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(TriggersRadarController.class)
@Import({ApiVersionConfig.class, TriggersRadarControllerTest.TestConfig.class})
class TriggersRadarControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TriggersIngestionService triggersIngestionService;

    @Autowired
    private TriggersRadarService triggersRadarService;

    @BeforeEach
    void setUp() {
        Mockito.reset(triggersIngestionService, triggersRadarService);
    }

    @Test
    void uploadExcelDocumentReturnsAcceptedResponse() throws Exception {
        var triggerId = UUID.fromString("9d0f6e63-90ef-4dc1-87bd-3caec9933404");
        when(triggersIngestionService.importExcel(any(InputStream.class)))
                .thenReturn(new FileImportedEvent(triggerId, 2));

        var file = new MockMultipartFile(
                "file",
                "trigger-radar.xlsx",
                MediaType.APPLICATION_OCTET_STREAM_VALUE,
                "excel-content".getBytes()
        );

        mockMvc.perform(multipart("/api/v1/trigger-radars/upload").file(file))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.triggerId").value(triggerId.toString()))
                .andExpect(jsonPath("$.fileName").value("trigger-radar.xlsx"))
                .andExpect(jsonPath("$.importedRecordCount").value(2))
                .andExpect(jsonPath("$.status").value("UPLOAD_ACCEPTED"));
    }

    @Test
    void uploadExcelDocumentRejectsEmptyFile() throws Exception {
        var file = new MockMultipartFile(
                "file",
                "trigger-radar.xlsx",
                MediaType.APPLICATION_OCTET_STREAM_VALUE,
                new byte[0]
        );

        mockMvc.perform(multipart("/api/v1/trigger-radars/upload").file(file))
                .andExpect(status().isBadRequest());

        verifyNoInteractions(triggersIngestionService);
    }

    @Test
    void uploadExcelDocumentRejectsUnsupportedFileType() throws Exception {
        var file = new MockMultipartFile(
                "file",
                "trigger-radar.csv",
                MediaType.TEXT_PLAIN_VALUE,
                "country,account".getBytes()
        );

        mockMvc.perform(multipart("/api/v1/trigger-radars/upload").file(file))
                .andExpect(status().isBadRequest());

        verifyNoInteractions(triggersIngestionService);
    }

    @Test
    void listReturnsPagedRecords() throws Exception {
        var triggerId = UUID.fromString("9d0f6e63-90ef-4dc1-87bd-3caec9933404");
        var model = new TriggersRadarModel(1L, triggerId, "India", "Acme", null, null, null, null, null,
                null, null, null, null, null, null, null, null, null);
        when(triggersRadarService.findAll(any(), any()))
                .thenReturn(new PageImpl<>(List.of(model), PageRequest.of(0, 20), 1));

        mockMvc.perform(get("/api/v1/trigger-radars"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].accountName").value("Acme"))
                .andExpect(jsonPath("$.content[0].triggerId").value(triggerId.toString()))
                .andExpect(jsonPath("$.totalElements").value(1));
    }

    @Test
    void getByIdReturnsNotFoundWhenMissing() throws Exception {
        when(triggersRadarService.findById(99L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/v1/trigger-radars/99"))
                .andExpect(status().isNotFound());
    }

    @TestConfiguration
    static class TestConfig {

        @Bean
        TriggersRadarService reportingService() {
            return Mockito.mock(TriggersRadarService.class);
        }

        @Bean
        TriggersIngestionService ingestionService() {
            return Mockito.mock(TriggersIngestionService.class);
        }
    }
}

