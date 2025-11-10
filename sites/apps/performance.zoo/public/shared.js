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
  } else if (currentDomain === 'performance.zoo') {
    console.log("⚡ Initializing Matomo Tag Manager for Performance.zoo...");

    // Matomo Tag Manager
    window._mtm = window._mtm || [];
    const _mtm = window._mtm;
    _mtm.push({'mtm.startTime': Date.now(), 'event': 'mtm.Start'});

    (() => {
      const d = document;
      const g = d.createElement('script');
      const s = d.getElementsByTagName('script')[0];
      g.async = true;
      g.src = 'https://analytics.zoo/js/container_tNJU3NKP.js';
      s.parentNode.insertBefore(g, s);
    })();

    // Expose Tag Manager for custom tracking
    window.__performanceZoo = {
      version: "2.0.0",
      tagManager: _mtm,
      initialized: true,
      // Helper method to push custom events to data layer
      pushEvent: (eventName, data) => {
        _mtm.push({
          'event': eventName,
          ...data
        });
      }
    };

    console.log("✅ Matomo Tag Manager initialized");
  } else {
    console.log(`ℹ️  No tracking configured for ${currentDomain}`);
  }
})();
