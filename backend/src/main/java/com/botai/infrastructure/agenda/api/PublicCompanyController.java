package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.PublicCompanyResponse;
import com.botai.application.agenda.usecase.business.ListPublicCompanyUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/agenda/public/companies")
@Tag(name = "Agenda Public · Company", description = "Marca y sucursales para /reservar?company=")
public class PublicCompanyController {

    private final ListPublicCompanyUseCase listPublicCompany;

    public PublicCompanyController(ListPublicCompanyUseCase listPublicCompany) {
        this.listPublicCompany = listPublicCompany;
    }

    @GetMapping("/{companySlug}")
    @Operation(summary = "Marca pública y sucursales activas por company slug")
    public PublicCompanyResponse company(@PathVariable("companySlug") String companySlug) {
        return listPublicCompany.execute(companySlug);
    }
}
