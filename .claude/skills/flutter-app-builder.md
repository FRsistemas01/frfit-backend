---
name: flutter-app-builder
description: "Crea y diseña apps en Flutter de nivel profesional/premium, desde cero o sobre una app ya construida. Cubre tanto el scaffolding técnico (estructura del proyecto, modelos, navegación, arquitectura) como la dirección de diseño/UI/UX (sistema visual, componentes, layouts, tipografía, color, micro-interacciones) para que la app se sienta nativa premium y no una plantilla genérica. Triggers: 'hazme una app en flutter', 'quiero una app de [rubro]', 'crea un proyecto flutter', 'diseña la UI de esta app', 'necesito el diseño visual de mi app flutter', 'app flutter que se vea profesional/premium', 'sistema de diseño para mi app', 'mejora el UI/UX de mi app flutter', 'arma las pantallas de la app', 'quiero rediseñar mi app flutter'."
---

# Flutter App Builder — Apps Flutter de nivel premium

Convierte una descripción de negocio (o una app Flutter ya construida) en una app completa y con dirección de diseño profesional, no una plantilla genérica.

**Regla fundamental: nunca uses el look por defecto de Material Design sin trabajarlo. Cada app tiene su propio sistema visual, diseñado a medida según el rubro y el público — el objetivo es que quien la abra piense "esto es una app nativa premium", no "esto es un dashboard hecho con componentes de fábrica".**

---

## Paso 1 — Entender qué necesita el usuario

Pregunta de forma conversacional, agrupando en bloques (no interrogatorio):

**Bloque 1 — Qué existe hoy**
- ¿Partimos de cero (proyecto nuevo) o ya existe un proyecto Flutter con la lógica de negocio construida?
- Si ya existe: pedí la ruta del proyecto y explorá la estructura (`lib/`, modelos, providers/bloc, pantallas actuales) antes de preguntar nada más — no inventes lo que ya podés leer del código.

**Bloque 2 — Qué necesita el negocio**
- ¿Qué funcionalidades/módulos tiene o debe tener la app? (pedí que las describan como lista, tipo lo que ya me pasaste del proyecto de fitness)
- ¿Hay datos reales (API, Firebase, base de datos) o por ahora es solo interfaz con datos de ejemplo?
- ¿Necesita login/autenticación, pagos, notificaciones push, IA?

**Bloque 3 — Dirección visual**
- ¿Qué rubro/industria es? (fitness, delivery, finanzas, salud, e-commerce...) — esto define el lenguaje visual de referencia
- ¿Hay referencias visuales que le gusten? (apps que admiren, screenshots, paleta de marca ya existente) — si no hay, proponé vos 2-3 direcciones distintas basadas en el rubro
- ¿Modo oscuro, claro, o ambos?

Si el usuario ya dio toda esta info en su primer mensaje (como en el caso de fitness), no la vuelvas a preguntar — confirmá lo que entendiste y avanzá.

---

## Paso 2 — Diseñar el sistema visual (custom design system)

Nunca arranques directo a construir pantallas sin definir primero el sistema. Esto es lo que separa una app premium de una genérica.

### 2.1 — Paleta de color
- Diseñá una paleta específica para el rubro, no uses los colores default de Material (`Colors.blue`, `Colors.deepPurple`, etc.)
- Definí: color primario, secundario/acento, superficie, fondo, textos (primario/secundario/deshabilitado), estados (éxito, error, advertencia), y variantes para modo oscuro si aplica
- Para fitness/salud: paletas que transmitan energía y foco sin caer en el cliché "gym rojo/negro" — explorá también verdes profundos, azules eléctricos con acentos cálidos, o paletas monocromáticas con un solo acento vibrante
- Documentá la paleta como un archivo `lib/theme/app_colors.dart` con `ColorScheme` completo

### 2.2 — Tipografía
- Elegí una fuente (Google Fonts vía `google_fonts` package) que le dé personalidad — evitá Roboto por defecto
- Definí una escala tipográfica completa (display, headline, title, body, label) con pesos y tracking cuidados
- Documentá en `lib/theme/app_typography.dart`

### 2.3 — Sistema de espaciado y forma
- Definí una escala de espaciado consistente (4/8/12/16/24/32/48)
- Definí radios de borde consistentes (¿bordes muy redondeados tipo iOS-friendly, o más geométricos?)
- Definí elevación/sombras — preferí sombras suaves y difusas por sobre el `Material` elevation plano por defecto

### 2.4 — Componentes base
Diseñá (no uses los widgets de Material sin personalizar) al menos:
- Botones (primario, secundario, texto) con estados (pressed, disabled, loading)
- Cards / contenedores de contenido
- Inputs de formulario
- Navegación (bottom nav bar custom, no la de Material por defecto — considerá indicadores animados, iconos con estado activo/inactivo diferenciado)
- Gráficos/charts si la app los necesita (progreso, evolución) — usá librerías como `fl_chart` pero con theming custom, nunca el estilo default

Guardá esto como `lib/theme/app_theme.dart` centralizando un `ThemeData` completo.

---

## Paso 3 — Construir (scaffolding técnico si aplica)

Si el proyecto es nuevo:

1. Verificá que Flutter esté instalado (`flutter --version`); si no, avisá al usuario con instrucciones de instalación para su SO — no lo bloquees, ofrecé el link oficial
2. Creá el proyecto: `flutter create nombre_app --org com.ejemplo`
3. Estructurá `lib/` de forma limpia y escalable:
   ```
   lib/
     main.dart
     theme/           (colores, tipografía, theme.dart del paso 2)
     models/          (modelos de datos)
     screens/         (una carpeta por módulo/feature)
     widgets/         (componentes reutilizables)
     services/        (API, storage, IA, pagos)
     providers/  o  blocs/   (estado, según lo que ya use el proyecto o lo que prefiera el usuario)
   ```
4. Auto-instalá las dependencias necesarias en `pubspec.yaml` según lo que la app necesite (`google_fonts`, `fl_chart`, `provider`/`flutter_bloc`, `http`/`dio`, etc.) y corré `flutter pub get`
5. Si el proyecto ya existe, respetá su arquitectura actual — no la reescribas, adaptate a los patrones que ya usa (state management, estructura de carpetas) y enfocate en lo que te pidieron (típicamente el paso 4)

---

## Paso 4 — Diseñar las pantallas (UI/UX)

Para cada módulo/pantalla:

- Pensá primero en **jerarquía de información**: qué es lo más importante que el usuario tiene que ver primero en esa pantalla
- Usá **micro-interacciones**: animaciones sutiles en transiciones, feedback táctil en botones, skeleton loaders en vez de spinners genéricos, animaciones de entrada escalonadas en listas (`AnimatedList`, `flutter_animate` si hace falta)
- Evitá layouts de "formulario largo" — preferí steppers, cards expandibles, bottom sheets contextuales
- Para pantallas de datos numéricos (progreso, macros, rutinas), priorizá visualización sobre texto: anillos de progreso, gráficos de evolución, barras comparativas — no tablas planas
- Adaptá el diseño según el módulo: una pantalla de "chat con IA" necesita un lenguaje visual distinto a una de "historial de entrenamiento" — mantené el sistema del Paso 2 pero con libertad de composición
- Construí primero la pantalla más representativa del "wow factor" de la app (en fitness, probablemente Progreso o Coach IA) para validar dirección visual con el usuario antes de replicar el sistema al resto

**Libertad creativa**: no sigas un layout rígido predefinido. Usá el sistema visual del Paso 2 como restricción de consistencia, pero la composición de cada pantalla es libre — priorizá lo que se vea mejor para ese contenido específico.

---

## Paso 5 — Revisar y presentar

Al terminar (o al completar un módulo si es un proyecto grande):

1. Corré `flutter analyze` para verificar que no haya errores
2. Si es posible, corré la app (`flutter run` o mostrá cómo previsualizarla) y describí/mostrá el resultado
3. Presentá un resumen:
   - Qué pantallas/módulos se construyeron o diseñaron
   - Qué sistema visual se definió (paleta, tipografía) y por qué encaja con el rubro
   - Qué falta por completar o conectar (ej: "el chat IA usa datos mock, falta conectar la API de Gemini")
   - Preguntá si quiere ajustar la dirección visual antes de replicarla a más pantallas

No sugieras precios ni consejos de venta — esto es una herramienta de trabajo, no una propuesta comercial.

---

## Notas para casos como apps de fitness/salud/coaching con IA

- Si la app ya tiene lógica de negocio (modelos, cálculos, IA, pagos) construida y solo falta diseño, no toques la lógica — trabajá exclusivamente en `theme/`, `screens/` (la parte de UI) y `widgets/`, conectando a los datos/métodos que ya existen
- Para features con IA conversacional (coach, asistente): diseñá el chat con burbujas custom (no el look de WhatsApp por defecto), y destacá visualmente cuando la IA genera algo "accionable" (ej: una rutina o plan de comida que se puede guardar con un click) — usá una card diferenciada con CTA claro
- Para features de billing/premium: el paywall/upsell debe sentirse integrado al sistema visual de la app, no un modal genérico de terceros
