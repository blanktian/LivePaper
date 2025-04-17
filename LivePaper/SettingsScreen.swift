import SwiftUI
import LaunchAtLogin
import KeyboardShortcuts

private enum SettingsTab: String {
	case general = "通用"
	case shortcuts = "快捷键"
	case advanced = "高级"
}

struct SettingsScreen: View {
	@Default(.language) private var language

	var body: some View {
		TabView {
			generalTab
			shortcutsTab
			advancedTab
		}
		.frame(width: 480)
		.fixedSize()
		.padding()
		.windowLevel(.floating + 1) // To ensure it's always above the Plash browser window.
	}

	private var generalTab: some View {
		Form {
			Section {
				languageSection
			}
			Section {
				LaunchAtLogin.Toggle(NSLocalizedString("settings.launch_at_login", comment: ""))
			}
			Section {
				ReloadIntervalSetting()
				OpacitySetting()
			}
			Section {
				DisplaySetting()
				ShowOnAllSpacesSetting()
			}
		}
		.formStyle(.grouped)
		.tabItem {
			Label {
				Text(NSLocalizedString("settings.general", comment: ""))
			} icon: {
				Image(systemName: "gear")
			}
		}
	}

	private var languageSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				Text(NSLocalizedString("settings.language", comment: ""))
				Spacer()
				Picker("", selection: $language) {
					ForEach(AppLanguage.allCases, id: \.self) { language in
						Text(language.title)
							.tag(language)
							.frame(width: 130, alignment: .trailing)
					}
				}
				.labelsHidden()
				.fixedSize()
				.frame(width: 130, alignment: .trailing)
			}
			Text(NSLocalizedString("settings.language.help", comment: ""))
				.font(.caption)
				.foregroundColor(.secondary)
				.fixedSize(horizontal: false, vertical: true)
		}
		.onChange(of: language) { newValue in
			if newValue != .system {
				UserDefaults.standard.set([newValue.rawValue], forKey: "AppleLanguages")
			} else {
				UserDefaults.standard.removeObject(forKey: "AppleLanguages")
			}
			let alert = NSAlert()
			alert.messageText = NSLocalizedString("settings.language.restart_required", comment: "")
			alert.informativeText = NSLocalizedString("settings.language.restart_message", comment: "")
			alert.addButton(withTitle: NSLocalizedString("dialog.restart_now", comment: ""))
			alert.addButton(withTitle: NSLocalizedString("dialog.restart_later", comment: ""))		
			if alert.runModal() == .alertFirstButtonReturn {
				DispatchQueue.main.async {
					NSApp.terminate(nil)
				}
			}
		}
	}

	private var shortcutsTab: some View {
		Form {
			Section {
				KeyboardShortcuts.Recorder(NSLocalizedString("shortcuts.toggle_enabled", comment: ""), name: .toggleEnabled)
				KeyboardShortcuts.Recorder(NSLocalizedString("shortcuts.toggle_browsing_mode", comment: ""), name: .toggleBrowsingMode)
				KeyboardShortcuts.Recorder(NSLocalizedString("shortcuts.reload", comment: ""), name: .reload)
				KeyboardShortcuts.Recorder(NSLocalizedString("shortcuts.next_website", comment: ""), name: .nextWebsite)
				KeyboardShortcuts.Recorder(NSLocalizedString("shortcuts.previous_website", comment: ""), name: .previousWebsite)
				KeyboardShortcuts.Recorder(NSLocalizedString("shortcuts.random_website", comment: ""), name: .randomWebsite)
			}
		}
		.formStyle(.grouped)
		.tabItem {
			Label {
				Text(NSLocalizedString("settings.shortcuts", comment: ""))
			} icon: {
				Image(systemName: "keyboard")
			}
		}
	}

	private var advancedTab: some View {
		Form {
			Section {
				BringBrowsingModeToFrontSetting()
				Defaults.Toggle(NSLocalizedString("settings.deactivate_on_battery", comment: ""), key: .deactivateOnBattery)
				OpenExternalLinksInBrowserSetting()
				HideMenuBarIconSetting()
				Defaults.Toggle(NSLocalizedString("settings.mute_audio", comment: ""), key: .muteAudio)
			}
			Section {} // Padding
			Section {} footer: {
				ClearWebsiteDataSetting()
					.controlSize(.small)
			}
		}
		.formStyle(.grouped)
		.tabItem {
			Label {
				Text(NSLocalizedString("settings.advanced", comment: ""))
			} icon: {
				Image(systemName: "slider.horizontal.3")
			}
		}
	}
}

private struct ShowOnAllSpacesSetting: View {
	var body: some View {
		Defaults.Toggle(
			NSLocalizedString("settings.show_on_all_spaces", comment: ""),
			key: .showOnAllSpaces
		)
		.help(NSLocalizedString("settings.show_on_all_spaces.help", comment: ""))
	}
}

private struct BringBrowsingModeToFrontSetting: View {
	var body: some View {
		Defaults.Toggle(
			NSLocalizedString("settings.bring_to_front", comment: ""),
			key: .bringBrowsingModeToFront
		)
		.help(NSLocalizedString("settings.bring_to_front.help", comment: ""))
	}
}

private struct OpenExternalLinksInBrowserSetting: View {
	var body: some View {
		Defaults.Toggle(
			NSLocalizedString("settings.open_links_in_browser", comment: ""),
			key: .openExternalLinksInBrowser
		)
		.help(NSLocalizedString("settings.open_links_in_browser.help", comment: ""))
	}
}

private struct OpacitySetting: View {
	@Default(.opacity) private var opacity

	var body: some View {
		Slider(
			value: $opacity,
			in: 0.1...1,
			step: 0.1
		) {
			Text(NSLocalizedString("settings.opacity", comment: ""))
		}
		.help(NSLocalizedString("settings.opacity.help", comment: ""))
	}
}

private struct ReloadIntervalSetting: View {
	private static let defaultReloadInterval = 60.0
	private static let minimumReloadInterval = 0.1

	@Default(.reloadInterval) private var reloadInterval
	@FocusState private var isTextFieldFocused: Bool

	var body: some View {
		LabeledContent(NSLocalizedString("settings.reload_interval", comment: "")) {
			HStack {
				TextField(
					"",
					value: reloadIntervalInMinutes,
					format: .number.grouping(.never).precision(.fractionLength(1))
				)
				.labelsHidden()
				.focused($isTextFieldFocused)
				.frame(width: 40)
				.disabled(reloadInterval == nil)
				Stepper(
					"",
					value: reloadIntervalInMinutes.didSet { _ in
						isTextFieldFocused = false
					},
					in: Self.minimumReloadInterval...(.greatestFiniteMagnitude),
					step: 1
				)
				.labelsHidden()
				.disabled(reloadInterval == nil)
				Text(NSLocalizedString("settings.reload_interval.minutes", comment: ""))
					.textSelection(.disabled)
			}
			.contentShape(.rect)
			Toggle(NSLocalizedString("settings.reload_interval", comment: ""), isOn: $reloadInterval.isNotNil(trueSetValue: Self.defaultReloadInterval))
				.labelsHidden()
				.controlSize(.mini)
				.toggleStyle(.switch)
		}
		.accessibilityLabel(NSLocalizedString("settings.reload_interval.accessibility", comment: ""))
		.contentShape(.rect)
	}

	private var reloadIntervalInMinutes: Binding<Double> {
		$reloadInterval.withDefaultValue(Self.defaultReloadInterval).secondsToMinutes
	}
}

private struct HideMenuBarIconSetting: View {
	@State private var isShowingAlert = false

	var body: some View {
		Defaults.Toggle(NSLocalizedString("settings.hide_menu_bar_icon", comment: ""), key: .hideMenuBarIcon)
			.onChange {
				isShowingAlert = $0
			}
			.alert2(
				NSLocalizedString("settings.hide_menu_bar_icon.alert", comment: ""),
				isPresented: $isShowingAlert
			)
	}
}

private struct DisplaySetting: View {
	@ObservedObject private var displayWrapper = Display.observable
	@Default(.display) private var chosenDisplay

	var body: some View {
		Picker(
			selection: $chosenDisplay.getMap(\.?.withFallbackToMain)
		) {
			ForEach(displayWrapper.wrappedValue.all) { display in
				Text(display.localizedName)
					.tag(display)
			}
		} label: {
			Text(NSLocalizedString("settings.display", comment: ""))
			Link(NSLocalizedString("settings.display.multi_monitor", comment: ""), destination: "https://github.com/sindresorhus/Plash/issues/2")
		}
		.task(id: chosenDisplay) {
			guard chosenDisplay == nil else {
				return
			}

			chosenDisplay = .main
		}
	}
}

private struct ClearWebsiteDataSetting: View {
	@State private var hasCleared = false

	var body: some View {
		// Not marked as destructive as it should mostly be used when it's together with other buttons.
		Button(NSLocalizedString("settings.clear_website_data", comment: "")) {
			Task {
				hasCleared = true
				WebsitesController.shared.thumbnailCache.removeAllImages()
				await AppState.shared.webViewController.webView.clearWebsiteData()
			}
		}
		.help(NSLocalizedString("settings.clear_website_data.help", comment: ""))
		.disabled(hasCleared)
	}
}

#Preview {
	SettingsScreen()
}
