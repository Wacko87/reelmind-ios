## 🛑 REGLA ESTRICTA: NUNCA SUBIR A PRODUCCIÓN SIN PERMISO EXPRESO

**QUEDA TERMINANTEMENTE PROHIBIDO desplegar o subir cambios a producción sin que el usuario lo autorice o solicite explícitamente:**
- Todo desarrollo, refactorización, corrección de errores y pruebas deben permanecer **EXCLUSIVAMENTE EN LOCAL** (`localhost:8080`, archivos locales, simulador de Xcode).
- **NUNCA** ejecutar scripts de sincronización o despliegue a producción (como `./sync-to-unraid.sh`, `ssh root@...` para reiniciar o modificar contenedores en producción, publicación en App Store / TestFlight o transferencias hacia servidores remotos) a menos que el usuario diga literalmente palabras como *"súbelo a producción"*, *"despliega en producción"*, o dé su confirmación explícita para hacerlo.
- Si el usuario no lo pide expresamente, todo se queda en local, se verifica en local y se le reporta el estado local a la espera de sus instrucciones.

## 📌 REGLA DE ORO OBLIGATORIA: Registro Automático de Cambios en la Wiki

**Cada vez que se complete cualquier intervención, configuración, migración, despliegue, saneamiento u optimización en la infraestructura (servidor Unraid, Docker, Nginx Proxy Manager, pfSense, redes, almacenamiento, etc.):**

1. **Registro Proactivo y Automático (Sin esperar a que el usuario lo pida):**
   - El registro en la wiki forma parte indivisible de la tarea. No se dará una intervención por finalizada sin haber guardado y sincronizado la documentación técnica correspondiente.

2. **Doble Registro Sincronizado (Obsidian + Trilium Notes):**
   - **Bóveda local de Obsidian:** Crear o actualizar el archivo Markdown en `/Users/wacko87/Desktop/Proyectos Antigravity/Antigravity/`.
   - **Trilium Notes:** Usar **SIEMPRE** el cliente estandarizado del workspace para que el permiso permanente (*Opción 3: Siempre en este proyecto*) se mantenga activo sin volver a pedir confirmación:
     ```bash
     python3 "/Users/wacko87/Desktop/Proyectos Antigravity/trilium-client.py" create --title "Título" --file "/ruta/nota.md"
     python3 "/Users/wacko87/Desktop/Proyectos Antigravity/trilium-client.py" update --id "ID_NOTA" --file "/ruta/nota.md"
     ```
     *(Prohibido usar `python3 -c '...'` dinámico para Trilium, ya que invalida el permiso persistente).*
   - **Índice Central:** Enlazar siempre la nueva guía técnica en [`Bienvenido.md`](/Users/wacko87/Desktop/Proyectos%20Antigravity/Antigravity/Bienvenido.md).

3. **Creación de Guías Monográficas Específicas:**
   - Cada cambio relevante debe contar con su **nota técnica independiente** (por ejemplo: migración de un servicio, limpieza de huérfanos, configuración de protocolos, asignación de cuotas).
   - Además, debe añadirse un resumen en la ficha global correspondiente (ej. sección en `auditoria-optimizacion-servidor-unraid.md` / nota Trilium `LR687yyd0MPI`).

4. **Sincronización de Inventarios:**
   - Si la intervención altera contenedores Docker o dominios CNAME en Nginx Proxy Manager, ejecutar siempre el script de sincronización:
     ```bash
     python3 "/Users/wacko87/Desktop/Proyectos Antigravity/actualizar-inventario-docker.py"
     ```

5. **Estructura Requerida en Cada Guía:**
   - **Objetivo y Justificación Técnica:** Por qué se hizo el cambio.
   - **Respaldos Preventivos (Red de Seguridad):** Ubicación exacta de backups previos.
   - **Procedimiento Paso a Paso:** Comandos y parámetros exactos aplicados.
   - **Verificación y Resultados:** Métricas obtenidas (espacio recuperado, códigos HTTP, puertos, logs).
   - **Plan de Contingencia (Rollback):** Comandos para revertir el cambio si algo falla.
   - **Comandos de Monitorización:** Cómo auditar o comprobar el estado en el futuro.

## 🐳 REGLA OBLIGATORIA: Despliegue de Docker en Unraid con Plantillas Oficiales de Community Applications

**Siempre que se instale un contenedor Docker en el servidor Unraid:**
1. **Prioridad Absoluta a la Plantilla de la Tienda de Apps (Community Applications):**
   - Si la aplicación dispone de plantilla en Community Applications / repositorios de Unraid, debe utilizarse **siempre** la plantilla oficial (`/boot/config/plugins/dockerMan/templates-user/my-<Nombre>.xml`).
   - El contenedor debe incluir **obligatoriamente** las etiquetas nativas de DockerMan:
     - `-l 'net.unraid.docker.managed=dockerman'`
     - `-l 'net.unraid.docker.webui=...'`
     - `-l 'net.unraid.docker.icon=...'`
   - Esto evita que Unraid clasifique el contenedor como *"3rd Party / Por terceros"* y garantiza que el sistema nativo de actualizaciones automáticas (`up-to-date`, `update ready`, `Update All`) funcione con un solo clic.
2. **Registro Inmediato en el Gestor de Versiones:**
   - Tras el despliegue, ejecutar la sincronización del estado de actualización (`reloadUpdateStatus`) en `/var/lib/docker/unraid-update-status.json` y actualizar la caché de aplicaciones de CA (`info.json`).

---

# AGENT.md - Directrices Técnicas y Operativas del Proyecto

## 1. Entorno de Desarrollo y Hardware
- **Máquina:** Mac mini (Apple Silicon, macOS).
- **Entorno de trabajo:** Antigravity vinculado con Xcode.
- **Objetivo del proyecto:** Aplicación nativa para iOS preparada para publicación en la App Store.
- **Stack:** Swift 6, SwiftUI (Arquitectura MVVM con `@Observable`), Swift Concurrency (`async/await`).

## 2. Reglas de Estructura y Código
- **Separación estricta de capas:**
  - `MiApp/Models/`: Estructuras de datos inmutables y conformidades a `Codable`, `Identifiable`, `Sendable`.
  - `MiApp/ViewModels/`: Clases `@Observable` con `@MainActor` para gestión de estado y lógica de negocio.
  - `MiApp/Views/`: Vistas SwiftUI modulares. Separar componentes en sub-vistas para mantener vistas ligeras y compatibles con el Xcode Canvas.
  - `MiApp/Services/`: Networking, persistencia local (SwiftData/UserDefaults) y lógica externa.
- **App Store Compliance:**
  - Prohibido el uso de APIs privadas de Apple.
  - Todo permiso del sistema (cámara, fotos, ubicación, etc.) debe incluir su clave descriptiva correspondiente en `Info.plist`.
  - No dejar hardcodeados identificadores de prueba, credenciales ni tokens sensibles en el código fuente.

## 3. Protocolo Obligatorio de Documentación (Obsidian & Trilium)
Tras cada hito, función añadida o refactorización completada:

1. **Obsidian (Bóveda sincronizada en iCloud `./Apps Xcode` / `./Docs`):**
   - **Bitácora continua:** Actualizar `./Docs/Bitacora.md` cronológicamente con fecha y hora, tarea realizada, archivos creados/modificados y siguientes pasos pendientes.
   - **Nota independiente por conversación (OBLIGATORIO):** Cada conversación/sesión de Antigravity en este proyecto debe contar con su propia nota dedicada en `./Docs/Conversaciones/YYYY-MM-DD - [Título de la Sesión].md`. Esta nota documentará los objetivos de la sesión, participantes, decisiones técnicas, archivos tocados y próximos pasos, quedando indexada en `./Docs/Bienvenido.md`.
   - **Arquitectura:** Si se introduce un patrón arquitectónico o un nuevo servicio, actualizar `./Docs/Arquitectura.md`.

2. **Trilium:**
   - Mantener un bloque de texto formateado en `./Docs/Trilium_Sync.md` listo para copiar en Trilium (o preparado para envío vía script API de Trilium si está configurado).

## 4. Control de Versiones y GitHub
- Comprobar que el proyecto compila antes de cualquier commit (`Product > Build` en Xcode o comando `xcodebuild`).
- Respetar el formato Conventional Commits:
  - `feat: [descripción]` para nuevas funciones.
  - `fix: [descripción]` para correcciones de bugs.
  - `refactor: [descripción]` para cambios de código sin impacto funcional.
  - `docs: [descripción]` para actualizaciones exclusivas en `./Docs/`.
- Flujo de terminal tras cada hito validado:
  ```bash
  git add .
  git commit -m "tipo: descripción clara del cambio"
  git push origin main
  ```

## 5. Estándares Obligatorios de Repositorio Limpio y Producción (Git, CI, Tests, Licencia y Privacidad)
En toda app nueva y en el mantenimiento de las existentes, se deben aplicar obligatoriamente estos 5 principios de calidad:

1. **Higiene Estricta de Git (Cero Tooling en el Repo):**
   - El directorio `.agents/` (skills, evals, prompts) y las carpetas de herramientas del asistente deben permanecer **SIEMPRE en `.gitignore`**. Nunca se commitean al producto en GitHub.
   - Los enlaces simbólicos locales de macOS (`Apps Xcode`, `Docs -> /Users/...`) **NUNCA se commitean a Git**. En GitHub aparecen como archivos rotos y exponen la ruta privada del Mac del usuario. La sincronización de Obsidian se mantiene en local mediante `.gitignore`.

2. **Legal y Cumplimiento App Store:**
   - Todo repositorio debe incluir en la raíz su archivo oficial de licencia (`LICENSE`, habitualmente MIT) y su documento formal de política de privacidad (`PrivacyPolicy.md`) para cumplir las directrices de Apple.

3. **Suite de Pruebas Automatizadas (Swift Testing):**
   - Todo proyecto debe incluir un target de pruebas unitarias (`Tests/` / `[App]Tests`) con el framework moderno de Apple **Swift Testing** (`@Test`, `#expect`), cubriendo seguridad, validación de inputs, persistencia y servicios clave.

4. **Integración Continua (GitHub Actions CI):**
   - Todo repositorio debe contar con `.github/workflows/ci.yml` configurado para compilar (`xcodebuild build`) y ejecutar los tests (`xcodebuild test`) sobre el simulador universal de iOS en cada push o pull request a `main`.

5. **Fuente Única de Verdad (XcodeGen):**
   - Cuando se utilice `project.yml` junto a `[App].xcodeproj`, el archivo `README.md` debe declarar explícitamente a `project.yml` como la fuente de verdad declarativa del proyecto, explicando el comando `xcodegen generate` para evitar discrepancias.

