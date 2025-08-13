import type { Request, Response, NextFunction } from "express";
import type { SessionUser } from "./types.js";

// Middleware to check if user is authenticated
export function requireAuth(req: Request, res: Response, next: NextFunction): void {
  if (!req.session.user) {
    res.redirect("/");
    return;
  }
  next();
}

// Middleware to check API key
export function requireApiKey(apiKey: string) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const providedKey = req.headers["x-api-key"];
    if (providedKey !== apiKey) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }
    next();
  };
}

// Type guard for session user
export function hasSessionUser(req: Request): req is Request & { session: { user: SessionUser } } {
  return !!req.session?.user;
}

// Type guard for Hydra response
export function isHydraResponse(obj: any): obj is { redirect_to: string } {
  return obj && typeof obj.redirect_to === "string";
}

// Type guard for successful API response
export function isApiSuccess<T>(response: any): response is { success: true; data: T } {
  return response && response.success === true && response.data !== undefined;
}

// Type guard for error API response
export function isApiError(response: any): response is { success: false; error: string } {
  return response && response.success === false && typeof response.error === "string";
}

// Middleware to add request timing
export function requestTiming(req: Request, res: Response, next: NextFunction): void {
  const start = Date.now();
  res.on("finish", () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.originalUrl} - ${res.statusCode} - ${duration}ms`);
  });
  next();
}

// Error handling middleware
export function errorHandler(err: Error, _req: Request, res: Response, next: NextFunction): void {
  console.error("Error:", err);

  if (res.headersSent) {
    next(err);
    return;
  }

  res.status(500).json({
    error: "Internal server error",
    message: process.env.NODE_ENV === "development" ? err.message : undefined,
  });
}
