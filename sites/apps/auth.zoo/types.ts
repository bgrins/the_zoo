// User types
export interface User {
  id: string;
  username: string;
  email: string;
  name: string;
  password?: string;
  created_at?: Date;
  updated_at?: Date;
}

export interface CreateUserInput {
  username: string;
  email: string;
  name: string;
  password: string;
}

export interface UpdateUserInput {
  email?: string;
  name?: string;
  password?: string;
}

// Session types
export interface SessionUser {
  id: string;
  username: string;
  name: string;
  email: string;
}

export interface UserSession {
  loginTime: Date;
  lastActive: Date;
}

// OAuth/Hydra types
export interface HydraLoginRequest {
  challenge: string;
  requested_scope: string[];
  requested_access_token_audience: string[];
  skip: boolean;
  subject: string;
  client: {
    client_id: string;
    client_name?: string;
  };
  request_url: string;
  session_id?: string;
}

export interface HydraConsentRequest {
  challenge: string;
  requested_scope: string[];
  requested_access_token_audience: string[];
  skip: boolean;
  subject: string;
  client: {
    client_id: string;
    client_name?: string;
  };
  context?: Record<string, any>;
}

export interface HydraAcceptLoginRequest {
  subject: string;
  remember: boolean;
  remember_for: number;
  context?: Record<string, any>;
}

export interface HydraAcceptConsentRequest {
  grant_scope: string[];
  grant_access_token_audience: string[];
  remember: boolean;
  remember_for: number;
  session: {
    access_token: Record<string, any>;
    id_token: Record<string, any>;
  };
}

export interface HydraResponse {
  redirect_to: string;
}

// Email types
export interface EmailOptions {
  to: string;
  subject: string;
  html: string;
}

export interface AppInfo {
  clientName: string;
  clientId: string;
  scopes: string[];
}

// Site registry types
export interface Site {
  domain: string;
  type: string;
  port?: number;
  service?: string;
  onDemand?: boolean;
  description?: string;
  icon?: string;
  hasOAuth?: boolean;
  httpsOnly?: boolean;
}

export interface SitesData {
  sites: Site[];
}

// API Request/Response types
export interface ApiUsersRequest {
  username: string;
  email: string;
  name: string;
  password: string;
}

export interface LoginRequest {
  username: string;
  password: string;
  challenge?: string;
}

export interface ConsentRequest {
  challenge: string;
  submit: "accept" | "deny";
  scopes?: string;
}

export interface ApiResponse<T = any> {
  success?: boolean;
  data?: T;
  error?: string;
}

// Express extensions
declare module "express-session" {
  interface SessionData {
    user?: SessionUser;
  }
}

// Environment variables
export interface ProcessEnv {
  PORT: string;
  DATABASE_URL: string;
  HYDRA_ADMIN_URL: string;
  HYDRA_PUBLIC_URL: string;
  SESSION_SECRET: string;
  EMAIL_FROM?: string;
  SMTP_HOST?: string;
  SMTP_PORT?: string;
  SMTP_USER?: string;
  SMTP_PASS?: string;
}

declare global {
  namespace NodeJS {
    interface ProcessEnv extends ProcessEnv {}
  }
}
