import type { Request, Response, NextFunction } from "express";

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
