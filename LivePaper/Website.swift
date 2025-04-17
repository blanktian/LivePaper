import Foundation

struct Website: Hashable, Codable, Identifiable, Sendable, Defaults.Serializable {
	let id: UUID
	var isCurrent: Bool
	var url: URL
	@DecodableDefault.EmptyString var title: String
	@DecodableDefault.Custom<InvertColors> var invertColors2
	var usePrintStyles: Bool
	var css = ""
	var javaScript = ""
	@DecodableDefault.False var allowSelfSignedCertificate

	var subtitle: String { url.humanString }

	var menuTitle: String { title.isEmpty ? subtitle : title }

	// The space is there to force `NSMenu` to display an empty line.
	var tooltip: String { "\(title)\n \n\(subtitle)".trimmed }

	var thumbnailCacheKey: String { url.isFileURL ? url.tildePath : (url.host ?? "") }

	@MainActor
	func makeCurrent() {
		WebsitesController.shared.current = self
	}

	@MainActor
	func remove() {
		WebsitesController.shared.remove(self)
	}
}

extension Website {
	enum InvertColors: String, CaseIterable, Codable {
		case never
		case always
		case darkMode

		var title: String {
			switch self {
			case .never:
				NSLocalizedString("settings.invert_colors.never", comment: "")
			case .always:
				NSLocalizedString("settings.invert_colors.always", comment: "")
			case .darkMode:
				NSLocalizedString("settings.invert_colors.dark_mode", comment: "")
			}
		}
	}
}

extension Website.InvertColors: DecodableDefault.Source {
	static let defaultValue = never
}
