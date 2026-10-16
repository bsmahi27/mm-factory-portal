package com.mmfactory.common.ingestion.internal;

import org.dhatim.fastexcel.reader.ReadableWorkbook;
import org.dhatim.fastexcel.reader.Row;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Component
public class ExcelParser {

    private static final ColumnDefinition COUNTRY = ColumnDefinition.required(0, "country");
    private static final ColumnDefinition ACCOUNT_NAME = ColumnDefinition.required(1, "account name", "account", "account_name");
    private static final ColumnDefinition SECTOR = ColumnDefinition.required(2, "sector", "industry");
    private static final ColumnDefinition TRIGGER_CATEGORY = ColumnDefinition.required(3, "trigger category", "category", "signal category", "signal_category");
    private static final ColumnDefinition RELEVANCE = ColumnDefinition.required(4, "relevance", "priority");
    private static final ColumnDefinition NEWS_HEADLINE = ColumnDefinition.required(5, "news headline", "headline", "title");
    private static final ColumnDefinition NEWS_SUMMARY = ColumnDefinition.required(6, "news summary", "summary", "description");
    private static final ColumnDefinition SOURCE_NAME = ColumnDefinition.required(7, "source name", "source", "publisher");
    private static final ColumnDefinition SOURCE_URL = ColumnDefinition.required(8, "source url", "url", "link");
    private static final ColumnDefinition PUBLISHED_DATE = ColumnDefinition.required(9, "published date", "date", "publication date");
    private static final ColumnDefinition RECOMMENDED_ACTION = ColumnDefinition.required(10, "recommended action", "action");
    private static final ColumnDefinition RECOMMENDED_AGENT = ColumnDefinition.required(11, "recommended agent", "agent");
    private static final ColumnDefinition RESEARCHER = ColumnDefinition.required(12, "researcher", "owner");
    private static final ColumnDefinition VALIDATION_STATUS = ColumnDefinition.required(13, "validation status", "status");
    private static final ColumnDefinition REVIEWER_COMMENTS = ColumnDefinition.required(14, "reviewer comments", "comments");

    public List<TriggersRadarIngestion> parse(InputStream inputStream, UUID triggerId) throws IOException {
        List<TriggersRadarIngestion> records = new ArrayList<>();

        try (var workbook = new ReadableWorkbook(inputStream)) {
            var sheet = workbook.getFirstSheet();

            try (var rows = sheet.openStream()) {
                var iterator = rows.iterator();

                if (!iterator.hasNext()) {
                    return records;
                }

                var columnLayout = ColumnLayout.fromHeader(iterator.next());

                iterator.forEachRemaining(row -> {
                    if (isEmpty(row)) {
                        return;
                    }

                    var ingestionEntity = mapRow(triggerId, row, columnLayout);
                    records.add(ingestionEntity);

                });
            }
        }
        return records;
    }

    private TriggersRadarIngestion mapRow(
            UUID triggerId,
            Row row,
            ColumnLayout columnLayout) {

        var entity = new TriggersRadarIngestion();

        entity.setTriggerId(triggerId);
        entity.setCountry(getCell(row, columnLayout.country()).orElse(null));
        entity.setAccountName(getCell(row, columnLayout.accountName()).orElse(null));
        entity.setSector(getCell(row, columnLayout.sector()).orElse(null));
        entity.setTriggerCategory(getCell(row, columnLayout.triggerCategory()).orElse(null));
        entity.setRelevance(getCell(row, columnLayout.relevance()).orElse(null));
        entity.setNewsHeadline(getCell(row, columnLayout.newsHeadline()).orElse(null));
        entity.setNewsSummary(getCell(row, columnLayout.newsSummary()).orElse(null));
        entity.setSourceName(getCell(row, columnLayout.sourceName()).orElse(null));
        entity.setSourceUrl(getCell(row, columnLayout.sourceUrl()).orElse(null));
        entity.setPublishedDate(getDateCell(row, columnLayout.publishedDate()));
        entity.setRecommendedAction(getCell(row, columnLayout.recommendedAction()).orElse(null));
        entity.setRecommendedAgent(getCell(row, columnLayout.recommendedAgent()).orElse(null));
        entity.setResearcher(getCell(row, columnLayout.researcher()).orElse(null));
        entity.setValidationStatus(getCell(row, columnLayout.validationStatus()).orElse(null));
        entity.setReviewerComments(getCell(row, columnLayout.reviewerComments()).orElse(null));

        return entity;
    }

    private Optional<String> getCell(Row row, int index) {
        if (index < 0) {
            return Optional.empty();
        }

        return row.getOptionalCell(index)
                .map(cell -> cell.getText() == null ? "" : cell.getText().trim())
                .filter(text -> !text.isBlank());
    }

    private static final List<DateTimeFormatter> DATE_FORMATS = List.of(
            DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.ENGLISH),
            DateTimeFormatter.ofPattern("dd-MMM-yyyy", Locale.ENGLISH),
            DateTimeFormatter.ofPattern("dd/MM/yyyy")
    );

    private LocalDate getDateCell(Row row, int index) {
        if (index < 0) {
            return null;
        }

        var cell = row.getOptionalCell(index).orElse(null);
        if (cell == null || cell.getText() == null || cell.getText().isBlank()) {
            return null;
        }

        try {
            LocalDateTime excelDate = cell.asDate();
            if (excelDate != null) {
                return excelDate.toLocalDate();
            }
        } catch (Exception ignored) {
        }

        String text = cell.getText().trim();
        if (text.matches("^-?\\d+(\\.\\d+)?$")) {
            try {
                return excelSerialDateToLocalDate(Double.parseDouble(text));
            } catch (NumberFormatException ignored) {
            }
        }

        for (DateTimeFormatter formatter : DATE_FORMATS) {
            try {
                return LocalDate.parse(text, formatter);
            } catch (Exception ignored) {
            }
        }

        throw new IllegalArgumentException("Invalid date: " + text);
    }

    private LocalDate excelSerialDateToLocalDate(double value) {
        int wholeDays = (int) Math.floor(value);
        int startYear = 1900;
        int dayAdjust = -1;

        if (wholeDays < 61) {
            dayAdjust = 0;
        }

        return LocalDate.of(startYear, 1, 1)
                .plusDays((long) wholeDays + dayAdjust - 1);
    }

    private boolean isEmpty(Row row) {
        return row.stream()
                .filter(cell -> cell != null && cell.getText() != null)
                .map(cell -> cell.getText().trim())
                .allMatch(String::isBlank);
    }

    private static Map<String, Integer> indexHeaders(Row row) {
        Map<String, Integer> headers = new LinkedHashMap<>();

        for (int index = 0; index < row.getCellCount(); index++) {
            String header = row.getOptionalCell(index)
                    .map(cell -> normalizeHeader(cell.getText()))
                    .filter(value -> !value.isBlank())
                    .orElse(null);

            if (header != null) {
                headers.putIfAbsent(header, index);
            }
        }

        return headers;
    }

    private static String normalizeHeader(String value) {
        if (value == null) {
            return "";
        }

        return value.toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", " ")
                .trim();
    }

    private record ColumnLayout(
            int country,
            int accountName,
            int sector,
            int triggerCategory,
            int relevance,
            int newsHeadline,
            int newsSummary,
            int sourceName,
            int sourceUrl,
            int publishedDate,
            int recommendedAction,
            int recommendedAgent,
            int researcher,
            int validationStatus,
            int reviewerComments
    ) {

        private static ColumnLayout fromHeader(Row headerRow) {
            Map<String, Integer> headers = indexHeaders(headerRow);

            return new ColumnLayout(
                    COUNTRY.resolve(headers),
                    ACCOUNT_NAME.resolve(headers),
                    SECTOR.resolve(headers),
                    TRIGGER_CATEGORY.resolve(headers),
                    RELEVANCE.resolve(headers),
                    NEWS_HEADLINE.resolve(headers),
                    NEWS_SUMMARY.resolve(headers),
                    SOURCE_NAME.resolve(headers),
                    SOURCE_URL.resolve(headers),
                    PUBLISHED_DATE.resolve(headers),
                    RECOMMENDED_ACTION.resolve(headers),
                    RECOMMENDED_AGENT.resolve(headers),
                    RESEARCHER.resolve(headers),
                    VALIDATION_STATUS.resolve(headers),
                    REVIEWER_COMMENTS.resolve(headers)
            );
        }
    }

    private record ColumnDefinition(int fallbackIndex, List<String> aliases) {

        private static ColumnDefinition required(int fallbackIndex, String... aliases) {
            return new ColumnDefinition(fallbackIndex, List.of(aliases));
        }

        private static ColumnDefinition optional(String... aliases) {
            return new ColumnDefinition(-1, List.of(aliases));
        }

        private int resolve(Map<String, Integer> headers) {
            for (String alias : aliases) {
                Integer resolvedIndex = headers.get(normalizeHeader(alias));
                if (resolvedIndex != null) {
                    return resolvedIndex;
                }
            }

            return fallbackIndex;
        }
    }

}
