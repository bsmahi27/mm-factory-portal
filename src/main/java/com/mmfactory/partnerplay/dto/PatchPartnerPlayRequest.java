package com.mmfactory.partnerplay.dto;

import org.jspecify.annotations.Nullable;

import java.util.List;

public record PatchPartnerPlayRequest(

        @Nullable String theme,

        @Nullable String valueProposition,

        @Nullable String ownerName,

        @Nullable List<String> eligibleCountryCodes

) {
}