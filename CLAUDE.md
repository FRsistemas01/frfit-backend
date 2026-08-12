# Kit de apps Flutter

Esta carpeta usa la skill `flutter-app-builder` para crear apps móviles nuevas de nivel profesional, con dirección de diseño premium (no plantillas genéricas).

## Comportamiento al iniciar

Cuando el usuario abra esta carpeta y escriba cualquier cosa, respondé:

> **Kit de apps Flutter**
>
> Contame qué app querés armar: para qué rubro es, qué funcionalidades necesita, y si ya tenés un backend/API o hay que armar todo desde cero.
>
> Si tenés capturas de referencia de diseño (una app que te guste, una paleta de colores), pasámelas — ayuda mucho a definir la dirección visual.

Después usá la skill `flutter-app-builder` automáticamente.

## Notas de la sesión anterior (FRfitt)

Se usó esta skill para construir "FRfitt", una app de fitness con backend Django (API REST) + Flutter completo. Aprendizajes que vale la pena aplicar de entrada en el próximo proyecto:

- **Paleta**: preguntar temprano si quieren un acento de color dominante único (ej. violeta) en vez de mezclar varios colores — un solo acento sobre negro/blanco da un look mucho más premium.
- **Fondos**: evitar manchas de color genéricas o degradés con bordes duros — un glow sutil que se funde solo (gradiente a alpha 0, sin clips/recortes) se ve mucho mejor.
- **Registro de datos** (rutinas, comidas, lo que sea que la app registre): pensar desde el arranque en que el usuario va a necesitar **editar** lo que ya cargó, no solo crear y borrar — armar la UI de carga de forma reusable entre "crear" y "editar" ahorra tiempo después.
- **Selección de ítems** (ejercicios, alimentos, lo que sea de una lista): mejor un selector dedicado con búsqueda que un `TextField` libre o un autocomplete — se siente mucho más pulido.
- Si el usuario pide "que se vea como [tal app]" o manda una captura de referencia, prestar mucha atención a si quiere el *estilo* general o un *elemento visual específico* (por ejemplo: sí quería el look oscuro+violeta con glow, pero no manchas de color genéricas) — conviene confirmar antes de rehacer todo.
- Preguntar de entrada si van a necesitar probarla en un celular real (no solo emulador/desktop) — así se configura la IP de red y el backend accesible por LAN desde el principio, en vez de tener que resolverlo después.
