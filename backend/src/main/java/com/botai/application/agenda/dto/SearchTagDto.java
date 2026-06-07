package com.botai.application.agenda.dto;

import com.botai.domain.agenda.model.SearchTag;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@JsonDeserialize(using = SearchTagDtoDeserializer.class)
public record SearchTagDto(
        @NotBlank @Size(max = 100) String value,
        @Size(max = 32) String type
) {
    public SearchTagDto {
        if (type == null || type.isBlank()) {
            type = SearchTag.TYPE_PROFILE;
        } else {
            type = type.trim().toLowerCase();
        }
        value = value.trim();
    }

    public static SearchTagDto fromDomain(SearchTag tag) {
        return new SearchTagDto(tag.value(), tag.type());
    }

    public SearchTag toDomain() {
        return new SearchTag(value, type);
    }
}
