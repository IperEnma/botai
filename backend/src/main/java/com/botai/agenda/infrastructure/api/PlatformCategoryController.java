package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.CategoryResponse;
import com.botai.agenda.application.dto.CreateCategoryRequest;
import com.botai.agenda.application.dto.MergeSynonymsRequest;
import com.botai.agenda.application.dto.UpdateCategoryRequest;
import com.botai.agenda.application.mapper.CategoryDtoMapper;
import com.botai.agenda.application.usecase.category.CreateCategoryUseCase;
import com.botai.agenda.application.usecase.category.DeleteCategoryUseCase;
import com.botai.agenda.application.usecase.category.ListPublicCategoriesUseCase;
import com.botai.agenda.application.usecase.category.MergeCategorySynonymsUseCase;
import com.botai.agenda.application.usecase.category.UpdateCategoryUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * CRUD del catálogo global de categorías. Destinado a admins de plataforma.
 *
 * <p>Nota: Sprint 1 NO configura seguridad. La restricción {@code PLATFORM_ADMIN}
 * se añadirá cuando exista Spring Security común.</p>
 */
@RestController
@RequestMapping("/api/agenda/platform/categories")
@Tag(name = "Agenda Platform", description = "Catálogo global de categorías")
@Validated
public class PlatformCategoryController {

    private final ListPublicCategoriesUseCase listCategories;
    private final CreateCategoryUseCase createCategory;
    private final UpdateCategoryUseCase updateCategory;
    private final DeleteCategoryUseCase deleteCategory;
    private final MergeCategorySynonymsUseCase mergeSynonyms;

    public PlatformCategoryController(ListPublicCategoriesUseCase listCategories,
                                      CreateCategoryUseCase createCategory,
                                      UpdateCategoryUseCase updateCategory,
                                      DeleteCategoryUseCase deleteCategory,
                                      MergeCategorySynonymsUseCase mergeSynonyms) {
        this.listCategories = listCategories;
        this.createCategory = createCategory;
        this.updateCategory = updateCategory;
        this.deleteCategory = deleteCategory;
        this.mergeSynonyms = mergeSynonyms;
    }

    @GetMapping
    @Operation(summary = "Lista categorías (incluye inactivas si includeInactive=true)")
    public List<CategoryResponse> list(
            @RequestParam(value = "includeInactive", defaultValue = "false") boolean includeInactive) {
        var categories = includeInactive ? listCategories.listAll() : listCategories.listActive();
        return categories.stream().map(CategoryDtoMapper::toResponse).toList();
    }

    @PostMapping
    @Operation(summary = "Crea una categoría global")
    public ResponseEntity<CategoryResponse> create(@Valid @RequestBody CreateCategoryRequest request) {
        var created = createCategory.execute(
                request.nombre(),
                request.slug(),
                request.icono(),
                request.synonyms()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(CategoryDtoMapper.toResponse(created));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Actualiza una categoría")
    public CategoryResponse update(@PathVariable("id") UUID id,
                                   @Valid @RequestBody UpdateCategoryRequest request) {
        var updated = updateCategory.execute(
                id,
                request.nombre(),
                request.icono(),
                request.synonyms(),
                request.activo()
        );
        return CategoryDtoMapper.toResponse(updated);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Elimina una categoría (falla si tiene negocios asociados)")
    public ResponseEntity<Void> delete(@PathVariable("id") UUID id) {
        deleteCategory.execute(id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}/synonyms")
    @Operation(summary = "Fusiona nuevos sinónimos (unión) con los existentes")
    public CategoryResponse mergeSynonyms(@PathVariable("id") UUID id,
                                          @Valid @RequestBody MergeSynonymsRequest request) {
        return CategoryDtoMapper.toResponse(mergeSynonyms.execute(id, request.synonyms()));
    }
}
