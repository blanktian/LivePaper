import Cocoa

extension AppState {
	private func addInfoMenuItem() {
		guard let website = WebsitesController.shared.current else {
			return
		}

		var url = website.url
		do {
			url = try replacePlaceholders(of: url) ?? url
		} catch {
			error.presentAsModal()
			return
		}

		let maxLength = 30

		if !website.menuTitle.isEmpty {
			let menuItem = menu.addDisabled(website.menuTitle.truncating(to: maxLength))
			menuItem.toolTip = website.tooltip
		}
	}

	private func createSwitchMenu() -> SSMenu {
		let menu = SSMenu()

		for website in WebsitesController.shared.all {
			let menuItem = menu.addCallbackItem(
				website.menuTitle.truncating(to: 40),
				isChecked: website.isCurrent
			) {
				website.makeCurrent()
			}

			menuItem.toolTip = website.tooltip
		}

		return menu
	}

	private func createMoreMenu() -> SSMenu {
		let menu = SSMenu()

		menu.addAboutItem()

		menu.addSeparator()

		menu.addCallbackItem(NSLocalizedString("menu.send_feedback", comment: "")) {
			SSApp.openSendFeedbackPage()
		}

		menu.addSeparator()

		menu.addLinkItem(NSLocalizedString("menu.examples", comment: ""), destination: "https://github.com/sindresorhus/Plash/discussions/136")

		menu.addLinkItem(NSLocalizedString("menu.tips", comment: ""), destination: "https://github.com/sindresorhus/Plash#tips")

		menu.addLinkItem(NSLocalizedString("menu.faq", comment: ""), destination: "https://github.com/sindresorhus/Plash#faq")

		menu.addLinkItem(NSLocalizedString("menu.scripting", comment: ""), destination: "https://github.com/sindresorhus/Plash#scripting")

		menu.addLinkItem(NSLocalizedString("menu.website", comment: ""), destination: "https://sindresorhus.com/plash")

		menu.addSeparator()

		menu.addLinkItem(NSLocalizedString("menu.rate_app", comment: ""), destination: "macappstore://apps.apple.com/app/id1494023538?action=write-review")

		menu.addMoreAppsItem()

		return menu
	}

	private func addWebsiteItems() {
		if let webViewError {
			let errorMessage = NSLocalizedString("error.server_not_found", comment: "")
			menu.addDisabled(errorMessage.toNSAttributedString)
			menu.addSeparator()
		}

		addInfoMenuItem()

		menu.addSeparator()

		if !WebsitesController.shared.all.isEmpty {
			menu.addCallbackItem(
				NSLocalizedString("menu.reload", comment: ""),
				isEnabled: WebsitesController.shared.current != nil
			) { [weak self] in
				self?.loadUserURL()
			}
			.setShortcut(for: .reload)

			menu.addCallbackItem(
				NSLocalizedString("menu.browsing_mode", comment: ""),
				isEnabled: WebsitesController.shared.current != nil,
				isChecked: Defaults[.isBrowsingMode]
			) {
				Defaults[.isBrowsingMode].toggle()

				SSApp.runOnce(identifier: "activatedBrowsingMode") {
					DispatchQueue.main.async {
						NSAlert.showModal(
							title: NSLocalizedString("browsing_mode.tip.title", comment: ""),
							message: NSLocalizedString("browsing_mode.tip.message", comment: "")
						)
					}
				}
			}
			.setShortcut(for: .toggleBrowsingMode)

			menu.addCallbackItem(
				NSLocalizedString("websites.edit", comment: ""),
				isEnabled: WebsitesController.shared.current != nil
			) {
				Constants.openWebsitesWindow()

				NotificationCenter.default.post(name: .showEditWebsiteDialog, object: nil)
			}
		}

		menu.addSeparator()

		if WebsitesController.shared.all.count > 1 {
			menu.addCallbackItem(NSLocalizedString("menu.next", comment: "")) {
				WebsitesController.shared.makeNextCurrent()
			}
			.setShortcut(for: .nextWebsite)

			menu.addCallbackItem(NSLocalizedString("menu.previous", comment: "")) {
				WebsitesController.shared.makePreviousCurrent()
			}
			.setShortcut(for: .previousWebsite)

			menu.addCallbackItem(NSLocalizedString("menu.random", comment: "")) {
				WebsitesController.shared.makeRandomCurrent()
			}
			.setShortcut(for: .randomWebsite)

			menu.addItem(NSLocalizedString("menu.switch", comment: ""))
				.withSubmenu(createSwitchMenu())

			menu.addSeparator()
		}

		menu.addCallbackItem(NSLocalizedString("websites.add", comment: "")) {
			Constants.openWebsitesWindow()

			NotificationCenter.default.post(name: .showAddWebsiteDialog, object: nil)
		}

		menu.addCallbackItem(NSLocalizedString("websites.manage", comment: "")) {
			Constants.openWebsitesWindow()
		}
	}

	func updateMenu() {
		menu.removeAllItems()

		if (isEnabled || isManuallyDisabled) || (!Defaults[.deactivateOnBattery] && powerSourceWatcher?.powerSource.isUsingBattery == false) {
			menu.addCallbackItem(
				isManuallyDisabled ? NSLocalizedString("menu.enable", comment: "") : NSLocalizedString("menu.disable", comment: "")
			) { [self] in
				isManuallyDisabled.toggle()
			}
		}

		menu.addSeparator()

		if isEnabled {
			addWebsiteItems()
		} else if !isManuallyDisabled {
			menu.addDisabled(NSLocalizedString("menu.disabled_on_battery", comment: ""))
		}

		menu.addSeparator()

		menu.addCallbackItem(NSLocalizedString("menu.settings", comment: "")) { [self] in
			SSApp.showSettingsWindow()
		}

		menu.addItem(NSLocalizedString("menu.more", comment: ""))
			.withSubmenu(createMoreMenu())

		menu.addSeparator()

		menu.addCallbackItem(NSLocalizedString("menu.quit", comment: "")) {
			NSApp.terminate(nil)
		}
	}
}
