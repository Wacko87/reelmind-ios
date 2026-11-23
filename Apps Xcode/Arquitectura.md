# 🏛️ Arquitectura del Sistema

Documento de referencia técnica sobre patrones, flujo de datos, servicios y dependencias de la app.

---

## 1. Patrón Arquitectónico General
- **Patrón:** MVVM (Model - View - ViewModel) nativo de SwiftUI.
- **Observabilidad:** Macro `@Observable` (Observation framework, Swift 5.9+ / Swift 6) con `@MainActor` en ViewModels.
- **Concurrencia:** Swift Concurrency (`async/await`, `Task`, `Sendable`).

## 2. Capas de la Aplicación
```text
MiApp/
├── Models/        # Estructuras de datos inmutables (Codable, Identifiable, Sendable)
├── ViewModels/    # Lógica de negocio y estado observable
├── Views/         # Vistas SwiftUI declarativas y sub-vistas modulares
└── Services/      # Persistencia (SwiftData / UserDefaults) y Networking
```

## 3. Servicios y Persistencia
*(Se detallarán conforme se defina la app y sus dependencias)*.
