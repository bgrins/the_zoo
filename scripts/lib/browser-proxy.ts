export interface BrowserInstance {
  instanceId: string | null;
  project: string;
  proxyUrl: string | null;
}

export function selectBrowserProxy(instances: BrowserInstance[], instance?: string): string {
  const matches = instance
    ? instances.filter((candidate) => [candidate.instanceId, candidate.project].includes(instance))
    : instances;
  if (matches.length !== 1) {
    throw new Error(
      matches.length === 0
        ? `No running Zoo instance${instance ? ` matching "${instance}"` : ""}; start one first`
        : "Multiple Zoo instances are running; set ZOO_BROWSER_INSTANCE to an instance ID or project name",
    );
  }
  if (!matches[0].proxyUrl) {
    throw new Error(`Zoo instance ${matches[0].project} has no published proxy port`);
  }
  return matches[0].proxyUrl;
}
