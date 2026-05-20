import Foundation

enum AppStrings {

    // MARK: - Menu
    enum Menu {
        static func mirrorRegion(_ l: Language) -> String {
            switch l {
            case .english:    return "Mirror a region…"
            case .portuguese: return "Espelhar uma região…"
            case .spanish:    return "Espejo de región…"
            }
        }
        static func unlockAllScreens(_ l: Language) -> String {
            switch l {
            case .english:    return "Unlock all screens"
            case .portuguese: return "Desbloquear todas as telas"
            case .spanish:    return "Desbloquear todas las pantallas"
            }
        }
        static func stopMirroring(_ l: Language) -> String {
            switch l {
            case .english:    return "Stop mirroring"
            case .portuguese: return "Parar espelhamento"
            case .spanish:    return "Detener espejo"
            }
        }
        static func settings(_ l: Language) -> String {
            switch l {
            case .english:    return "Settings…"
            case .portuguese: return "Configurações…"
            case .spanish:    return "Configuración…"
            }
        }
        static func quit(_ l: Language) -> String {
            switch l {
            case .english:    return "Quit IllusionApp"
            case .portuguese: return "Sair do IllusionApp"
            case .spanish:    return "Salir de IllusionApp"
            }
        }
    }

    // MARK: - Alerts
    enum Alert {
        static func limitReachedTitle(_ l: Language) -> String {
            switch l {
            case .english:    return "Limit Reached"
            case .portuguese: return "Limite Atingido"
            case .spanish:    return "Límite Alcanzado"
            }
        }
        static func limitReachedMessage(_ l: Language, max: Int) -> String {
            switch l {
            case .english:    return "You can have a maximum of \(max) simultaneous mirror windows. Close one to add another."
            case .portuguese: return "Você pode ter no máximo \(max) janelas espelho simultâneas. Feche uma para adicionar outra."
            case .spanish:    return "Puede tener un máximo de \(max) ventanas espejo simultáneas. Cierre una para agregar otra."
            }
        }
        static func ok(_ l: Language) -> String {
            switch l {
            case .english:    return "OK"
            case .portuguese: return "OK"
            case .spanish:    return "OK"
            }
        }
    }

    // MARK: - Mirror controls
    enum Mirror {
        static func noRegionSelected(_ l: Language) -> String {
            switch l {
            case .english:    return "No region selected"
            case .portuguese: return "Nenhuma região selecionada"
            case .spanish:    return "Sin región seleccionada"
            }
        }
        static func openPrivacySettings(_ l: Language) -> String {
            switch l {
            case .english:    return "Open Privacy Settings"
            case .portuguese: return "Abrir Configurações de Privacidade"
            case .spanish:    return "Abrir Configuración de Privacidad"
            }
        }
        static func adjustOpacity(_ l: Language) -> String {
            switch l {
            case .english:    return "Adjust opacity"
            case .portuguese: return "Ajustar opacidade"
            case .spanish:    return "Ajustar opacidad"
            }
        }
        static func clickToLock(_ l: Language) -> String {
            switch l {
            case .english:    return "Click to lock"
            case .portuguese: return "Clique para bloquear"
            case .spanish:    return "Clic para bloquear"
            }
        }
        static func closeMirror(_ l: Language) -> String {
            switch l {
            case .english:    return "Close mirror"
            case .portuguese: return "Fechar espelho"
            case .spanish:    return "Cerrar espejo"
            }
        }
    }

    // MARK: - Selection overlay
    enum Selection {
        static func dragToSelect(_ l: Language) -> String {
            switch l {
            case .english:    return "Drag to select a region to mirror"
            case .portuguese: return "Arraste para selecionar uma região para espelhar"
            case .spanish:    return "Arrastra para seleccionar una región para espejo"
            }
        }
        static func pressEscToCancel(_ l: Language) -> String {
            switch l {
            case .english:    return "Press Esc to cancel"
            case .portuguese: return "Pressione Esc para cancelar"
            case .spanish:    return "Presiona Esc para cancelar"
            }
        }
    }

    // MARK: - Settings
    enum Settings {
        static func title(_ l: Language) -> String {
            switch l {
            case .english:    return "Settings"
            case .portuguese: return "Configurações"
            case .spanish:    return "Configuración"
            }
        }
        static func language(_ l: Language) -> String {
            switch l {
            case .english:    return "Language"
            case .portuguese: return "Idioma"
            case .spanish:    return "Idioma"
            }
        }
        static func about(_ l: Language) -> String {
            switch l {
            case .english:    return "About"
            case .portuguese: return "Sobre"
            case .spanish:    return "Acerca de"
            }
        }
        static func viewOnGitHub(_ l: Language) -> String {
            switch l {
            case .english:    return "View on GitHub"
            case .portuguese: return "Ver no GitHub"
            case .spanish:    return "Ver en GitHub"
            }
        }
        static func version(_ l: Language) -> String {
            switch l {
            case .english:    return "Version"
            case .portuguese: return "Versão"
            case .spanish:    return "Versión"
            }
        }
        static func description(_ l: Language) -> String {
            switch l {
            case .english:    return "A macOS app that mirrors any region of your screen into a floating, always-on-top window."
            case .portuguese: return "Um app para macOS que espelha qualquer região da tela em uma janela flutuante sempre visível."
            case .spanish:    return "Una app de macOS que refleja cualquier región de la pantalla en una ventana flotante siempre visible."
            }
        }
    }
}
