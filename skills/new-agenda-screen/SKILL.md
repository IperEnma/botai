---
name: new-agenda-screen
description: Scaffolding de una nueva pantalla Flutter del módulo Agenda. Genera el archivo con los tokens de diseño correctos, estructura Riverpod, responsive layout y registra la ruta en router.dart. Úsese cuando el usuario pide "crear/agregar la pantalla de X".
metadata:
  author: botai
  version: "1.0"
  scope: [frontend]
  auto_invoke: "Creating a new Agenda Flutter screen"
---

# new-agenda-screen

Genera una pantalla Flutter completa para el módulo Agenda siguiendo el design system establecido en `landing_screen.dart`.

## Cuándo usar esta skill

- "Creá la pantalla de perfil público del negocio"
- "Agregá una pantalla de confirmación de reserva"
- "Necesitamos la vista de mis favoritos"

No usar si:
- Es solo un widget reutilizable sin ruta propia (crear directamente en `lib/widgets/agenda/`).
- La pantalla ya existe y solo hay que modificarla.

## Pre-requisitos que la skill confirma antes de empezar

1. Confirmar con el usuario el **nombre** de la pantalla (ej. `BookingConfirmationScreen`) y la **ruta** GoRouter (ej. `/agenda/bookings/:id/confirm`).
2. Identificar si la pantalla es pública (`public/`), tenant (`tenant/`), plataforma (`platform/`) o usuario (`me/`).
3. Revisar `router.dart` para verificar que la ruta no existe ya.

## Design tokens obligatorios

Toda pantalla nueva DEBE usar estos tokens (definir como constantes `_k*` al tope del archivo, fuera de cualquier clase):

```dart
const _kPrimary    = Color(0xFF6366F1);   // indigo-500
const _kPrimaryDark= Color(0xFF4F46E5);   // indigo-600
const _kAccent     = Color(0xFF8B5CF6);   // violet-500
const _kDark       = Color(0xFF0F172A);   // slate-900
const _kSurface    = Color(0xFFF8FAFC);   // slate-50
const _kTextMuted  = Color(0xFF64748B);   // slate-500
const _kBreakpoint = 800.0;
const _kMaxWidth   = 1200.0;
```

Tipografía: `GoogleFonts.poppins(...)` — nunca `TextStyle(fontFamily: 'Poppins')` a mano.

Cards: `borderRadius: BorderRadius.circular(16)` + `BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: Offset(0, 4))`.

## Estructura del scaffold generado

```dart
// Imports: flutter, go_router, flutter_riverpod, google_fonts, modelos/providers agenda

// Tokens de diseño (constantes privadas _k*)
const _kPrimary = Color(0xFF6366F1);
// ...

// Widget principal (StatelessWidget o ConsumerStatefulWidget según necesite)
class FooScreen extends ConsumerWidget {
  const FooScreen({super.key, required this.param});
  final String param;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _kBreakpoint;

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: _buildAppBar(context),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxWidth),
          child: isWide ? _WideLayout(...) : _NarrowLayout(...),
        ),
      ),
    );
  }
}

// Subwidgets privados (_WideLayout, _NarrowLayout, etc.)
```

## Pasos

### Paso 1 — Crear el archivo
Ruta del archivo: `frontend/lib/features/agenda/<scope>/<nombre_snake_case>_screen.dart`

Generar el scaffold completo con:
- Imports necesarios (riverpod, go_router, google_fonts, modelos).
- Tokens `_k*` al tope.
- Widget principal con `WidgetRef ref` si usa providers.
- Layout responsivo con `MediaQuery.sizeOf(context).width >= _kBreakpoint`.
- AppBar con `backgroundColor: _kPrimary, foregroundColor: Colors.white` si aplica.
- Sección de contenido con `ConstrainedBox(constraints: BoxConstraints(maxWidth: _kMaxWidth))`.

### Paso 2 — Registrar la ruta en router.dart
Agregar el `GoRoute` correspondiente en `frontend/lib/core/router.dart`.
- Importar la nueva screen.
- Ubicar el bloque correcto (public / tenant / platform / me).
- Extraer path parameters con `state.pathParameters['x']!`.

### Paso 3 — Crear provider si hace falta
Si la pantalla consume datos nuevos, agregar el `FutureProvider` en:
`frontend/lib/providers/agenda/<scope>/<nombre_provider>.dart`

### Paso 4 — Verificar
```bash
dart analyze lib/features/agenda/<scope>/<nombre>_screen.dart lib/core/router.dart
```
Corregir todos los warnings antes de reportar al usuario.

### Paso 5 — Reporte al usuario
- Ruta del archivo creado.
- URL de acceso: `http://localhost:<port>/#/<ruta>`.
- Qué providers/modelos usa.
- Próximos pasos (conectar API, agregar tests de widget).

## Reglas que nunca se rompen

- Ningún color hardcodeado que no sea un token `_k*` o `Colors.white` / `Colors.black`.
- Ningún `TextStyle(fontFamily: 'Poppins')` a mano — siempre `GoogleFonts.poppins(...)`.
- Toda navegación con `context.go()` o `context.push()` de go_router — nunca `Navigator.push`.
- Estado de servidor con Riverpod providers — nunca `setState` para datos remotos.
- Layout responsivo siempre: al menos un check `isWide` con `_kBreakpoint`.
- `dart analyze` debe pasar limpio antes de cerrar la tarea.
