import type { Request, Response, NextFunction } from "express";
import { renderErrorPage } from "./utils/index.js";

// Middleware to check if user is authenticated
export function requireAuth(req: Request, res: Response, next: NextFunction): void {
  if (!req.session.user) {
    res.redirect("/");
    return;
  }
  next();
}

// Rejects a form unless each required field, and each optional one it has, is a string:
// the body parser turns `a[b]=1` into an object and a repeated field into an array
export function requireFormFields(required: string[], optional: string[] = []) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const body: Record<string, unknown> = req.body ?? {};
    if (
      !required.every((name) => typeof body[name] === "string") ||
      !optional.every((name) => body[name] === undefined || typeof body[name] === "string")
    ) {
      res.status(400).send(renderErrorPage("Invalid form submission"));
      return;
    }
    next();
  };
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
