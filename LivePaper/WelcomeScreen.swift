import Cocoa

extension AppState {
	func showWelcomeScreenIfNeeded() {
		guard SSApp.isFirstLaunch else {
			return
		}

		SSApp.forceActivate()

		NSAlert.showModal(
			title: NSLocalizedString("welcome.title", comment: ""),
			message: NSLocalizedString("welcome.message", comment: ""),
			buttonTitles: [
				NSLocalizedString("welcome.continue", comment: "")
			],
			defaultButtonIndex: -1
		)

		NSAlert.showModal(
			title: NSLocalizedString("welcome.feedback.title", comment: ""),
			message: NSLocalizedString("welcome.feedback.message", comment: ""),
			buttonTitles: [
				NSLocalizedString("welcome.get_started", comment: "")
			]
		)

		// Does not work on macOS 11 or later.
//		statusItemButton.playRainbowAnimation()

		delay(.seconds(1)) { [self] in
			statusItemButton.performClick(nil)
		}
	}
}
