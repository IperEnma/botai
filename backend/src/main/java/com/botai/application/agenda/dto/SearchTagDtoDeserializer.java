package com.botai.application.agenda.dto;

import com.botai.domain.agenda.model.SearchTag;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;
import com.fasterxml.jackson.databind.JsonNode;

import java.io.IOException;

/** Deserializa {@code {"value":"x","type":"profile"}}. */
public class SearchTagDtoDeserializer extends JsonDeserializer<SearchTagDto> {

    @Override
    public SearchTagDto deserialize(JsonParser p, DeserializationContext ctxt) throws IOException {
        JsonNode node = p.getCodec().readTree(p);
        if (!node.isObject()) {
            throw ctxt.weirdStringException(node.toString(), SearchTagDto.class,
                    "expected object with value and type");
        }
        String value = node.path("value").asText(null);
        if (value == null || value.isBlank()) {
            throw ctxt.weirdStringException(node.toString(), SearchTagDto.class, "value is required");
        }
        String type = node.path("type").asText(SearchTag.TYPE_PROFILE);
        return new SearchTagDto(value, type);
    }
}
