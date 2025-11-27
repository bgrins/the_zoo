// Performance Zoo Shared Script with Matomo Analytics
// This script is auto-injected into all Zoo pages via Caddy

(() => {
  const currentDomain = window.location.hostname;
  console.log(`📊 Shared.js loaded on ${currentDomain}`);

  // Skip tracking on performance.zoo and analytics.zoo to avoid loops
  if (currentDomain === 'performance.zoo' || currentDomain === 'analytics.zoo') {
    console.log(`ℹ️  Skipping tracking for ${currentDomain}`);
    return;
  }

  // Domain to Site ID mapping
  const SITE_IDS = {
    'search.zoo': 2,
    'snappymail.zoo': 1,
    'gitea.zoo': 4,
    'auth.zoo': 5,
    'classifieds.zoo': 6,
    'excalidraw.zoo': 7,
    'focalboard.zoo': 8,
    'lorem-rss.zoo': 9,
    'miniflux.zoo': 10,
    'northwind.zoo': 11,
    'oauth-example.zoo': 12,
    'planka.zoo': 13,
    'utils.zoo': 14,
    'wiki.zoo': 15,
  };

  const siteId = SITE_IDS[currentDomain];

  if (!siteId) {
    console.log(`ℹ️  No site ID configured for ${currentDomain}`);
    return;
  }

  console.log(`📊 Initializing comprehensive tracking for ${currentDomain} (Site ID: ${siteId})`);

  // Initialize Matomo
  window._paq = window._paq || [];
  const _paq = window._paq;

  // ============================================================================
  // PHASE 1: FOUNDATION - Core Navigation & Goal Tracking
  // ============================================================================

  // Enable cross-domain tracking across all .zoo sites
  _paq.push(['enableCrossDomainLinking']);
  _paq.push(['setDomains', ['*.zoo']]);

  // Enable link tracking (downloads, outlinks)
  _paq.push(['enableLinkTracking']);

  // Set custom download extensions relevant to zoo
  _paq.push(['setDownloadExtensions', 'pdf|zip|doc|docx|xls|xlsx|ppt|pptx|txt|json|csv|xml|sql|md']);

  // Disable request queuing to send events immediately (important for agent tracking)
  _paq.push(['disableQueueRequest']);

  // Enable HeartBeat timer for accurate time-on-page tracking (ping every 15s)
  _paq.push(['enableHeartBeatTimer', 15]);

  // Custom Dimensions for Agent Context (dimensions 1-5)
  // These must be configured in Matomo UI first, but we set them here
  const agentContext = {
    agentType: navigator.userAgent.includes('HeadlessChrome') ? 'Playwright/Puppeteer' :
               navigator.userAgent.includes('Chrome') ? 'Chrome-Agent' : 'Unknown',
    sessionId: Date.now().toString(36),
    taskType: 'general', // Can be overridden via window.__zooTracking
    attemptNumber: 1,
  };

  _paq.push(['setCustomDimension', 1, agentContext.agentType]);
  _paq.push(['setCustomDimension', 2, agentContext.sessionId]);
  _paq.push(['setCustomDimension', 3, agentContext.taskType]);
  _paq.push(['setCustomDimension', 4, agentContext.attemptNumber.toString()]);

  // Track initial page view
  _paq.push(['trackPageView']);

  // ============================================================================
  // PHASE 2: INTERACTION TRACKING - Events, Forms, Search
  // ============================================================================

  // Helper function to track events
  function trackEvent(category, action, name, value) {
    _paq.push(['trackEvent', category, action, name, value]);
  }

  // Track all clicks with detailed context
  document.addEventListener('click', (e) => {
    const target = e.target;
    const tagName = target.tagName.toLowerCase();
    const elementId = target.id || 'no-id';
    const elementClass = target.className || 'no-class';
    const elementText = target.textContent?.substring(0, 50) || 'no-text';

    trackEvent('Click', tagName, `${elementId}|${elementClass}|${elementText}`);

    // Track button clicks specifically
    if (tagName === 'button' || target.getAttribute('role') === 'button') {
      trackEvent('Button', 'Click', elementText, Date.now());
    }

    // Track link clicks
    if (tagName === 'a') {
      const href = target.getAttribute('href');
      trackEvent('Link', 'Click', href || 'no-href');
    }
  }, true);

  // Track form interactions
  document.addEventListener('submit', (e) => {
    const form = e.target;
    const formId = form.id || 'no-id';
    const formAction = form.action || 'no-action';

    trackEvent('Form', 'Submit', `${formId}|${formAction}`);
  }, true);

  // Track form field focus (helps understand form completion patterns)
  document.addEventListener('focus', (e) => {
    const target = e.target;
    if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.tagName === 'SELECT') {
      const fieldName = target.name || target.id || 'unnamed-field';
      const fieldType = target.type || 'unknown';
      trackEvent('Form', 'Field Focus', `${fieldType}|${fieldName}`);
    }
  }, true);

  // Track form field blur with value filled status
  document.addEventListener('blur', (e) => {
    const target = e.target;
    if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.tagName === 'SELECT') {
      const fieldName = target.name || target.id || 'unnamed-field';
      const fieldType = target.type || 'unknown';
      const hasValue = target.value.length > 0 ? 'filled' : 'empty';
      trackEvent('Form', 'Field Blur', `${fieldType}|${fieldName}|${hasValue}`);
    }
  }, true);

  // Track search queries (site-specific)
  document.addEventListener('submit', (e) => {
    const form = e.target;
    const searchInput = form.querySelector('input[type="search"], input[name*="search"], input[name*="query"], input[name*="q"]');

    if (searchInput?.value) {
      const query = searchInput.value;
      const category = form.getAttribute('data-search-category') || 'general';
      _paq.push(['trackSiteSearch', query, category, 0]); // resultsCount can be updated later
      trackEvent('Search', 'Query', query);
    }
  }, true);

  // ============================================================================
  // PHASE 3: ERROR TRACKING
  // ============================================================================

  // Track JavaScript errors
  window.addEventListener('error', (e) => {
    const errorMsg = e.message || 'Unknown error';
    const errorFile = e.filename || 'unknown-file';
    const errorLine = e.lineno || 0;
    trackEvent('Error', 'JavaScript', `${errorMsg} at ${errorFile}:${errorLine}`);
  });

  // Track unhandled promise rejections
  window.addEventListener('unhandledrejection', (e) => {
    const reason = e.reason?.message || e.reason || 'Unknown rejection';
    trackEvent('Error', 'Promise Rejection', reason);
  });

  // Track AJAX errors by intercepting fetch
  const originalFetch = window.fetch;
  window.fetch = function(...args) {
    const startTime = Date.now();
    return originalFetch.apply(this, args)
      .then(response => {
        const duration = Date.now() - startTime;
        const url = args[0];

        if (!response.ok) {
          trackEvent('AJAX', 'Error', `${response.status}|${url}`, duration);
        } else {
          trackEvent('AJAX', 'Success', `${response.status}|${url}`, duration);
        }

        return response;
      })
      .catch(error => {
        const duration = Date.now() - startTime;
        trackEvent('AJAX', 'Network Error', `${args[0]}|${error.message}`, duration);
        throw error;
      });
  };

  // ============================================================================
  // PHASE 4: PERFORMANCE TRACKING
  // ============================================================================

  // Track page performance metrics after load
  window.addEventListener('load', () => {
    setTimeout(() => {
      if (window.performance?.timing) {
        const timing = window.performance.timing;
        const navigationStart = timing.navigationStart;

        const metrics = {
          networkTime: timing.responseStart - timing.fetchStart,
          serverTime: timing.responseEnd - timing.requestStart,
          transferTime: timing.responseEnd - timing.responseStart,
          domProcessing: timing.domInteractive - timing.domLoading,
          domCompletion: timing.domComplete - timing.domLoading,
          onloadTime: timing.loadEventEnd - timing.loadEventStart,
        };

        // Track performance metrics
        _paq.push(['setPagePerformanceTiming',
          metrics.networkTime,
          metrics.serverTime,
          metrics.transferTime,
          metrics.domProcessing,
          metrics.domCompletion,
          metrics.onloadTime
        ]);

        // Also track as events for easier querying
        trackEvent('Performance', 'Page Load', 'Total', timing.loadEventEnd - navigationStart);
        trackEvent('Performance', 'DOM Interactive', 'Time', timing.domInteractive - navigationStart);
      }
    }, 100);
  });

  // ============================================================================
  // PHASE 5: CONTENT TRACKING
  // ============================================================================

  // Track visible content impressions after load
  window.addEventListener('load', () => {
    setTimeout(() => {
      // Track all visible content blocks
      _paq.push(['trackVisibleContentImpressions', true, 750]); // check on scroll, interval 750ms
    }, 500);
  });

  // ============================================================================
  // PHASE 6: SESSION PATTERNS & ENGAGEMENT
  // ============================================================================

  // Track scroll depth
  let maxScrollDepth = 0;
  let scrollTimeout;
  window.addEventListener('scroll', () => {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    const scrollHeight = document.documentElement.scrollHeight - window.innerHeight;
    const scrollPercent = Math.round((scrollTop / scrollHeight) * 100);

    if (scrollPercent > maxScrollDepth) {
      maxScrollDepth = scrollPercent;

      clearTimeout(scrollTimeout);
      scrollTimeout = setTimeout(() => {
        trackEvent('Engagement', 'Scroll Depth', `${maxScrollDepth}%`, maxScrollDepth);
      }, 500);
    }
  });

  // Track time on page before leaving
  window.addEventListener('beforeunload', () => {
    const timeOnPage = Math.round((Date.now() - performance.timing.navigationStart) / 1000);
    trackEvent('Engagement', 'Time on Page', currentDomain, timeOnPage);
  });

  // Track visibility changes (tab switching)
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      trackEvent('Engagement', 'Tab Hidden', currentDomain);
    } else {
      trackEvent('Engagement', 'Tab Visible', currentDomain);
    }
  });

  // ============================================================================
  // PUBLIC API for Custom Tracking
  // ============================================================================

  window.__zooTracking = {
    version: '1.0.0',
    siteId: siteId,
    domain: currentDomain,
    matomo: _paq,

    // Track custom event
    trackEvent: trackEvent,

    // Track goal completion
    trackGoal: (goalId, customRevenue) => {
      _paq.push(['trackGoal', goalId, customRevenue]);
    },

    // Update agent context
    setAgentContext: (context) => {
      if (context.agentType) _paq.push(['setCustomDimension', 1, context.agentType]);
      if (context.taskType) _paq.push(['setCustomDimension', 3, context.taskType]);
      if (context.attemptNumber) _paq.push(['setCustomDimension', 4, context.attemptNumber.toString()]);
    },

    // Track custom dimension
    setDimension: (id, value) => {
      _paq.push(['setCustomDimension', id, value]);
    },

    // Track search with results count
    trackSearch: (keyword, category, resultsCount) => {
      _paq.push(['trackSiteSearch', keyword, category, resultsCount]);
    },
  };

  // Load Matomo script
  (() => {
    const u = "//analytics.zoo/";
    _paq.push(['setTrackerUrl', `${u}matomo.php`]);
    _paq.push(['setSiteId', siteId.toString()]);
    const d = document;
    const g = d.createElement('script');
    const s = d.getElementsByTagName('script')[0];
    g.async = true;
    g.src = `${u}matomo.js`;
    s.parentNode.insertBefore(g, s);
  })();

  console.log(`✅ Comprehensive tracking initialized for ${currentDomain}`);
  console.log(`   Use window.__zooTracking to access tracking API`);
})();
