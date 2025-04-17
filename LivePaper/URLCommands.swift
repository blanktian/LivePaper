import Cocoa

extension AppState {
	func setUpURLCommands() {
		SSEvents.appOpenURL
			.sink { [self] in
				handleURLCommands($0)
			}
			.store(in: &cancellables)
	}

	private func handleURLCommands(_ urlComponents: URLComponents) {
		guard urlComponents.scheme == "plash" else {
			return
		}

		let command = urlComponents.path
		let parameters = urlComponents.queryDictionary

		func showMessage(_ message: String) {
			SSApp.forceActivate()
			NSAlert.showModal(title: message)
		}

		switch command {
		case "add":
			guard
				let urlString = parameters["url"]?.trimmed,
				let url = URL(string: urlString, encodingInvalidCharacters: false),
				url.isValid
			else {
				showMessage("\"add\" 命令的 URL 无效。")
				return
			}

			WebsitesController.shared.add(url, title: parameters["title"]?.trimmed.nilIfEmpty)
		case "reload":
			reloadWebsite()
		case "next":
			WebsitesController.shared.makeNextCurrent()
		case "previous":
			WebsitesController.shared.makePreviousCurrent()
		case "random":
			WebsitesController.shared.makeRandomCurrent()
		case "toggle-browsing-mode":
			toggleBrowsingMode()
		default:
			showMessage("不支持的命令：\"\(command)\"。")
		}
	}
}
