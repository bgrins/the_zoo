import { createHash } from "node:crypto";

export interface Persona {
  fullName: string;
  username: string;
  password: string;
  bio: string;
  role: "admin" | "user" | "developer" | "manager" | "analyst" | "designer" | "qa" | "devops";
}

// uuidv5(NAMESPACE_DNS, "auth.zoo")
const PERSONA_ID_NAMESPACE = "4881815d-a237-52e2-8d0c-95cb5d5c2b4c";

// The persona's auth.zoo user ID, which apps link OAuth logins by: a UUIDv5 of the username,
// so every seed produces the IDs the golden dumps record
export function personaId(username: string): string {
  const hash = createHash("sha1")
    .update(Buffer.from(PERSONA_ID_NAMESPACE.replace(/-/g, ""), "hex"))
    .update(username)
    .digest();
  hash[6] = (hash[6] & 0x0f) | 0x50;
  hash[8] = (hash[8] & 0x3f) | 0x80;
  const hex = hash.toString("hex", 0, 16);
  return [8, 12, 16, 20].reduceRight((id, at) => `${id.slice(0, at)}-${id.slice(at)}`, hex);
}

// Mattermost and Focalboard require 8+ character passwords
export function minLengthPassword(password: string): string {
  return password.padEnd(8, "!");
}

// Members of Mattermost's private "platform" team (engineering-focused) besides "zoo"
export const platformTeamMembers = [
  "alice",
  "frank",
  "grace",
  "alex.chen",
  "blake.sullivan",
  "eve",
];

export const personas: Persona[] = [
  {
    fullName: "System Administrator",
    username: "admin",
    password: "admin123",
    bio: "Senior system administrator with 15+ years managing enterprise infrastructure. Specializes in security hardening and automation.",
    role: "admin",
  },
  {
    fullName: "Alice Johnson",
    username: "alice",
    password: "alice123",
    bio: "Full-stack developer passionate about React and TypeScript. Contributes to open source projects and mentors junior developers.",
    role: "developer",
  },
  {
    fullName: "Robert 'Bob' Smith",
    username: "bob",
    password: "bob123",
    bio: "Product manager with a background in UX design. Focuses on user-centric development and agile methodologies.",
    role: "manager",
  },
  {
    fullName: "Charles Brown",
    username: "charlie",
    password: "charlie123",
    bio: "Data analyst specializing in business intelligence and predictive modeling. Expert in SQL and Python data science libraries.",
    role: "analyst",
  },
  {
    fullName: "Diana Prince",
    username: "diana",
    password: "diana123",
    bio: "UI/UX designer with a keen eye for accessibility and inclusive design. Creates beautiful, functional interfaces that delight users.",
    role: "designer",
  },
  {
    fullName: "Evelyn Torres",
    username: "eve",
    password: "eve123",
    bio: "QA engineer dedicated to test automation and continuous improvement. Advocates for shift-left testing practices.",
    role: "qa",
  },
  {
    fullName: "Franklin Castle",
    username: "frank",
    password: "frank123",
    bio: "DevOps engineer specializing in Kubernetes and cloud infrastructure. Automates everything that moves.",
    role: "devops",
  },
  {
    fullName: "Grace Hopper",
    username: "grace",
    password: "grace123",
    bio: "Senior software engineer with expertise in distributed systems and microservices. Named after the legendary computer scientist.",
    role: "developer",
  },
  {
    fullName: "Demo User",
    username: "demo",
    password: "demo123",
    bio: "Demo account for showcasing platform features to potential users and stakeholders.",
    role: "user",
  },
  {
    fullName: "Test User One",
    username: "user1",
    password: "password",
    bio: "Basic test account used for automated testing and QA verification workflows.",
    role: "user",
  },
  {
    fullName: "Alexander Chen",
    username: "alex.chen",
    password: "Password.123",
    bio: "Backend developer specializing in API design and database optimization. Advocates for clean code and comprehensive documentation.",
    role: "developer",
  },
  {
    fullName: "Blake Sullivan",
    username: "blake.sullivan",
    password: "Password.123",
    bio: "Engineering manager leading a team of 12 developers. Former developer who still loves to code and stays hands-on with the technology.",
    role: "manager",
  },
  {
    fullName: "Mallory Mercer",
    username: "mallory",
    password: "mallory123",
    bio: "Product designer shaping intuitive user experiences. Former illustrator who brings a creative eye to digital design while staying deeply involved in usability research.",
    role: "user",
  },
  {
    fullName: "Analytics Administrator",
    username: "analytics_user",
    password: "analytics_pw",
    bio: "Analytics platform administrator managing Matomo web analytics. Monitors site traffic, user behavior, and conversion metrics.",
    role: "admin",
  },
];
