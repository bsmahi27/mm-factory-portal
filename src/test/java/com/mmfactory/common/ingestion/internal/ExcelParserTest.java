package com.mmfactory.common.ingestion.internal;

import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class ExcelParserTest {

    private final ExcelParser excelParser = new ExcelParser();

    @Test
    void parseUsesHeaderNamesWhenOptionalColumnsShiftTheDatePosition() throws IOException {
        var workbookBytes = createWorkbook(
                textCells(
                        "Trigger ID",
                        "Country",
                        "Account Name",
                        "Sector",
                        "Trigger Category",
                        "Relevance",
                        "News Headline",
                        "News Summary",
                        "Source Name",
                        "Source Type",
                        "Source Url",
                        "Published Date",
                        "Recommended Action",
                        "Recommended Agent",
                        "Researcher",
                        "Validation Status",
                        "Reviewer Comments"
                ),
                textCells(
                        "",
                        "Germany",
                        "HORNBACH Holding AG & Co. KGaA",
                        "Retail",
                        "Strategy Updates",
                        "High",
                        "HORNBACH plans new store openings in Germany and Europe",
                        "HORNBACH said it will open six German locations in spring 2027 and pursue further openings across Europe, moving toward 200 DIY megastores.",
                        "HORNBACH Newsroom",
                        "Newsroom",
                        "https://newsroom.hornbach.de/?site=de",
                        "18 Sep 2026",
                        "",
                        "",
                        "Samyak Gaur",
                        "Draft",
                        ""
                )
        );

        var records = excelParser.parse(
                new ByteArrayInputStream(workbookBytes),
                UUID.fromString("59b6a08e-aae9-4f8c-a8f6-b085b77c6b8d")
        );

        assertEquals(1, records.size());

        var record = records.getFirst();
        assertEquals("Germany", record.getCountry());
        assertEquals("HORNBACH Holding AG & Co. KGaA", record.getAccountName());
        assertEquals("Retail", record.getSector());
        assertEquals("Strategy Updates", record.getTriggerCategory());
        assertEquals("High", record.getRelevance());
        assertEquals("HORNBACH Newsroom", record.getSourceName());
        assertEquals("https://newsroom.hornbach.de/?site=de", record.getSourceUrl());
        assertEquals(LocalDate.of(2026, 9, 18), record.getPublishedDate());
        assertNull(record.getRecommendedAction());
        assertNull(record.getRecommendedAgent());
        assertEquals("Samyak Gaur", record.getResearcher());
        assertEquals("Draft", record.getValidationStatus());
        assertNull(record.getReviewerComments());
    }

    @Test
    void parseFallsBackToDefaultPositionsWhenHeadersAreLegacy() throws IOException {
        var workbookBytes = createWorkbook(
                textCells(
                        "Col1", "Col2", "Col3", "Col4", "Col5", "Col6", "Col7", "Col8", "Col9", "Col10",
                        "Col11", "Col12", "Col13", "Col14", "Col15"
                ),
                textCells(
                        "Germany",
                        "HORNBACH Holding AG & Co. KGaA",
                        "Retail",
                        "Strategy Updates",
                        "High",
                        "HORNBACH plans new store openings in Germany and Europe",
                        "HORNBACH said it will open six German locations in spring 2027 and pursue further openings across Europe, moving toward 200 DIY megastores.",
                        "HORNBACH Newsroom",
                        "https://newsroom.hornbach.de/?site=de",
                        "18 Sep 2026",
                        "",
                        "",
                        "Samyak Gaur",
                        "Draft",
                        ""
                )
        );

        var records = excelParser.parse(
                new ByteArrayInputStream(workbookBytes),
                UUID.fromString("9cb67bfa-8cb7-4db1-a393-55b4f72d44e3")
        );

        assertEquals(1, records.size());
        assertEquals(LocalDate.of(2026, 9, 18), records.getFirst().getPublishedDate());
        assertEquals("https://newsroom.hornbach.de/?site=de", records.getFirst().getSourceUrl());
    }

    @Test
    void parseSupportsNumericExcelSerialDates() throws IOException {
        var workbookBytes = createWorkbook(
                textCells(
                        "Country",
                        "Account Name",
                        "Sector",
                        "Trigger Category",
                        "Relevance",
                        "News Headline",
                        "News Summary",
                        "Source Name",
                        "Source Url",
                        "Published Date",
                        "Recommended Action",
                        "Recommended Agent",
                        "Researcher",
                        "Validation Status",
                        "Reviewer Comments"
                ),
                List.of(
                        CellValue.text("Germany"),
                        CellValue.text("HORNBACH Holding AG & Co. KGaA"),
                        CellValue.text("Retail"),
                        CellValue.text("Strategy Updates"),
                        CellValue.text("High"),
                        CellValue.text("HORNBACH plans new store openings in Germany and Europe"),
                        CellValue.text("HORNBACH said it will open six German locations in spring 2027 and pursue further openings across Europe, moving toward 200 DIY megastores."),
                        CellValue.text("HORNBACH Newsroom"),
                        CellValue.text("https://newsroom.hornbach.de/?site=de"),
                        CellValue.number("46283"),
                        CellValue.text(""),
                        CellValue.text(""),
                        CellValue.text("Samyak Gaur"),
                        CellValue.text("Draft"),
                        CellValue.text("")
                )
        );

        var records = excelParser.parse(
                new ByteArrayInputStream(workbookBytes),
                UUID.fromString("ec8db57a-f39c-47f7-a0da-dd6af17523c3")
        );

        assertEquals(1, records.size());
        assertEquals(LocalDate.of(2026, 9, 18), records.getFirst().getPublishedDate());
    }

    private byte[] createWorkbook(List<CellValue> headers, List<CellValue> values) throws IOException {
        try (var outputStream = new ByteArrayOutputStream();
             var zipOutputStream = new ZipOutputStream(outputStream)) {

            writeZipEntry(zipOutputStream, "[Content_Types].xml", """
                    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                      <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                      <Default Extension="xml" ContentType="application/xml"/>
                      <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
                      <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
                    </Types>
                    """);
            writeZipEntry(zipOutputStream, "_rels/.rels", """
                    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                      <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
                    </Relationships>
                    """);
            writeZipEntry(zipOutputStream, "xl/workbook.xml", """
                    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                    <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
                              xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
                      <sheets>
                        <sheet name="Triggers" sheetId="1" r:id="rId1"/>
                      </sheets>
                    </workbook>
                    """);
            writeZipEntry(zipOutputStream, "xl/_rels/workbook.xml.rels", """
                    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                      <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
                    </Relationships>
                    """);
            writeZipEntry(zipOutputStream, "xl/worksheets/sheet1.xml", buildWorksheet(headers, values));

            zipOutputStream.finish();
            return outputStream.toByteArray();
        }
    }

    private void writeZipEntry(ZipOutputStream zipOutputStream, String name, String content) throws IOException {
        zipOutputStream.putNextEntry(new ZipEntry(name));
        zipOutputStream.write(content.stripIndent().getBytes());
        zipOutputStream.closeEntry();
    }

    private String buildWorksheet(List<CellValue> headers, List<CellValue> values) {
        return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
                "<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">" +
                "<sheetData>" +
                buildRow(1, headers) +
                buildRow(2, values) +
                "</sheetData>" +
                "</worksheet>";
    }

    private String buildRow(int rowNumber, List<CellValue> values) {
        StringBuilder row = new StringBuilder();
        row.append("<row r=\"").append(rowNumber).append("\">");

        for (int column = 0; column < values.size(); column++) {
            row.append(values.get(column).toCellXml(columnName(column) + rowNumber, this::escape));
        }

        row.append("</row>");
        return row.toString();
    }

    private String columnName(int index) {
        StringBuilder result = new StringBuilder();
        int value = index + 1;

        while (value > 0) {
            int remainder = (value - 1) % 26;
            result.insert(0, (char) ('A' + remainder));
            value = (value - 1) / 26;
        }

        return result.toString();
    }

    private String escape(String value) {
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&apos;");
    }

    private List<CellValue> textCells(String... values) {
        return java.util.Arrays.stream(values)
                .map(CellValue::text)
                .toList();
    }

    private record CellValue(String value, boolean numeric) {

        private static CellValue text(String value) {
            return new CellValue(value, false);
        }

        private static CellValue number(String value) {
            return new CellValue(value, true);
        }

        private String toCellXml(String address, java.util.function.Function<String, String> escaper) {
            if (numeric && !value.isBlank()) {
                return "<c r=\"" + address + "\"><v>" + value + "</v></c>";
            }

            return "<c r=\"" + address + "\" t=\"inlineStr\"><is><t>" + escaper.apply(value) + "</t></is></c>";
        }
    }
}

