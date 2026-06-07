package com.botai.application.agenda.dto;

import com.botai.domain.agenda.model.SearchTag;

import java.util.List;

public final class SearchTagDtoMapper {

    private SearchTagDtoMapper() {
    }

    public static List<SearchTag> toDomain(List<SearchTagDto> dtos) {
        if (dtos == null) {
            return null;
        }
        return dtos.stream().map(SearchTagDto::toDomain).toList();
    }
}
