import SwiftUI
import LinkPresentation

@MainActor
final class WebsitesController {
	static let shared = WebsitesController()

	private var cancellables = Set<AnyCancellable>()
	private var _current: Website? { all.first(where: \.isCurrent) }
	private var nextCurrent: Website? { all.elementAfterOrFirst(_current) }
	private var previousCurrent: Website? { all.elementBeforeOrLast(_current) }

	var randomWebsiteIterator = Defaults[.websites].infiniteUniformRandomSequence().makeIterator()

	@MainActor let thumbnailCache = SimpleImageCache<String>(diskCacheName: "websiteThumbnailCache")

	/**
	The current website.
	*/
	var current: Website? {
		get { _current ?? all.first }
		set {
			guard let newValue else {
				all = all.modifying {
					$0.isCurrent = false
				}

				return
			}

			makeCurrent(newValue)
		}
	}

	/**
	All websites.
	*/
	var all: [Website] {
		get { Defaults[.websites] }
		set {
			Defaults[.websites] = newValue
		}
	}

	let allBinding = Defaults.bindingCollection(for: .websites)

	private init() {
		setUpEvents()
		thumbnailCache.prewarmCacheFromDisk(for: all.map(\.thumbnailCacheKey))
		// 如果是第一次启动（没有任何网站），添加默认网站
		if all.isEmpty {
			addDefaultWebsites()
		}
	}

	/// 添加默认网站
	private func addDefaultWebsites() {
		// 腾讯日历
		let calendar = add(
			URL(string: "https://rili.tencent.com")!,
			title: "腾讯日历",
			isBuiltIn: true
		)
		calendar.wrappedValue.css = """
		* {background-color: transparent!important;color:#fff!important;}
		.web-header_content-w__jbQXu{display:block!important;text-align:center!important;}
		.login-page-container,.web-header_component-web-header__eA8yu .web-header_header-fixed__luK85{background: none!important;box-shadow:none!important;}
		.login-page-container-zone-bg,.go-to-home-btn,.big-calendar-header,.sideBar_sideBarBox__Ivm66{display: none!important;}
		.mp-qrcode-component-qrcode-container{background: #fff!important;border-radius: 10px!important;}
		.mp-qrcode-component-qrcode-mask{background: #f7f8fb!important;}
		.mp-qrcode-component-title,.mp-qrcode-component-sub-title{color:#333!important;}
		.calendar-month{color:#fff!important;margin-bottom: -1px;}
		.big-calendar .months{border-color:rgba(255,255,255,.3)!important;}
		.big-calendar-day-lunar.holiday{color:#029076!important;font-weight:700;}
		.big-calendar-day-num .duty.on{background-color:#00b996!important;}
		.big-calendar-day-num .duty.off{background-color:#ff434d!important;}
		.big-calendar-day-num .today{background-color:rgba(255,255,255,.3)!important;}
		.big-calendar-day-num .today:after{content: "";position: absolute;left: 0;right: 0;top: 0;bottom:0;background-color:rgba(255,255,255,.1)!important;}
		.calendar-month .calendar-month-week{border-bottom: 1px solid rgba(255, 255, 255, .3);box-shadow:none!important;border-top:none!important;}
		.big-calendar-week{height:30px!important;line-height: 30px!important;}
		.big-calendar-day-num .not-month{color:#999da8!important;}
		.switch_calendar-switch__tFYr_{background-color: #999da8 !important;}
		.switch_calendar-switch__tFYr_.switch_calendar-switch-is-checked__7vK5A,{background-color: #0e62ff !important;}
		.detail-modal,.calendar-month-modal-body{background: rgba(0, 0, 0, .8) !important;}
		popup-select_popup-select__dropdown-outer__3A5oT,.calendar-date-picker-content,.select_calendar-select__dropdown-outer__GQcTJ,.content_CalendarSelectContent__EikNv,.popup-select_popup-select__dropdown-inner__2hF9R{background: rgba(0, 0, 0, 1) !important;}
		.schedule-list-item.show-time {background: rgba(255, 255, 255, .3)!important;margin: 0 5px 5px 5px!important;border-radius: 3px!important;padding: 0 3px!important;}
		.detail-modal .modal-arrow{border-right-color:rgba(0, 0, 0, .8) !important;}
		"""

		// 必应每日壁纸
		let bingWallpaper = add(
			URL(string: "https://bing.biturl.top/?resolution=3840&format=image&index=0&mkt=zh-CN")!,
			title: "必应每日壁纸",
			isBuiltIn: true
		)
		bingWallpaper.wrappedValue.css = "body { background-color: black; }\nimg { object-fit: cover; width: 100vw; height: 100vh; }"

		// Windy Weather
		let windy = add(
			URL(string: "https://www.windy.com/-temp-temp")!,
			title: "Windy Weather",
			isBuiltIn: true
		)
		windy.wrappedValue.css = """
		#search,.rhpane,#plugin-startup-whats-new,#plugin-startup-articles.open{display:none!important;}
		"""

		// Archillect TV
		let archillect = add(
			URL(string: "https://archillect.com/tv")!,
			title: "Archillect TV",
			isBuiltIn: true
		)
		archillect.wrappedValue.css = """
		#notification{display: none;}
		"""
		archillect.wrappedValue.javaScript = """
		(function () {
		  const disableSoundCloud = () => {
		    const iframe = document.getElementById("scwidget");
		    if (iframe) {
		      iframe.remove(); // 或 iframe.style.display = "none";
		      console.log("[SoundCloud] 已禁止播放");
		    }
		  };

		  // 初始清除
		  disableSoundCloud();

		  // 监听是否被重新添加
		  const observer = new MutationObserver(disableSoundCloud);
		  observer.observe(document.body, { childList: true, subtree: true });
		})();
		"""

		// BB-8
		let bb8 = add(
			URL(string: "https://origakid.top/wallpaper/bb8/")!,
			title: "BB-8",
			isBuiltIn: true
		)

		// Google Calendar
		let googleCalendar = add(
			URL(string: "https://calendar.google.com")!,
			title: "Google Calendar",
			isBuiltIn: true
		)
		googleCalendar.wrappedValue.css = """
		* {background-color: transparent !important;color: white !important;}
		.V8Lvo,.gb_Fa.gb_2a,.QQYuzf,.dwlvNd,.gboEAb,.Kk7lMc-QWPxkf-LgbsSe-haAclf{display:none!important;}
		.nfCJAf{margin-left: -1px!important;border-radius: 0px!important;}
		.wuX2hf{border-bottom: var(--gm3-sys-color-surface-container-highest) 1px solid!important;}
		.kbf0gd{margin-top: 8px!important;}
		[role="grid"] * {border-color: rgba(255, 255, 255, 0.3) !important;}
		[data-chips-dialog] {background-color: rgba(0 0 0 / 80%) !important;}
		.tNDBE:not(.Wyo4Qe),.SGWAac,.QIadxc:last-child {border: none !important;}
		.SGWAac{height: calc(100%)!important;}
		.ogB5bf{margin-bottom: -1px!important;}
		.Po94xd{padding-left: 8px!important;}
		.qLWd9c{border-right:none!important;}
		.KF4T6b.jKgTF{background-color: rgba(255, 255, 255, 0.1) !important;}
		.t6NDEb,.p9lUpf{background: #333!important;}
		.gHQcAb,.uW2Fw-P5QLlc,.dgjdGd .l0fHie,.tB5Jxf-xl07Ob-S5Cmsd{background: #666!important;}
		.RCXPcd{position: relative!important;}
		.w48V4c.F262Ye:after {position: absolute;content: "";background-color: rgba(255, 255, 255, 0.1)!important;left: 0;right: 0;top: 0;bottom: 0;z-index: -1;}
		"""

		// Google Street View
		let streetView = add(
			URL(string: "https://randomstreetview.com/")!,
			title: "Google Street View",
			isBuiltIn: true
		)
		streetView.wrappedValue.css = """
		#smallad, #adnotice, #mainad, #controls, #minimaximize, #address, #intro, .gmnoprint, #intro_bg1, #intro_bg2, #intro_bg3, #intro_bg4{display: none!important;}
		#map_canvas{top: 10px!important;}
		"""
		streetView.wrappedValue.javaScript = """
		setInterval(() => {
		  const nextButton = document.getElementById('next');
		  if (nextButton) {
		    nextButton.click();
		    console.log('Clicked #next at', new Date().toLocaleTimeString());
		  } else {
		    console.warn('Element #next not found');
		  }
		}, 60000); // 每 60 秒执行一次
		"""

		// Google Earth
		let googleEarth = add(
			URL(string: "https://random.earth")!,
			title: "Google Earth",
			isBuiltIn: true
		)
		googleEarth.wrappedValue.css = """
		#about-box,.modal-backdrop.in,#search-box,#topmenu,#controls-box,#userinfo,#prev,#next,.gmnoprint,#disclaimer{display:none!important;}
		#address{top:25px!important;}
		"""
		googleEarth.wrappedValue.javaScript = """
		setInterval(() => {
		  const nextButton = document.getElementById('next');
		  if (nextButton) {
		    nextButton.click();
		    console.log('Clicked #next at', new Date().toLocaleTimeString());
		  } else {
		    console.warn('Element #next not found');
		  }
		}, 60000); // 每 60 秒执行一次
		"""

		// Unsplash by Tabliss
		let unsplash = add(
			URL(string: "https://web.tabliss.io")!,
			title: "Unsplash by Tabliss",
			isBuiltIn: true
		)
		unsplash.wrappedValue.css = """
		.controls{right: 0;position: absolute;}
		"""
	}

	private func setUpEvents() {
		Defaults.publisher(.websites)
			.sink { [weak self] change in
				guard let self else {
					return
				}

				// Ensures there's always a current website.
				if
					change.newValue.allSatisfy(!\.isCurrent),
					let website = change.newValue.first
				{
					website.makeCurrent()
				}

				// We only reset the iterator if a website was added/removed.
				if change.newValue.map(\.id) != change.oldValue.map(\.id) {
					randomWebsiteIterator = all.infiniteUniformRandomSequence().makeIterator()
				}
			}
			.store(in: &cancellables)
	}

	/**
	Make a website the current one.
	*/
	private func makeCurrent(_ website: Website) {
		all = all.modifying {
			$0.isCurrent = $0.id == website.id
		}
	}

	/**
	Add a website.
	*/
	@discardableResult
	func add(_ website: Website) -> Binding<Website> {
		// The order here is important.
		all.append(website)
		current = website

		return allBinding[id: website.id]!
	}

	/**
	Add a website from a URL.

	Optionally, specify a title. If no title is given or if the title is empty, a title will be automatically fetched from the website.
	*/
	@discardableResult
	func add(_ websiteURL: URL, title: String? = nil, isBuiltIn: Bool = false) -> Binding<Website> {
		let websiteBinding = add(
			Website(
				id: UUID(),
				isCurrent: true,
				url: websiteURL,
				usePrintStyles: false
			)
		)

		if let title = title?.nilIfEmptyOrWhitespace {
			websiteBinding.wrappedValue.title = title
		} else {
			fetchTitleIfNeeded(for: websiteBinding)
		}

		websiteBinding.wrappedValue.isBuiltIn = isBuiltIn
		return websiteBinding
	}

	/**
	Remove a website.
	*/
	func remove(_ website: Website) {
		all = all.removingAll(website)
	}

	/**
	Makes the next website the current one.
	*/
	func makeNextCurrent() {
		guard let nextCurrent else {
			return
		}

		makeCurrent(nextCurrent)
	}

	/**
	Makes the previous website the current one.
	*/
	func makePreviousCurrent() {
		guard let previousCurrent else {
			return
		}

		makeCurrent(previousCurrent)
	}

	/**
	Makes a random website in the list the current one.
	*/
	func makeRandomCurrent() {
		guard let website = randomWebsiteIterator.next() else {
			return
		}

		makeCurrent(website)
	}

	/**
	Fetch the title for a website in the background if the existing title is empty.
	*/
	func fetchTitleIfNeeded(for website: Binding<Website>) {
		guard website.wrappedValue.title.isEmpty else {
			return
		}

		Task {
			let metadataProvider = LPMetadataProvider()
			metadataProvider.shouldFetchSubresources = false

			guard
				let metadata = try? await metadataProvider.startFetchingMetadata(for: website.wrappedValue.url),
				let title = metadata.title
			else {
				return
			}

			website.wrappedValue.title = title
		}
	}
}
