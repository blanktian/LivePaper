import SwiftUI
import KeyboardShortcuts

enum Constants {
	@MainActor
	static var websitesWindow: NSWindow? {
		NSApp.windows.first { $0.identifier?.rawValue == "websites" }
	}

	@MainActor
	static func openWebsitesWindow() {
		SSApp.forceActivate()
		EnvironmentValues().openWindow(id: "websites")
	}
}

extension Defaults.Keys {
	static let websites = Key<[Website]>("websites", default: [])
	static let isBrowsingMode = Key<Bool>("isBrowsingMode", default: false)

	// Settings
	static let hideMenuBarIcon = Key<Bool>("hideMenuBarIcon", default: false)
	static let opacity = Key<Double>("opacity", default: 1)
	static let reloadInterval = Key<Double?>("reloadInterval")
	static let display = Key<Display?>("display")
	static let deactivateOnBattery = Key<Bool>("deactivateOnBattery", default: false)
	static let showOnAllSpaces = Key<Bool>("showOnAllSpaces", default: false)
	static let bringBrowsingModeToFront = Key<Bool>("bringBrowsingModeToFront", default: false)
	static let openExternalLinksInBrowser = Key<Bool>("openExternalLinksInBrowser", default: false)
	static let muteAudio = Key<Bool>("muteAudio", default: true)

	static let extendPlashBelowMenuBar = Key<Bool>("extendPlashBelowMenuBar", default: false)

	static let language = Key<AppLanguage>("language", default: AppLanguage.system)
}

extension KeyboardShortcuts.Name {
	static let toggleBrowsingMode = Self("toggleBrowsingMode")
	static let toggleEnabled = Self("toggleEnabled")
	static let reload = Self("reload")
	static let nextWebsite = Self("nextWebsite")
	static let previousWebsite = Self("previousWebsite")
	static let randomWebsite = Self("randomWebsite")
}

extension Notification.Name {
	static let showAddWebsiteDialog = Self("showAddWebsiteDialog")
	static let showEditWebsiteDialog = Self("showEditWebsiteDialog")
}

enum AppLanguage: String, CaseIterable, Defaults.Serializable {
	case system = ""
	case english = "en"
	case simplifiedChinese = "zh-Hans"
	case traditionalChinese = "zh-Hant"
	case spanish = "es"
	case french = "fr"
	case german = "de"
	case russian = "ru"
	case portuguese = "pt"
	case japanese = "ja"
	case korean = "ko"
	case arabic = "ar"
	case hindi = "hi"
	case malay = "ms"
	case italian = "it"
	case turkish = "tr"	
	var title: String {
		switch self {
		case .system:
			return NSLocalizedString("settings.language.system", comment: "")
		case .english:
			return NSLocalizedString("settings.language.english", comment: "")
		case .simplifiedChinese:
			return NSLocalizedString("settings.language.chinese_simplified", comment: "")
		case .traditionalChinese:
			return NSLocalizedString("settings.language.chinese_traditional", comment: "")
		case .spanish:
			return NSLocalizedString("settings.language.spanish", comment: "")
		case .french:
			return NSLocalizedString("settings.language.french", comment: "")
		case .german:
			return NSLocalizedString("settings.language.german", comment: "")
		case .russian:
			return NSLocalizedString("settings.language.russian", comment: "")
		case .portuguese:
			return NSLocalizedString("settings.language.portuguese", comment: "")
		case .japanese:
			return NSLocalizedString("settings.language.japanese", comment: "")
		case .korean:
			return NSLocalizedString("settings.language.korean", comment: "")
		case .arabic:
			return NSLocalizedString("settings.language.arabic", comment: "")
		case .hindi:
			return NSLocalizedString("settings.language.hindi", comment: "")
		case .malay:
			return NSLocalizedString("settings.language.malay", comment: "")
		case .italian:
			return NSLocalizedString("settings.language.italian", comment: "")
		case .turkish:
			return NSLocalizedString("settings.language.turkish", comment: "")
		}
	}
}
