import SwiftUI
import LinkPresentation

struct AddWebsiteScreen: View {
	@Environment(\.dismiss) private var dismiss
	@State private var hostingWindow: NSWindow?
	@State private var isFetchingTitle = false
	@State private var isApplyConfirmationPresented = false
	@State private var originalWebsite: Website?
	@State private var urlString = ""

	@State private var newWebsite = Website(
		id: UUID(),
		isCurrent: true,
		url: ".",
		usePrintStyles: false
	)

	private var isURLValid: Bool {
		URL.isValid(string: urlString)
			&& website.wrappedValue.url.isValid
	}

	private var hasChanges: Bool { website.wrappedValue != originalWebsite }

	private let isEditing: Bool

	// TODO: `@OptionalBinding` extension?
	private var existingWebsite: Binding<Website>?

	private var website: Binding<Website> { existingWebsite ?? $newWebsite }

	init(
		isEditing: Bool,
		website: Binding<Website>?
	) {
		self.isEditing = isEditing
		self.existingWebsite = website
		self._originalWebsite = .init(wrappedValue: website?.wrappedValue)

		if isEditing {
			self._urlString = .init(wrappedValue: website?.wrappedValue.url.absoluteString ?? "")
		}
	}

	var body: some View {
		Form {
			topView
			if SSApp.isFirstLaunch, !isEditing {
				firstLaunchView
			}
			if isEditing {
				editingView
			}
		}
		.formStyle(.grouped)
		.frame(width: 500)
		.fixedSize()
		.bindHostingWindow($hostingWindow)
		// Note: Current only works when a text field is focused. (macOS 11.3)
		.onExitCommand {
			guard
				isEditing,
				hasChanges
			else {
				dismiss()
				return
			}

			isApplyConfirmationPresented = true
		}
		.onSubmit {
			submit()
		}
		.confirmationDialog2(
			"保留更改？",
			isPresented: $isApplyConfirmationPresented
		) {
			Button("保留") {
				dismiss()
			}
			Button("不保留", role: .destructive) {
				revert()
				dismiss()
			}
			Button("取消", role: .cancel) {}
		}
		.toolbar {
			if isEditing {
				ToolbarItem {
					Button(NSLocalizedString("dialog.revert", comment: "")) {
						revert()
					}
					.disabled(!hasChanges)
				}
			} else {
				ToolbarItem(placement: .cancellationAction) {
					Button(NSLocalizedString("dialog.cancel", comment: "")) {
						dismiss()
					}
				}
			}
			ToolbarItem(placement: .confirmationAction) {
				Button(isEditing ? NSLocalizedString("dialog.done", comment: "") : NSLocalizedString("dialog.add", comment: "")) {
					submit()
				}
				.disabled(!isURLValid)
			}
		}
		.task {
			guard isEditing else {
				return
			}

			website.wrappedValue.makeCurrent()
		}
	}

	private var firstLaunchView: some View {
		Section {
			HStack {
				HStack(spacing: 3) {
					Text(NSLocalizedString("add_website.example", comment: ""))
					Button(NSLocalizedString("add_website.example.show_time", comment: "")) {
						urlString = "https://time.pablopunk.com/?seconds&fg=white&bg=transparent"
					}
					.buttonStyle(.link)
				}
				Spacer()
				Link(NSLocalizedString("settings.more_ideas", comment: ""), destination: "https://github.com/sindresorhus/Plash/discussions/136")
					.buttonStyle(.link)
			}
		}
	}

	private var topView: some View {
		Section {
			TextField(NSLocalizedString("add_website.url", comment: ""), text: $urlString)
				.textContentType(.URL)
				.lineLimit(1)
				// This change listener is used to respond to URL changes from the outside, like the "Revert" button or the Shortcuts actions.
				.onChange(of: website.wrappedValue.url) { _, url in
					guard
						url.absoluteString != "-",
						url.absoluteString != urlString
					else {
						return
					}

					urlString = url.absoluteString
				}
				.onChange(of: urlString) {
					guard let url = URL(humanString: urlString) else {
						// Makes the "Revert" button work if the user clears the URL field.
						if urlString.trimmed.isEmpty {
							website.wrappedValue.url = "-"
						} else if
							let url = URL(string: urlString, encodingInvalidCharacters: false),
							url.isValid
						{
							website.wrappedValue.url = url
						}

						return
					}

					guard url.isValid else {
						return
					}

					website.wrappedValue.url = url
						.normalized(
							removeDefaultPort: false, // We need to allow typing `http://172.16.0.100:8080`.
							removeWWW: false // Some low-quality sites don't work without this.
						)
				}
				.debouncingTask(id: website.wrappedValue.url, interval: .seconds(0.5)) {
					await fetchTitle()
				}
			TextField(NSLocalizedString("add_website.title", comment: ""), text: website.title)
				.lineLimit(1)
				.disabled(isFetchingTitle)
				.overlay(alignment: .leading) {
					if isFetchingTitle {
						ProgressView()
							.controlSize(.small)
							.offset(x: 50)
					}
				}
		} footer: {
			Button(NSLocalizedString("add_website.local_website", comment: "")) {
				Task {
					let url = await chooseLocalWebsite()
					if let url {
						urlString = url.absoluteString
					} else {
						return
					}
				}
			}
			.controlSize(.small)
		}
	}

	@ViewBuilder
	private var editingView: some View {
		Section {
			EnumPicker(NSLocalizedString("website.invert_colors", comment: ""), selection: website.invertColors2) { value in
				Text(value.title)
			}
			.help(NSLocalizedString("website.invert_colors.help", comment: ""))
			Toggle(NSLocalizedString("website.use_print_styles", comment: ""), isOn: website.usePrintStyles)
				.help(NSLocalizedString("website.use_print_styles.help", comment: ""))
			let cssHelpText = NSLocalizedString("website.css.help", comment: "")
			VStack(alignment: .leading) {
				HStack {
					Text(NSLocalizedString("website.css", comment: ""))
					Spacer()
					InfoPopoverButton(cssHelpText)
						.controlSize(.small)
				}
				ScrollableTextView(
					text: website.css,
					font: .monospacedSystemFont(ofSize: 11, weight: .regular),
					isAutomaticQuoteSubstitutionEnabled: false,
					isAutomaticDashSubstitutionEnabled: false,
					isAutomaticTextReplacementEnabled: false,
					isAutomaticSpellingCorrectionEnabled: false
				)
				.frame(height: 70)
			}
			.accessibilityElement(children: .combine)
			.accessibilityLabel("CSS")
			.accessibilityHint(Text(cssHelpText))
			let jsHelpText = NSLocalizedString("website.javascript.help", comment: "")
			VStack(alignment: .leading) {
				HStack {
					Text(NSLocalizedString("website.javascript", comment: ""))
					Spacer()
					InfoPopoverButton(jsHelpText)
						.controlSize(.small)
				}
				ScrollableTextView(
					text: website.javaScript,
					font: .monospacedSystemFont(ofSize: 11, weight: .regular),
					isAutomaticQuoteSubstitutionEnabled: false,
					isAutomaticDashSubstitutionEnabled: false,
					isAutomaticTextReplacementEnabled: false,
					isAutomaticSpellingCorrectionEnabled: false
				)
				.frame(height: 70)
			}
			.accessibilityElement(children: .combine)
			.accessibilityLabel("JavaScript")
			.accessibilityHint(Text(jsHelpText))
		} header: {
			Text(NSLocalizedString("website.advanced", comment: ""))
		}
		Section(NSLocalizedString("website.advanced_settings", comment: "")) {
			Toggle(NSLocalizedString("website.allow_self_signed_certificate", comment: ""), isOn: website.allowSelfSignedCertificate)
		}
	}

	private func submit() {
		guard isURLValid else {
			return
		}

		if isEditing {
			dismiss()
		} else {
			add()
		}
	}

	private func revert() {
		guard let originalWebsite else {
			return
		}

		website.wrappedValue = originalWebsite
	}

	private func add() {
		WebsitesController.shared.add(website.wrappedValue)
		dismiss()

		SSApp.runOnce(identifier: "editWebsiteTip") {
			Task {
				await NSAlert.show(
					title: NSLocalizedString("website.edit_tip", comment: "")
				)
			}
		}
	}

	private func chooseLocalWebsite() async -> URL? {
//		guard let hostingWindow else {
//			return nil
//		}

		let panel = NSOpenPanel()
		panel.canChooseFiles = false
		panel.canChooseDirectories = true
		panel.canCreateDirectories = false
		panel.title = NSLocalizedString("add_website.choose_local.title", comment: "")
		panel.message = NSLocalizedString("add_website.choose_local.message", comment: "")
		panel.prompt = NSLocalizedString("add_website.choose_local.prompt", comment: "")

		// Ensure it's above the window when in "Browsing Mode".
		panel.level = .modalPanel

		let url = website.wrappedValue.url

		if
			isEditing,
			url.isFileURL
		{
			panel.directoryURL = url
		}

		// TODO: Make it a sheet instead when targeting the macOS bug is fixed. (macOS 15.3)
//		let result = await panel.beginSheet(hostingWindow)
		let result = await panel.begin()

		guard
			result == .OK,
			let url = panel.url
		else {
			return nil
		}

		guard url.appendingPathComponent("index.html", isDirectory: false).exists else {
			await NSAlert.show(title: NSLocalizedString("add_website.choose_local.error", comment: ""))
			return await chooseLocalWebsite()
		}

		do {
			try SecurityScopedBookmarkManager.saveBookmark(for: url)
		} catch {
			await error.present()
			return nil
		}

		return url
	}

	private func fetchTitle() async {
		// Ensure we don't erase a user's existing title.
		if
			isEditing,
			!website.title.wrappedValue.isEmpty
		{
			return
		}

		let url = website.wrappedValue.url

		guard url.isValid else {
			website.wrappedValue.title = ""
			return
		}

		withAnimation {
			isFetchingTitle = true
		}

		defer {
			withAnimation {
				isFetchingTitle = false
			}
		}

		let metadataProvider = LPMetadataProvider()
		metadataProvider.shouldFetchSubresources = false
		metadataProvider.timeout = 5

		guard
			let metadata = try? await metadataProvider.startFetchingMetadata(for: url),
			let title = metadata.title
		else {
			if !isEditing || website.wrappedValue.title.isEmpty {
				website.wrappedValue.title = ""
			}

			return
		}

		website.wrappedValue.title = title
	}
}

#Preview {
	AddWebsiteScreen(
		isEditing: false,
		website: nil
	)
}
