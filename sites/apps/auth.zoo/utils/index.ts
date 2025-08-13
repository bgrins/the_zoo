export { renderPage, type RenderPageOptions } from "./renderPage.js";

// Scope descriptions for OAuth consent
export function getScopeDescription(scope: string): string {
  const scopeDescriptions: Record<string, string> = {
    openid: "Access your basic profile information",
    email: "Access your email address",
    profile: "Access your profile information",
    offline_access: "Access your data when you're not present",
    offline: "Keep you logged in",
  };
  return scopeDescriptions[scope] || scope;
}

// Format domain name for display
export function formatDomainName(domain: string): string {
  return domain
    .replace(".zoo", "")
    .split(".")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

// User session tracking
export const userSessions = new Map<string, { loginTime: Date; lastActive: Date }>();
