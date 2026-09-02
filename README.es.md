# Natural Spacing

[English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

> Alfa del código fuente. La publicación en registros de paquetes está deshabilitada intencionadamente.

Natural Spacing es un conjunto de herramientas basado primero en una especificación para añadir espacios predecibles en los límites entre caracteres Han y letras latinas, y entre caracteres Han y dígitos ASCII, sin afectar la composición del IME, las selecciones, la intención de borrado ni el comportamiento nativo de deshacer. Está pensado tanto para entrada interactiva como para texto no interactivo, incluido ASR, dictado, contenido importado y prosa generada.

## Antes y después

Con la política `naturalLanguage` activada:

```diff
- 在GitHub发布2个项目
+ 在 GitHub 发布 2 个项目
```

| Antes | Después |
| --- | --- |
| `支持macOS和Windows11系统` | `支持 macOS 和 Windows11 系统` |
| `今天发布v2版本` | `今天发布 v2 版本` |

El formateador solo inserta espacios en límites directos entre caracteres Han y letras latinas, o entre caracteres Han y dígitos ASCII. Los espacios existentes, la puntuación, las secuencias de letras latinas y dígitos como `React18`, y los campos que usan la política `verbatim` permanecen sin cambios. Los adaptadores de edición en vivo están diseñados para producir el mismo resultado visible y, a la vez, preservar la composición del IME, las selecciones, la intención de borrado y el comportamiento nativo de deshacer; consulta más abajo los niveles de compatibilidad experimental.

## Estado

Se han implementado las reglas v1, los núcleos de referencia privados para TypeScript/Swift/Kotlin/C#/Dart y los puentes experimentales para UIKit/AppKit/SwiftUI/Web/Android Views/Jetpack Compose/WinUI/WPF/Flutter. El proyecto aún **no** contiene adaptadores de plataforma listos para producción. Todos los puentes de plataforma existentes seguirán siendo experimentales hasta que superen su matriz de aceptación con entradas reales.

El hito actual incluye:

- reglas v1;
- el contrato de edición independiente del lenguaje;
- metadatos fijados de las fuentes Unicode 17.0, datos oficiales de pruebas de grafemas y artefactos generados de clasificación y segmentación independientes del lenguaje;
- fixtures compartidos de reglas y sesiones de entrada;
- un validador de la especificación sin dependencias;
- un núcleo TypeScript y un coordinador de sesiones que usan segmentación y clasificación deterministas de grafemas Unicode 17;
- núcleos Swift solo con Foundation, Kotlin/JVM, C# para .NET 10 sin dependencias y Dart 3.13 sin dependencias, todos basados en los mismos datos generados de clasificación y segmentación Unicode 17;
- adaptadores experimentales de `TextBox` para WinUI 3 y WPF que comparten un coordinador de texto estable comprobable desde el host;
- un paquete experimental Flutter `TextInputFormatter` verificado con el SDK y un consumidor independiente mediante dependencia de ruta;
- un adaptador experimental para `EditText` de Android Views;
- un adaptador experimental con estado para `TextFieldValue` de Jetpack Compose;
- adaptadores experimentales de selección única para UIKit y AppKit;
- envoltorios experimentales de editores de texto SwiftUI para iOS/macOS construidos sobre esos adaptadores nativos;
- cobertura XCTest en iPhone Simulator para controles UIKit y publicación de bindings de SwiftUI;
- cobertura XCTest en macOS para `NSTextView`, el editor de campo de `NSTextField`, deshacer/notificaciones nativas y publicación de bindings de SwiftUI;
- adaptadores experimentales de texto plano para Web y compatibles con React;
- cobertura Playwright de doce escenarios nativos y de extremo a extremo con `input`/`textarea` en motores locales Chrome, Edge, Firefox y WebKit, incluida la degradación segura en campos de contraseña y una demostración compartida de políticas para teclado, entrada segura y ASR;
- cobertura en los mismos cuatro motores para React 19.2.8 en modos controlado, no controlado, restablecimiento externo y deshacer/rehacer;
- una hoja de estilos progresiva `text-autospace` que solo afecta a la presentación;
- APIs explicables de recomendación de políticas y actualización de texto interim/final;
- resolución segura de políticas entre lenguajes que solo aplica automáticamente recomendaciones con `autoApply` y, en los demás casos, usa `verbatim`;
- sesiones ordenadas de ASR/dictado independientes del proveedor en TypeScript, Swift, Kotlin, C# y Dart, con fixtures compartidos de ciclo de vida y revisión, sin conservar el texto transcrito;
- ejemplos de ASR independientes del proveedor y comprobados para hipótesis completas, deltas explícitamente acumulativos, revisiones ordenadas, cancelación, cierre final y aislamiento de enunciados;
- consumidores aislados de tarballs npm, SwiftPM desde la raíz, compilación compuesta de Kotlin, ProjectReference de .NET y dependencias de ruta de Dart y Flutter que importan y ejercitan las APIs públicas.

## Principios

- Los campos deben optar explícitamente por `naturalLanguage`; la política predeterminada es `verbatim`.
- Nunca se reescribe un intervalo de composición IME activo.
- Se respeta la decisión del usuario de eliminar un espacio insertado automáticamente.
- Los cambios automáticos se expresan como pequeños parches de inserción y la selección se mapea a través de ellos.
- La semántica de las reglas se mantiene en la especificación y en los fixtures, no en una implementación privilegiada de un lenguaje.
- El espaciado CSS estático se mantiene separado del contenido de entrada almacenado.
- La política se resuelve una sola vez a partir de una configuración explícita o del contexto semántico; nunca se cambia un editor activo basándose únicamente en heurísticas de texto.

## Mapa del repositorio

```text
Package.swift
spec/
  rules-v1.md
  content-policy-v1.md
  edit-contract.schema.json
  unicode/17.0.0/sources.json
  unicode/17.0.0/classification-ranges.json
  unicode/17.0.0/grapheme-segmentation.json
  fixtures/rules-v1.json
  fixtures/sessions-v1.json
  fixtures/policy-v1.json
  fixtures/text-updates-v1.json
  fixtures/ordered-text-sessions-v1.json
docs/
  ordered-text-updates.md
  publication-boundary.md
  adr/
examples/
  asr/
  consumers/
scripts/
  generate-unicode-tables.mjs
  generate-grapheme-tables.mjs
  validate-spec.mjs
packages/
  dart/
  dotnet/
  flutter/
  kotlin/
  typescript/core/
  typescript/web/
  swift/
```

## Validar la especificación

Node.js 20 o posterior es suficiente para validar la especificación y ejecutar la suite de conformidad de TypeScript. Las reglas de TypeScript ya no dependen de la versión Unicode del entorno de ejecución host.

```sh
npm run validate
npm test
npm run test:consumer:npm
npm run test:browser
swift test
bash scripts/test-swift-consumer.sh
bash scripts/test-ios-simulator.sh
(cd packages/kotlin && ./gradlew --no-daemon conformance :android-views:testDebugUnitTest :android-views:assembleDebug :compose:testDebugUnitTest)
bash scripts/test-kotlin-consumer.sh
dotnet run --project packages/dotnet/NaturalSpacing.Conformance/NaturalSpacing.Conformance.csproj -- .
bash scripts/test-dotnet-consumer.sh
(cd packages/dart && dart pub get && dart run tool/conformance.dart ../..)
bash scripts/test-dart-consumer.sh
bash scripts/test-flutter.sh
bash scripts/test-flutter-target-builds.sh
```

El validador comprueba en el conjunto de archivos candidatos de Git las rutas prohibidas de compilación, caché y credenciales; patrones comunes de secretos; rutas absolutas al directorio personal; y enlaces relativos de Markdown rotos. También comprueba la sintaxis JSON, los campos obligatorios de los fixtures, los identificadores únicos, los intervalos UTF-16, los límites de selección esperados, los metadatos fijados de las fuentes Unicode y los intervalos generados de clasificación y segmentación. `npm test` también compara las cinco tablas de clasificación y las cuatro tablas nativas de segmentación generadas con sus artefactos independientes del lenguaje, compila el núcleo TypeScript y ejecuta pruebas de reglas, sesiones, Web y ASR. Todas las suites de los núcleos ejecutan los mismos 766 casos oficiales de grafemas fijados. Consulta el [flujo de trabajo de datos Unicode](spec/unicode/README.md) para reproducir las tablas.

El repositorio incluye un flujo de trabajo de GitHub Actions de solo lectura para TypeScript/Web/ASR, una matriz Playwright de Chromium/Firefox/WebKit, Swift/UIKit/AppKit/SwiftUI, Kotlin/JVM, C#/.NET, Dart/Flutter y compilación de adaptadores Windows. La automatización local del navegador cubre actualmente doce escenarios nativos y de extremo a extremo, además de tres escenarios de React 19, en Chrome 152, Edge 151, Playwright Firefox 153 y Playwright WebKit 26.5: 60 ejecuciones de navegador, incluidas deshacer/rehacer nativas en una sola transacción, degradación segura en campos de contraseña y una demostración ejecutable que comparte políticas resueltas entre rutas de teclado, entrada segura y ASR ordenado. CI ejecuta los mismos quince escenarios en sus tres motores administrados. Superar la automatización no demuestra que hayan pasado Safari/Firefox de distribución, un IME real, una ruta de dictado, una fuente de entrada asistida ni una matriz de dispositivos.

Las pruebas rápidas de consumidores de paquetes están separadas intencionadamente de la conformidad. Verifican que los tarballs npm empaquetados se instalan e importan sin conexión, que la raíz del repositorio es una dependencia SwiftPM válida que expone los cuatro productos de Apple y que proyectos Kotlin, .NET, Dart y Flutter independientes pueden importar sus núcleos o adaptadores mediante dependencias de código fuente. No autorizan la publicación en registros ni demuestran una dependencia Git remota con etiqueta, Maven, NuGet o pub. Empieza por los [ejemplos de consumidores desde código fuente](examples/consumers/README.md) y consulta la [instantánea de evidencias de consumidores](docs/evidence/package-consumers-2026-09-02.md) para conocer resultados y límites exactos. Las herramientas manuales para UIKit/SwiftUI, AppKit/SwiftUI, Android Views/Compose, Web, Flutter, WinUI 3 y WPF están indexadas por separado en [hosts de aceptación de entradas reales](examples/acceptance/README.md); compilarlas no eleva el nivel de soporte de una plataforma.

Para integrar una aplicación, empieza por [Primeros pasos desde el código fuente](docs/getting-started.md). Allí se selecciona la ruta adecuada para editor en vivo, texto no interactivo/ASR o solo presentación; se documenta la resolución segura de políticas; y se enlaza cada adaptador de plataforma.

## Recomendación de políticas y ASR

`recommendPolicy(context)` devuelve `naturalLanguage` o `verbatim` junto con la confianza, el motivo, la fuente de evidencia y una marca `autoApply`. La seguridad y los campos de contraseña siempre fuerzan `verbatim`; fuera de entradas seguras, una política explícita tiene prioridad. Las heurísticas basadas solo en texto son recomendaciones y nunca cambian automáticamente un editor activo.

`resolvePolicy(context, fallback)` es la ruta práctica para la configuración automática. Solo adopta la recomendación cuando `autoApply=true`; en caso contrario devuelve el fallback del llamador, cuyo valor predeterminado es `verbatim`. Los adaptadores de interfaz con política opcional también usan `verbatim` por defecto, de modo que el espaciado de lenguaje natural siempre requiere una activación explícita o una resolución segura.

`formatTextUpdate(update)` admite ASR, dictado, contenido importado y texto generado. Las hipótesis interim producen texto para mostrar, pero no un valor confirmado; las hipótesis final pueden persistirse. Consulta [Política de contenido y texto no interactivo v1](spec/content-policy-v1.md).

`OrderedTextUpdateSession` añade un ciclo de vida de enunciados independiente del proveedor y gestión de revisiones monótonas. Solo acepta eventos del enunciado activo, rechaza revisiones duplicadas o antiguas, se cierra tras un evento final válido y conserva únicamente el ID del enunciado activo y la última revisión, no el texto transcrito. Consulta [Actualizaciones ordenadas de ASR y dictado](docs/ordered-text-updates.md).

## Alcance de las reglas v1

Las reglas v1 insertan U+0020 únicamente en estos límites directos, en ambas direcciones:

- Han ↔ latino;
- Han ↔ dígito ASCII (`0`–`9`).

No añaden reglas para puntuación, dígitos de ancho completo, japonés, coreano, Markdown, código fuente, texto enriquecido ni `contenteditable`.

## Licencia

Apache License 2.0. Consulta [LICENSE](LICENSE).

La implementación actual y el soporte de plataformas se registran en [COMPATIBILITY.md](COMPATIBILITY.md).
El orden completo de plataformas y las puertas de aceptación se registran en [ROADMAP.md](ROADMAP.md).
Las carencias de segmentación Unicode se muestran explícitamente en la [matriz de segmentación](docs/unicode-segmentation-matrix.md), y las evidencias de entradas reales siguen el [protocolo de aceptación de plataformas](docs/platform-acceptance.md).
Las puertas actuales de publicación del código fuente se registran en la [auditoría de preparación para publicación](docs/evidence/publication-readiness-2026-09-02.md).
Las evidencias de hosts para adaptadores Apple se registran por separado para [macOS](docs/evidence/macos-host-2026-09-02.md) y [iOS Simulator](docs/evidence/ios-simulator-2026-09-02.md).
Las evidencias del SDK de Flutter se registran en la [instantánea del host Flutter](docs/evidence/flutter-host-2026-09-02.md).
