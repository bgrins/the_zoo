// Performance Zoo Shared Script
// This script will be included by other zoo apps for performance monitoring

(() => {

  console.log("🚀 Performance.zoo shared.js loaded successfully!");
  console.log("📊 Initializing performance monitoring...");

  // Store load timestamp
  const loadTime = new Date().toISOString();
  console.log(`⏰ Script loaded at: ${loadTime}`);

  // Create global performance object if it doesn't exist
  window.__performanceZoo = window.__performanceZoo || {
    version: "1.0.0",
    loadTime: loadTime,
    domain: window.location.hostname,
    initialized: true,
  };

  console.log("✅ Performance.zoo initialized:", window.__performanceZoo);
})();
