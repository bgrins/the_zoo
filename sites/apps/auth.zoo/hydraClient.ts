import fetch from "node-fetch";
import type {
  HydraLoginRequest,
  HydraConsentRequest,
  HydraAcceptLoginRequest,
  HydraAcceptConsentRequest,
  HydraResponse,
} from "./types.js";

const HYDRA_ADMIN_URL = process.env.HYDRA_ADMIN_URL || "http://hydra:4445";

export class HydraClient {
  private adminUrl: string;

  constructor(adminUrl: string = HYDRA_ADMIN_URL) {
    this.adminUrl = adminUrl;
  }

  // Get login request
  async getLoginRequest(challenge: string): Promise<HydraLoginRequest> {
    const response = await fetch(
      `${this.adminUrl}/admin/oauth2/auth/requests/login?challenge=${encodeURIComponent(challenge)}`,
    );
    if (!response.ok) {
      throw new Error(`Failed to get login request: ${response.statusText}`);
    }
    return response.json() as Promise<HydraLoginRequest>;
  }

  // Accept login request
  async acceptLoginRequest(
    challenge: string,
    body: HydraAcceptLoginRequest,
  ): Promise<HydraResponse> {
    const response = await fetch(
      `${this.adminUrl}/admin/oauth2/auth/requests/login/accept?challenge=${encodeURIComponent(challenge)}`,
      {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      },
    );
    if (!response.ok) {
      throw new Error(`Failed to accept login request: ${response.statusText}`);
    }
    return response.json() as Promise<HydraResponse>;
  }

  // Get consent request
  async getConsentRequest(challenge: string): Promise<HydraConsentRequest> {
    const response = await fetch(
      `${this.adminUrl}/admin/oauth2/auth/requests/consent?challenge=${encodeURIComponent(challenge)}`,
    );
    if (!response.ok) {
      throw new Error(`Failed to get consent request: ${response.statusText}`);
    }
    return response.json() as Promise<HydraConsentRequest>;
  }

  // Accept consent request
  async acceptConsentRequest(
    challenge: string,
    body: HydraAcceptConsentRequest,
  ): Promise<HydraResponse> {
    const response = await fetch(
      `${this.adminUrl}/admin/oauth2/auth/requests/consent/accept?challenge=${encodeURIComponent(challenge)}`,
      {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      },
    );
    if (!response.ok) {
      throw new Error(`Failed to accept consent request: ${response.statusText}`);
    }
    return response.json() as Promise<HydraResponse>;
  }

  // Reject consent request
  async rejectConsentRequest(
    challenge: string,
    error: string,
    errorDescription: string,
  ): Promise<HydraResponse> {
    const response = await fetch(
      `${this.adminUrl}/admin/oauth2/auth/requests/consent/reject?challenge=${encodeURIComponent(challenge)}`,
      {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          error,
          error_description: errorDescription,
        }),
      },
    );
    if (!response.ok) {
      throw new Error(`Failed to reject consent request: ${response.statusText}`);
    }
    return response.json() as Promise<HydraResponse>;
  }

  // Accept logout request
  async acceptLogoutRequest(challenge: string): Promise<HydraResponse> {
    const response = await fetch(
      `${this.adminUrl}/admin/oauth2/auth/requests/logout/accept?logout_challenge=${encodeURIComponent(challenge)}`,
      {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      },
    );
    if (!response.ok) {
      throw new Error(`Failed to accept logout request: ${response.statusText}`);
    }
    return response.json() as Promise<HydraResponse>;
  }

  // End one browser's login session, leaving the subject's others
  async revokeLoginSession(sessionId: string): Promise<void> {
    const response = await fetch(
      `${this.adminUrl}/admin/oauth2/auth/sessions/login?${new URLSearchParams({ sid: sessionId })}`,
      { method: "DELETE" },
    );
    if (!response.ok) {
      throw new Error(`Failed to revoke login session: ${response.statusText}`);
    }
  }

  // Get consent sessions for a user
  async getConsentSessions(subject: string): Promise<any[]> {
    const response = await fetch(
      `${this.adminUrl}/admin/oauth2/auth/sessions/consent?${new URLSearchParams({ subject })}`,
    );
    if (!response.ok) {
      return [];
    }
    return response.json() as Promise<any[]>;
  }

  // Revoke consent sessions for a user and client. Encoded, so a client ID can't add a
  // parameter such as all=true, which revokes every client's.
  async revokeConsentSessions(subject: string, clientId: string): Promise<void> {
    const response = await fetch(
      `${this.adminUrl}/admin/oauth2/auth/sessions/consent?${new URLSearchParams({ subject, client: clientId })}`,
      {
        method: "DELETE",
      },
    );

    if (!response.ok) {
      throw new Error(`Failed to revoke consent sessions: ${response.statusText}`);
    }
  }
}

// Export singleton instance
export const hydraClient = new HydraClient();
