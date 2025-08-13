import bcrypt from "bcryptjs";
import db from "./db.js";
import type { User, CreateUserInput, UpdateUserInput } from "./types.js";

const SALT_ROUNDS = 10;

interface UserWithPassword extends User {
  password_hash: string;
}

export const userService = {
  // Find user by username
  async findByUsername(username: string): Promise<UserWithPassword | undefined> {
    const result = await db.query<UserWithPassword>("SELECT * FROM users WHERE username = $1", [
      username,
    ]);
    return result.rows[0];
  },

  // Find user by email
  async findByEmail(email: string): Promise<UserWithPassword | undefined> {
    const result = await db.query<UserWithPassword>("SELECT * FROM users WHERE email = $1", [
      email,
    ]);
    return result.rows[0];
  },

  // Find user by username or email
  async findByUsernameOrEmail(usernameOrEmail: string): Promise<UserWithPassword | undefined> {
    const result = await db.query<UserWithPassword>(
      "SELECT * FROM users WHERE username = $1 OR email = $1",
      [usernameOrEmail],
    );
    return result.rows[0];
  },

  // Find user by ID
  async findById(id: string): Promise<User | undefined> {
    const result = await db.query<User>("SELECT * FROM users WHERE id = $1", [id]);
    return result.rows[0];
  },

  // Create new user
  async create(userData: CreateUserInput): Promise<User> {
    const { username, email, password, name } = userData;
    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const result = await db.query<User>(
      `INSERT INTO users (username, email, password_hash, name) 
       VALUES ($1, $2, $3, $4) 
       RETURNING id, username, email, name, created_at`,
      [username, email, passwordHash, name],
    );

    return result.rows[0];
  },

  // Verify password
  async verifyPassword(password: string, passwordHash: string): Promise<boolean> {
    return bcrypt.compare(password, passwordHash);
  },

  // Update user
  async update(id: string, updates: UpdateUserInput): Promise<User | undefined> {
    const { name, email } = updates;
    const result = await db.query<User>(
      `UPDATE users 
       SET name = COALESCE($2, name), 
           email = COALESCE($3, email)
       WHERE id = $1
       RETURNING id, username, email, name`,
      [id, name, email],
    );
    return result.rows[0];
  },

  // Change password
  async changePassword(id: string, newPassword: string): Promise<void> {
    const passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);
    await db.query("UPDATE users SET password_hash = $2 WHERE id = $1", [id, passwordHash]);
  },
};
