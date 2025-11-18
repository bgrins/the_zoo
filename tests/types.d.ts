// TypeScript type declarations for analytics tracking

interface ZooTrackingAPI {
  trackEvent(category: string, action: string, name?: string, value?: number): void;
  trackGoal(goalId: number): void;
  setAgentContext(context: { agentType?: string; taskType?: string; attemptNumber?: number }): void;
  trackSearch(keyword: string, category?: string, resultsCount?: number): void;
  version: string;
  siteId: number;
  domain: string;
}

declare global {
  interface Window {
    __zooTracking: ZooTrackingAPI;
    _paq: any[];
  }
}

export {};
