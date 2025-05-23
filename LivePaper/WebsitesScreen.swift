import SwiftUI

struct WebsitesScreen: View {
	@Environment(\.requestReview) private var requestReview
	@Default(.websites) private var websites
	@State private var editedWebsite: Website.ID?
	@State private var isAddWebsiteDialogPresented = false
	@Namespace private var bottomScrollID

	var body: some View {
		Form {
			// 内置选项 Section
			Section {
				ForEach($websites.filter { $0.isBuiltIn.wrappedValue }) { website in
					RowView(
						website: website,
						selection: $editedWebsite
					)
				}
			} header: {
				Text("推荐网站")
			}
			
			// 用户添加的网站
			if !websites.filter({ !$0.isBuiltIn }).isEmpty {
				Section {
					ForEach($websites.filter { !$0.isBuiltIn.wrappedValue }) { website in
						RowView(
							website: website,
							selection: $editedWebsite
						)
					}
				} header: {
					Text("我添加的")
				}
			}
		}
		.onChange(of: websites) { oldWebsites, websites in
			guard websites.count > oldWebsites.count else {
				return
			}
			withAnimation {
//				scrollViewProxy.scrollTo(bottomScrollID, anchor: .top)
			}
		}
		.overlay {
			if websites.isEmpty {
				Text(NSLocalizedString("websites.empty", comment: ""))
					.emptyStateTextStyle()
			}
		}
		.accessibilityAction(named: NSLocalizedString("websites.add", comment: "")) {
			isAddWebsiteDialogPresented = true
		}
		.formStyle(.grouped)
		.frame(width: 480, height: 500)
		.sheet(item: $editedWebsite) { websiteId in
			if let website = websites.first(where: { $0.id == websiteId }), !website.isBuiltIn {
				AddWebsiteScreen(
					isEditing: true,
					website: $websites[id: websiteId]
				)
			}
		}
		.sheet(isPresented: $isAddWebsiteDialogPresented) {
			AddWebsiteScreen(
				isEditing: false,
				website: nil
			)
		}
		.onNotification(.showAddWebsiteDialog) { _ in
			isAddWebsiteDialogPresented = true
		}
		.onNotification(.showEditWebsiteDialog) { _ in
			if let current = WebsitesController.shared.current, !current.isBuiltIn {
				editedWebsite = current.id
			}
		}
		.toolbar {
			Button("Add Website", systemImage: "plus") {
				isAddWebsiteDialogPresented = true
			}
			.keyboardShortcut("+")
		}
		.onAppear {
			SSApp.requestReviewAfterBeingCalledThisManyTimes([3, 50, 500], requestReview)
		}
		.windowMinimizeBehavior(.disabled)
		.windowLevel(.floating)
	}
}

#Preview {
	WebsitesScreen()
}

private struct RowView: View {
	@Binding var website: Website
	@Binding var selection: Website.ID?

	var body: some View {
		HStack {
			Label {
				if let title = website.title.nilIfEmpty {
					Text(title)
				}
				Text(website.subtitle)
			} icon: {
				IconView(website: website)
			}
			.lineLimit(1)
			Spacer()
			if website.isCurrent {
				Image(systemName: "checkmark.circle.fill")
					.renderingMode(.original)
					.font(.title2)
			}
			if website.isBuiltIn {
				Image(systemName: "lock.fill")
					.foregroundStyle(.secondary)
					.font(.caption)
			}
		}
		.frame(height: 64)
		.padding(.horizontal, 8)
		.help(website.tooltip)
		.swipeActions(edge: .leading, allowsFullSwipe: true) {
			Button(NSLocalizedString("websites.make_current", comment: "")) {
				website.makeCurrent()
			}
			.disabled(website.isCurrent)
		}
		.contentShape(.rect)
		.onTapGesture {
			website.makeCurrent()
		}
		.onTapGesture(count: 2) {
			if !website.isBuiltIn {
				selection = website.id
			}
		}
		.contextMenu {
			Button(NSLocalizedString("websites.make_current", comment: "")) {
				website.makeCurrent()
			}
			.disabled(website.isCurrent)
			
			if !website.isBuiltIn {
				Divider()
				Button(NSLocalizedString("websites.edit", comment: "")) {
					selection = website.id
				}
				
				Divider()
				Button(NSLocalizedString("websites.delete", comment: ""), role: .destructive) {
					website.remove()
				}
			}
		}
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.if(website.isCurrent) {
			$0.accessibilityAddTraits(.isSelected)
		}
		.accessibilityAction(named: "Edit") {
			if !website.isBuiltIn {
				selection = website.id
			}
		}
		.accessibilityRepresentation {
			Button(website.menuTitle) {
				if !website.isBuiltIn {
					selection = website.id
				}
			}
		}
	}
}

private struct IconView: View {
	@State private var icon: Image?

	let website: Website

	var body: some View {
		VStack {
			if let icon {
				icon
					.resizable()
					.scaledToFit()
			} else {
				Color.primary.opacity(0.1)
			}
		}
		.frame(width: 32, height: 32)
		.clipShape(.rect(cornerRadius: 4))
		.task(id: website.url) {
			guard let image = await fetchIcons() else {
				return
			}

			icon = Image(nsImage: image)
		}
	}

	private func fetchIcons() async -> NSImage? {
		let cache = WebsitesController.shared.thumbnailCache

		if let image = cache[website.thumbnailCacheKey] {
			return image
		}

		guard let image = try? await WebsiteIconFetcher.fetch(for: website.url) else {
			return nil
		}

		cache[website.thumbnailCacheKey] = image

		return image
	}
}
