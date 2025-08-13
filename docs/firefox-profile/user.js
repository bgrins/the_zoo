// The Zoo Firefox Configuration
// This file configures Firefox for use with The Zoo environment

// Domain Configuration
user_pref("browser.fixup.domainsuffixwhitelist.zoo", true);

// Proxy Configuration - Route all traffic through local proxy
user_pref("network.proxy.type", 1);
user_pref("network.proxy.http", "localhost");
user_pref("network.proxy.http_port", 3128);
user_pref("network.proxy.ssl", "localhost");
user_pref("network.proxy.ssl_port", 3128);
user_pref("network.proxy.share_proxy_settings", true);
user_pref("network.proxy.no_proxies_on", "");

// Homepage and New Tab Configuration
user_pref("browser.startup.page", 3); // Restore session by default
user_pref("browser.startup.homepage", "https://status.zoo");
user_pref("browser.startup.homepage_override.mstone", "ignore"); // Needed for branded builds to prevent opening a second tab on startup
user_pref("browser.newtabpage.activity-stream.newtabWallpapers.wallpaper", "purple");
user_pref("browser.newtabpage.activity-stream.default.sites", "https://status.zoo");
user_pref(
  "browser.newtabpage.pinned",
  '[{"url":"https://status.zoo","title":"The Zoo Status","baseDomain":"status.zoo"}]',
);
user_pref("unifiedAds.tiles.enabled", false);
user_pref("startup.homepage_welcome_url", "https://status.zoo"); // Disable first-run welcome page
user_pref("startup.homepage_welcome_url.additional", "");

// Disable Default Browser Check
user_pref("browser.shell.checkDefaultBrowser", false);

// Search Configuration
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.suggest.searches", false); // Turn off search suggestions in the location bar
user_pref("browser.urlbar.merino.endpointURL", "");
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
user_pref("browser.search.update", false); // Disable updates to search engines
user_pref("browser.search.hiddenOneOffs", "Google,Bing,Amazon.com,DuckDuckGo,eBay,Wikipedia (en)");
user_pref("browser.newtabpage.activity-stream.showSearch", false);
user_pref("browser.newtabpage.activity-stream.showWeather", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", true);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredCheckboxes", false);
user_pref("browser.newtabpage.activity-stream.newtabWallpapers.wallpaper", "red");
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);

// Disable Firefox Account prompts
user_pref("identity.fxaccounts.enabled", false);

// Disable remote data
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("app.shield.optoutstudies.enabled", false);

// Set default search engine name (will need manual selection)
user_pref("browser.search.order.1", "The Zoo Search");

// Update and Security Configuration
user_pref("app.update.checkInstallTime", false); // Disable Firefox old build background check
user_pref("app.update.disabledForTesting", true); // Disable automatically upgrading Firefox
user_pref("app.update.auto", false); // For backward compatibility up to Firefox 64
user_pref("browser.safebrowsing.update.enabled", false); // Disable safe browsing / tracking protection updates

// Browser Behavior Configuration
user_pref("browser.tabs.warnOnClose", false); // Do not warn when closing all open tabs
user_pref("browser.tabs.warnOnCloseOtherTabs", false); // Do not warn when closing all other open tabs
user_pref("browser.warnOnQuit", false); // Don't warn when exiting the browser
user_pref("browser.warnOnQuitShortcut", false); // Don't warn when exiting the browser with shortcut
user_pref("browser.sessionstore.resume_from_crash", false); // Do not restore the last open set of tabs if the browser has crashed
user_pref("browser.startup.couldRestoreSession.count", -1); // Disable session restore infobar

// UI and Notifications
user_pref("browser.contentblocking.introCount", 99); // Don't show the content blocking introduction panel
user_pref("browser.download.panel.shown", true); // Indicate that the download panel has been shown once
user_pref("browser.EULA.override", true); // Do not show the EULA notification
user_pref("browser.uitour.enabled", false); // Disable the UI tour
user_pref("browser.toolbars.bookmarks.visibility", "never"); // Don't show the Bookmarks Toolbar on any tab

// Developer and Testing Configuration
user_pref("browser.aboutConfig.showWarning", false);
user_pref("browser.dom.window.dump.enabled", true); // Enable output for dump()
user_pref("devtools.console.stdout.chrome", true); // Enable chrome console API
