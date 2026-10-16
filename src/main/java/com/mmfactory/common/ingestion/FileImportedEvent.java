package com.mmfactory.common.ingestion;

import java.util.UUID;

public record FileImportedEvent(UUID triggerId, long recordCount) {}

