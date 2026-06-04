---
name: agenda-style-check
description: Auditoría rápida de consistencia visual de uno o varios archivos Flutter del módulo Agenda. Verifica tokens de color, tipografía, responsive layout, navegación y patrones Riverpod contra el design system de landing_screen.dart. Solo lectura — reporta, no edita.
metadata:
  author: botai
  version: "1.0"
  scope: [frontend]
  auto_invoke: "Reviewing Agenda Flutter UI against the design system"
---

# agenda-style-check

Audita archivos Flutter del módulo Agenda contra el design system establecido. Devuelve un reporte con violaciones clasificadas por severidad.

## Cuándo usar esta skill

- "Revisá si la pantalla de búsqueda respeta los estilos"
- "Chequea todos los screens de la carpeta public/"
- Antes de hacer PR de cambios de UI.

## Qué chequea

### 1. Tokens de color
- ❌ Colores hardcodeados que no son tokens: `Color(0xFFABCDEF)` que no está definido como `_k*`.
- ❌ `Colors.blue`, `Colors.red`, `Colors.green` sueltos (excepto `Colors.white`, `Colors.black`, `Colors.transparent`).
- ❌ `Theme.of(context).primaryColor` en lugar de `_kPrimary`.
- ✅ Uso de `_kPrimary`, `_kPrimaryDark`, `_kAccent`, `_kDark`, `_kSurface`, `_kTextMuted`.

### 2. Tipografía
- ❌ `TextStyle(fontFamily: 'Poppins')` hardcodeado.
- ❌ `Text(...)` sin estilo de fuente en textos de heading/cuerpo visibles.
- ✅ `GoogleFonts.poppins(...)` para todo texto que no sea un placeholder/debug.
- ✅ Jerarquía tipográfica clara: heading grande (`fontSize >= 24`), cuerpo (`14-16`), muted (`_kTextMuted`).

### 3. Layout responsivo
- ❌ Ausencia total de check `_kBreakpoint` en pantallas que tienen secciones horizontales.
- ❌ `MediaQuery.of(context).size` en lugar de `MediaQuery.sizeOf(context)` (rebuilds innecesarios).
- ✅ `ConstrainedBox(constraints: BoxConstraints(maxWidth: _kMaxWidth))` en contenido principal.
- ✅ `isWide` / `isMobile` derivado de `_kBreakpoint = 800.0`.

### 4. Cards y contenedores
- ❌ `borderRadius: BorderRadius.circular(8)` o valores distintos de `16` sin justificación.
- ❌ `BoxShadow` con opacidad > 0.12 o `blurRadius` > 24 (se ve pesado).
- ✅ `borderRadius: BorderRadius.circular(16)`.
- ✅ `BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: Offset(0, 4))`.

### 5. Navegación
- ❌ `Navigator.push(...)` / `Navigator.of(context).push(...)`.
- ❌ `MaterialPageRoute(...)` suelto.
- ✅ `context.go(...)` o `context.push(...)` de go_router.

### 6. Gestión de estado
- ❌ `setState(...)` para datos que vienen de una API.
- ❌ `FutureBuilder` sin loading/error states explícitos.
- ✅ `ref.watch(someProvider)` + `.when(data:, loading:, error:)`.
- ✅ `ConsumerWidget` o `ConsumerStatefulWidget` para pantallas con datos remotos.

### 7. AppBar / Scaffold
- ❌ `AppBar` sin `backgroundColor` explícito en pantallas de agenda (deja el default de Material).
- ✅ `AppBar(backgroundColor: _kPrimary, foregroundColor: Colors.white, elevation: 0)`.
- ✅ `Scaffold(backgroundColor: _kSurface)` (no `Colors.white` directo).

## Formato del reporte

```
## Style Audit — <nombre del archivo o carpeta>

### Bloqueantes (rompen la consistencia visual)
- [archivo.dart:línea] Descripción

### Warnings (degradan la UX pero no rompen)
- [archivo.dart:línea] Descripción

### Sugerencias
- Descripción

### Checklist
- [x] Tokens _k* definidos
- [x] GoogleFonts.poppins en uso
- [ ] Layout responsivo (falta _kBreakpoint)
- [x] Navegación con go_router
- [x] Estado con Riverpod

### Veredicto
APTO / NECESITA CAMBIOS / BLOQUEADO
```

## Cómo ejecutar

1. Leer los archivos indicados por el usuario.
2. Correr `dart analyze <archivo>` para capturar lint warnings.
3. Buscar patrones problemáticos con Grep.
4. Emitir el reporte.

No modificar ningún archivo — solo reportar.
