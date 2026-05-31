package com.botai.application.agenda.usecase.business;

import com.botai.application.agenda.dto.PublicCompanyResponse;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ListPublicCompanyUseCaseTest {

    @Mock
    private BusinessRepository businessRepository;

    @InjectMocks
    private ListPublicCompanyUseCase useCase;

    @Test
    void execute_returnsBranchesForCompanySlug() {
        UUID id1 = UUID.randomUUID();
        UUID id2 = UUID.randomUUID();
        Business cordon = new Business(
                id1, "t1", "Felito Barber Studio (Cordón)",
                "José Enrique Rodó 1969, Montevideo", null, List.of(), true,
                null, "#111111", null, null, null, null, null,
                "felito-barber-cordon-abc12345", "felitobarber", null, null, null, null);
        Business punta = new Business(
                id2, "t1", "Felito Barber Studio (Punta Carretas)",
                "Luis franzini 938, Montevideo", null, List.of(), true,
                null, "#111111", null, null, null, null, null,
                "felito-barber-punta-def67890", "felitobarber", null, null, null, null);

        when(businessRepository.findAllActiveByCompanySlug("felitobarber"))
                .thenReturn(List.of(cordon, punta));

        PublicCompanyResponse response = useCase.execute("felitobarber");

        assertThat(response.companySlug()).isEqualTo("felitobarber");
        assertThat(response.brandName()).isEqualTo("Felito Barber Studio");
        assertThat(response.branches()).hasSize(2);
        assertThat(response.branches().get(0).descripcion()).contains("Rodó");
    }
}
