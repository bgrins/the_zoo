// Performance Zoo Shared Script with Matomo Analytics
// This script is auto-injected into all Zoo pages via Caddy

(() => {
  const currentDomain = window.location.hostname;
  console.log(`📊 Shared.js loaded on ${currentDomain}`);

  // Initialize Matomo tracking based on domain
  if (currentDomain === 'search.zoo') {
    console.log("🔍 Initializing Matomo tracking for Search...");

    window._paq = window._paq || [];
    const _paq = window._paq;
    _paq.push(['trackPageView']);
    _paq.push(['enableLinkTracking']);
    (() => {
      const u = "//analytics.zoo/";
      _paq.push(['setTrackerUrl', `${u}matomo.php`]);
      _paq.push(['setSiteId', '2']);
      const d = document;
      const g = d.createElement('script');
      const s = d.getElementsByTagName('script')[0];
      g.async = true;
      g.src = `${u}matomo.js`;
      s.parentNode.insertBefore(g, s);
    })();

    console.log("✅ Matomo tracking initialized for Search");
  } else {
    console.log(`ℹ️  No tracking configured for ${currentDomain}`);
  }
})();
