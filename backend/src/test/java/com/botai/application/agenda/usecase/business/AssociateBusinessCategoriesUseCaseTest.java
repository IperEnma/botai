package com.botai.application.agenda.usecase.business;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.CategoryNotFoundException;
import com.botai.domain.agenda.model.Category;
import com.botai.domain.agenda.repository.BusinessCategoryRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.CategoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AssociateBusinessCategoriesUseCaseTest {

    private BusinessRepository businessRepo;
    private CategoryRepository categoryRepo;
    private BusinessCategoryRepository businessCategoryRepo;
    private AssociateBusinessCategoriesUseCase useCase;

    private static final String TENANT_ID = "tenant-1";
    private static final UUID BUSINESS_ID = UUID.randomUUID();
    private static final UUID CAT_1 = UUID.randomUUID();
    private static final UUID CAT_2 = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        businessRepo = mock(BusinessRepository.class);
        categoryRepo = mock(CategoryRepository.class);
        businessCategoryRepo = mock(BusinessCategoryRepository.class);
        useCase = new AssociateBusinessCategoriesUseCase(
                businessRepo, categoryRepo, businessCategoryRepo);
    }

    @Test
    void asociaCategoriasValidasYReemplazaEnElRepo() {
        when(businessRepo.existsByIdAndTenantId(BUSINESS_ID, TENANT_ID)).thenReturn(true);
        when(categoryRepo.findById(CAT_1)).thenReturn(Optional.of(activeCategory(CAT_1, "manicure")));
        when(categoryRepo.findById(CAT_2)).thenReturn(Optional.of(activeCategory(CAT_2, "peluqueria")));

        List<UUID> ids = List.of(CAT_1, CAT_2);
        useCase.execute(TENANT_ID, BUSINESS_ID, ids);

        verify(businessCategoryRepo).replaceCategories(eq(BUSINESS_ID), eq(ids));
    }

    @Test
    void lanzaBusinessNotFoundSiElNegocioNoPerteneceAlTenant() {
        when(businessRepo.existsByIdAndTenantId(BUSINESS_ID, TENANT_ID)).thenReturn(false);

        assertThrows(
                BusinessNotFoundException.class,
                () -> useCase.execute(TENANT_ID, BUSINESS_ID, List.of(CAT_1)),
                "Si el negocio no existe en el tenant, debe fallar con BusinessNotFoundException"
        );
        verify(businessCategoryRepo, never()).replaceCategories(eq(BUSINESS_ID), anyList());
    }

    @Test
    void lanzaCategoryNotFoundSiAlgunaCategoriaNoExiste() {
        when(businessRepo.existsByIdAndTenantId(BUSINESS_ID, TENANT_ID)).thenReturn(true);
        when(categoryRepo.findById(CAT_1)).thenReturn(Optional.of(activeCategory(CAT_1, "manicure")));
        when(categoryRepo.findById(CAT_2)).thenReturn(Optional.empty());

        assertThrows(
                CategoryNotFoundException.class,
                () -> useCase.execute(TENANT_ID, BUSINESS_ID, List.of(CAT_1, CAT_2)),
                "Si alguna categoría no existe, debe abortar antes de asociar"
        );
        verify(businessCategoryRepo, never()).replaceCategories(eq(BUSINESS_ID), anyList());
    }

    @Test
    void lanzaIllegalArgumentSiAlgunaCategoriaEstaInactiva() {
        when(businessRepo.existsByIdAndTenantId(BUSINESS_ID, TENANT_ID)).thenReturn(true);
        when(categoryRepo.findById(CAT_1)).thenReturn(Optional.of(inactiveCategory(CAT_1, "pedicure")));

        assertThrows(
                IllegalArgumentException.class,
                () -> useCase.execute(TENANT_ID, BUSINESS_ID, List.of(CAT_1)),
                "No se puede asociar una categoría inactiva a un negocio"
        );
        verify(businessCategoryRepo, never()).replaceCategories(eq(BUSINESS_ID), anyList());
    }

    @Test
    void lanzaIllegalArgumentSiLaListaEsNull() {
        when(businessRepo.existsByIdAndTenantId(BUSINESS_ID, TENANT_ID)).thenReturn(true);

        assertThrows(
                IllegalArgumentException.class,
                () -> useCase.execute(TENANT_ID, BUSINESS_ID, null)
        );
    }

    private Category activeCategory(UUID id, String slug) {
        return new Category(id, slug, slug, null, List.of(), true, null, null);
    }

    private Category inactiveCategory(UUID id, String slug) {
        return new Category(id, slug, slug, null, List.of(), false, null, null);
    }
}
