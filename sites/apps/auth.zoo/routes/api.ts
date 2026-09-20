import { Router, type Request, type Response } from "express";
import express from "express";
import db from "../db.js";
import { userService } from "../userService.js";
import { emailService } from "../emailService.js";
import { requireApiKey } from "../middleware.js";
import type { ApiUsersRequest, ApiResponse, User } from "../types.js";

const router = Router();

// API endpoint for creating users programmatically
router.post(
  "/users",
  express.json(),
  requireApiKey("zoo-seed-api-key"),
  async (
    req: Request<Record<string, never>, ApiResponse, ApiUsersRequest>,
    res: Response<ApiResponse>,
  ) => {
    const { id, username, email, name, password } = req.body;

    // Validate required fields
    if (!username || !email || !name || !password) {
      res.status(400).json({ error: "Missing required fields" });
      return;
    }
    if (
      id !== undefined &&
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(id)
    ) {
      res.status(400).json({ error: "id must be a lowercase UUID" });
      return;
    }

    try {
      if (id !== undefined && (await userService.findById(id))) {
        res.status(409).json({ error: "User ID already exists" });
        return;
      }

      // Check if user already exists
      const existingUser = await userService.findByUsername(username);
      if (existingUser) {
        res.status(409).json({ error: "User already exists" });
        return;
      }

      // Check if email already exists
      const existingEmail = await userService.findByEmail(email);
      if (existingEmail) {
        res.status(409).json({ error: "Email already exists" });
        return;
      }

      // Create the user
      const user = await userService.create({
        id,
        username,
        email,
        name,
        password,
      });

      // Send welcome email
      await emailService.sendWelcomeEmail(user);

      res.status(201).json({
        success: true,
        data: {
          id: user.id,
          username: user.username,
          email: user.email,
          name: user.name,
          created_at: user.created_at,
        },
      });
    } catch (error) {
      console.error("Error creating user:", error);
      res.status(500).json({ error: "Internal server error" });
      return;
    }
  },
);

// Get user by ID (protected endpoint example)
router.get(
  "/users/:id",
  requireApiKey("zoo-seed-api-key"),
  async (req: Request<{ id: string }>, res: Response<ApiResponse<User>>) => {
    try {
      const user = await userService.findById(req.params.id);

      if (!user) {
        res.status(404).json({
          success: false,
          error: "User not found",
        });
        return;
      }

      res.json({
        success: true,
        data: {
          id: user.id,
          username: user.username,
          email: user.email,
          name: user.name,
        },
      });
    } catch (error) {
      console.error("Error fetching user:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      });
      return;
    }
  },
);

// Health check endpoint (used by the container healthcheck)
router.get("/health", async (_req: Request, res: Response) => {
  try {
    await db.query("SELECT 1");
    res.json({
      status: "healthy",
      database: "connected",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(503).json({
      status: "unhealthy",
      database: "disconnected",
      error: (error as Error).message,
      timestamp: new Date().toISOString(),
    });
  }
});

export default router;
