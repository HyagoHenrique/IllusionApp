import Foundation

/// All user-facing strings, grouped by feature. Each entry is a `LocalizedString`
/// that resolves to the right translation via `string(language)`.
enum AppStrings {

    enum Menu {
        static let mirrorRegion = LocalizedString(
            en: "Mirror a region…",
            pt: "Espelhar uma região…",
            es: "Espejo de región…"
        )
        static let unlockAllScreens = LocalizedString(
            en: "Unlock all screens",
            pt: "Desbloquear todas as telas",
            es: "Desbloquear todas las pantallas"
        )
        static let stopMirroring = LocalizedString(
            en: "Stop mirroring",
            pt: "Parar espelhamento",
            es: "Detener espejo"
        )
        static let settings = LocalizedString(
            en: "Settings…",
            pt: "Configurações…",
            es: "Configuración…"
        )
        static let quit = LocalizedString(
            en: "Quit IllusionApp",
            pt: "Sair do IllusionApp",
            es: "Salir de IllusionApp"
        )
    }

    enum Alert {
        static let limitReachedTitle = LocalizedString(
            en: "Limit Reached",
            pt: "Limite Atingido",
            es: "Límite Alcanzado"
        )
        static let ok = LocalizedString(en: "OK", pt: "OK", es: "OK")

        // Parameterised — kept as a function because of string interpolation.
        static func limitReachedMessage(_ language: Language, max: Int) -> String {
            switch language {
            case .english:    return "You can have a maximum of \(max) simultaneous mirror windows. Close one to add another."
            case .portuguese: return "Você pode ter no máximo \(max) janelas espelho simultâneas. Feche uma para adicionar outra."
            case .spanish:    return "Puede tener un máximo de \(max) ventanas espejo simultáneas. Cierre una para agregar otra."
            }
        }
    }

    enum Mirror {
        static let noRegionSelected = LocalizedString(
            en: "No region selected",
            pt: "Nenhuma região selecionada",
            es: "Sin región seleccionada"
        )
        static let openPrivacySettings = LocalizedString(
            en: "Open Privacy Settings",
            pt: "Abrir Configurações de Privacidade",
            es: "Abrir Configuración de Privacidad"
        )
        static let adjustOpacity = LocalizedString(
            en: "Adjust opacity",
            pt: "Ajustar opacidade",
            es: "Ajustar opacidad"
        )
        static let clickToLock = LocalizedString(
            en: "Click to lock",
            pt: "Clique para bloquear",
            es: "Clic para bloquear"
        )
        static let closeMirror = LocalizedString(
            en: "Close mirror",
            pt: "Fechar espelho",
            es: "Cerrar espejo"
        )
        static let permissionRequired = LocalizedString(
            en: "Screen capture permission required. Tap the button below to allow access in System Settings, then try again.",
            pt: "Permissão de captura de tela é necessária. Toque no botão abaixo para permitir o acesso nas Configurações do Sistema e tente novamente.",
            es: "Se requiere permiso de captura de pantalla. Toca el botón de abajo para permitir el acceso en Configuración del Sistema y vuelve a intentarlo."
        )
    }

    enum Selection {
        static let dragToSelect = LocalizedString(
            en: "Drag to select a region to mirror",
            pt: "Arraste para selecionar uma região para espelhar",
            es: "Arrastra para seleccionar una región para espejo"
        )
        static let pressEscToCancel = LocalizedString(
            en: "Press Esc to cancel",
            pt: "Pressione Esc para cancelar",
            es: "Presiona Esc para cancelar"
        )
    }

    enum Settings {
        static let title = LocalizedString(
            en: "Settings",
            pt: "Configurações",
            es: "Configuración"
        )
        static let language = LocalizedString(
            en: "Language",
            pt: "Idioma",
            es: "Idioma"
        )
        static let about = LocalizedString(
            en: "About",
            pt: "Sobre",
            es: "Acerca de"
        )
        static let viewOnGitHub = LocalizedString(
            en: "View on GitHub",
            pt: "Ver no GitHub",
            es: "Ver en GitHub"
        )
        static let version = LocalizedString(
            en: "Version",
            pt: "Versão",
            es: "Versión"
        )
        static let description = LocalizedString(
            en: "A macOS app that mirrors any region of your screen into a floating, always-on-top window.",
            pt: "Um app para macOS que espelha qualquer região da tela em uma janela flutuante sempre visível.",
            es: "Una app de macOS que refleja cualquier región de la pantalla en una ventana flotante siempre visible."
        )
    }
}
