import json

translations = {
    "Dashboard": "Panel",
    "Prompt Studio": "Estudio de Prompts",
    "Ask Vault": "Preguntar a la Bóveda",
    "Settings": "Ajustes",
    "ReelMind": "ReelMind",
    "Search reels, tools, prompts...": "Buscar reels, herramientas, prompts...",
    "All Tools": "Todas las herramientas",
    "Show all AI tools": "Mostrar todas las herramientas",
    "Filter by tool %@": "Filtrar por herramienta %@",
    "All": "Todos",
    "Favorites": "Favoritos",
    "Tested": "Probados",
    "Pending": "Pendientes",
    "Loading ReelMind Vault...": "Cargando bóveda de ReelMind...",
    "No Reels in this view": "No hay reels en esta vista",
    "Tap + to ingest a reel or video from Instagram, TikTok or YouTube.": "Toca + para añadir un reel o vídeo de Instagram, TikTok o YouTube.",
    "Delete": "Eliminar",
    "Add new reel to vault": "Añadir nuevo reel a la bóveda",
    "Activate Free Gemini AI": "Activa tu IA gratuita de Gemini",
    "Tap here to add your free Gemini key in 1 click & analyze reels.": "Toca aquí para añadir tu clave gratuita de Gemini en 1 clic y analizar reels.",
    "Save Reels from Any App": "Guarda reels desde cualquier app",
    "Tap Share in Instagram, TikTok, YouTube, or X and select ReelMind to automatically extract AI tools, prompts, and steps.": "Pulsa Compartir en Instagram, TikTok, YouTube o X y selecciona ReelMind para extraer herramientas de IA, prompts y pasos automáticamente.",
    "Status": "Estado",
    "Favorite": "Favorito",
    "Open original video": "Abrir vídeo original",
    "Executive Summary": "Resumen Ejecutivo",
    "Mentioned AI Tools": "Herramientas de IA Mencionadas",
    "Step-by-Step Blueprint": "Guía Paso a Paso",
    "Extracted Prompts & Formulas": "Prompts y Fórmulas Extraídas",
    "Prompt #%lld": "Prompt nº %lld",
    "Copy": "Copiar",
    "Personal Notes & Learnings": "Notas Personales y Aprendizajes",
    "Save Notes": "Guardar Notas",
    "Reel Breakdown": "Desglose del Reel",
    "Copied to Clipboard": "Copiado al portapapeles",
    "Remove from favorites": "Quitar de favoritos",
    "Add to favorites": "Añadir a favoritos",
    "Ingest Reel / Video": "Añadir Reel / Vídeo",
    "Paste video URL (Instagram, TikTok, YouTube, X)...": "Pega el enlace del vídeo (Instagram, TikTok, YouTube, X)...",
    "Paste from Clipboard": "Pegar del portapapeles",
    "Analyze & Extract AI Knowledge": "Analizar y Extraer Conocimiento IA",
    "Analyzing with Gemini...": "Analizando con Gemini...",
    "Cancel": "Cancelar",
    "Describe what you want to generate or paste a prompt...": "Describe qué quieres generar o pega un prompt...",
    "Target Model:": "Modelo de destino:",
    "Optimize with AI": "Optimizar con IA",
    "Optimizing...": "Optimizando...",
    "Generated Variations": "Variaciones Generadas",
    "Prompt Copied!": "¡Prompt Copiado!",
    "Ask Your AI Vault": "Pregunta a tu Bóveda de IA",
    "Search by concept, AI tool, or question...": "Busca por concepto, herramienta IA o pregunta...",
    "Synthesize Answer": "Sintetizar Respuesta",
    "Thinking & Synthesizing...": "Pensando y sintetizando...",
    "Vault Insights": "Conocimiento de la Bóveda",
    "Referenced Reels": "Reels Referenciados",
    "AI Intelligence Engine": "Motor de Inteligencia Artificial",
    "Google Gemini API Key": "Clave API de Google Gemini",
    "Get Free Gemini Key (1 click)": "Obtén tu clave gratuita de Gemini (1 clic)",
    "AI Model": "Modelo de IA",
    "Gemini 2.5 Flash (Recommended)": "Gemini 2.5 Flash (Recomendado)",
    "Gemini 2.5 Pro (Deep Reasoning)": "Gemini 2.5 Pro (Razonamiento Profundo)",
    "Verify AI Engine": "Verificar Motor de IA",
    "ReelMind runs 100% locally on your iPhone using your private Gemini Key. Your data never touches any third-party server.": "ReelMind funciona 100% en local en tu iPhone usando tu clave privada de Gemini. Tus datos nunca pasan por servidores de terceros.",
    "Vault Management": "Gestión de la Bóveda",
    "Export Vault as Markdown": "Exportar Bóveda en Markdown",
    "Restore Sample Reels": "Restaurar Reels de Ejemplo",
    "Restore Initial Samples?": "¿Restaurar ejemplos iniciales?",
    "This will reload the initial tutorial reels into your local vault.": "Esto recargará los reels de tutoriales iniciales en tu bóveda local.",
    "Restore Samples": "Restaurar Ejemplos",
    "Advanced Setup": "Configuración Avanzada",
    "Self-Hosted Server Mode": "Modo Servidor Propio",
    "Server URL": "URL del Servidor",
    "Access PIN / Token": "PIN / Token de Acceso",
    "About ReelMind": "Acerca de ReelMind",
    "Mode": "Modo",
    "Architecture": "Arquitectura",
    "Privacy": "Privacidad",
    "Zero Data Collection": "Cero Recopilación de Datos",
    "Local Device (On-Device)": "Dispositivo Local (En el móvil)",
    "Remote Server": "Servidor Remoto",
    "Vault Backup": "Copia de Seguridad de la Bóveda",
    "Close": "Cerrar",
    "Share": "Compartir",
    "Content to Analyze:": "Contenido a analizar:",
    "Detecting shared URL...": "Detectando URL compartida...",
    "Save to Vault": "Guardar en la Bóveda",
    "Ingesting...": "Guardando...",
    "Saved: %@": "Guardado: %@",
    "Please add your free Google Gemini API Key in Settings to analyze reels.": "Por favor añade tu clave gratuita de Google Gemini en Ajustes para analizar reels.",
    "Settings saved securely.": "Ajustes guardados de forma segura.",
    "Gemini AI Engine verified and ready!": "¡Motor de IA Gemini verificado y listo!"
}

catalog = {
    "sourceLanguage": "en",
    "strings": {},
    "version": "1.0"
}

for en_str, es_str in translations.items():
    catalog["strings"][en_str] = {
        "extractionState": "manual",
        "localizations": {
            "en": {
                "stringUnit": {
                    "state": "translated",
                    "value": en_str
                }
            },
            "es": {
                "stringUnit": {
                    "state": "translated",
                    "value": es_str
                }
            }
        }
    }

output_path = "/Users/wacko87/Desktop/Creacion Apps en Xcode/ReelMind/Resources/Localizable.xcstrings"
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)

print(f"Generated {len(translations)} strings in {output_path}")
