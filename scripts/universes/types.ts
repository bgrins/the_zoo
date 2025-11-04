/**
 * Type definitions for The Zoo universe system
 */

/**
 * Main universe metadata configuration
 */
export interface Universe {
  /** Unique identifier, must match directory name */
  id: string;
  /** Human-readable name */
  name?: string;
  /** Description of this universe */
  description?: string;
  /** Semantic version */
  version?: string;
  /** Array of persona usernames to include */
  personas: string[];
}

/**
 * Email message
 */
export interface Email {
  /** Sender email address */
  from: string;
  /** Recipient email address(es) */
  to: string | string[];
  /** Email subject */
  subject: string;
  /** Email body (plain text or HTML) */
  body: string;
  /** ISO 8601 timestamp */
  date?: string;
  /** CC recipients */
  cc?: string | string[];
  /** Whether body contains HTML */
  html?: boolean;
}

/**
 * File to add to a repository
 */
export interface RepositoryFile {
  /** File path relative to repository root */
  path: string;
  /** File content */
  content: string;
  /** Branch name (defaults to defaultBranch) */
  branch?: string;
  /** Commit message (defaults to "Add {path}") */
  message?: string;
}

/**
 * Git repository
 */
export interface Repository {
  /** Repository name */
  name: string;
  /** Owner username (must be in personas) */
  owner: string;
  /** Repository description */
  description?: string;
  /** Whether repository is private */
  private?: boolean;
  /** Default branch name */
  defaultBranch?: string;
  /** Initial files to commit */
  files?: RepositoryFile[];
}

/**
 * Gitea app data
 */
export interface GiteaData {
  repositories?: Repository[];
}

/**
 * SnappyMail app data
 */
export interface SnappyMailData {
  emails?: Email[];
}

/**
 * Complete universe data structure
 */
export interface UniverseData {
  universe: Universe;
  apps: {
    "snappymail.zoo"?: SnappyMailData;
    "gitea.zoo"?: GiteaData;
  };
}

/**
 * App seeder interface
 */
export interface AppSeeder {
  /** App name */
  name: string;
  /** Load app data from universe */
  load: (data: UniverseData, personas: string[]) => Promise<void>;
}
