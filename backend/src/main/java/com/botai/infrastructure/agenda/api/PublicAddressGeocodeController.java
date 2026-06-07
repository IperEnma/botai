package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.AddressGeocodeResponse;
import com.botai.application.agenda.support.BusinessAddressSupport;
import com.botai.infrastructure.agenda.support.OpenStreetMapPreviewService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/agenda/public/address")
@Tag(name = "Agenda Public · Address", description = "Validación y geocodificación de direcciones")
public class PublicAddressGeocodeController {

    private final OpenStreetMapPreviewService mapPreviewService;

    public PublicAddressGeocodeController(OpenStreetMapPreviewService mapPreviewService) {
        this.mapPreviewService = mapPreviewService;
    }

    @GetMapping("/geocode")
    @Operation(summary = "Geocodifica una dirección (exacta, calle o barrio/ciudad)")
    public AddressGeocodeResponse geocode(@RequestParam("address") String address) {
        String formatError = BusinessAddressSupport.formatErrorMessage(address);
        if (formatError != null) {
            throw new IllegalArgumentException(formatError);
        }
        return mapPreviewService.lookupAddressResponse(address.trim());
    }
}
