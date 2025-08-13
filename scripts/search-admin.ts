#!/usr/bin/env -S npx tsx

/**
 * Search Admin utility script for managing Meilisearch index
 * Usage: ./scripts/search-admin.ts [command] [args...]
 */

import { execSync } from "node:child_process";
import readline from "node:readline";
import { Buffer } from "node:buffer";

const MEILI_HOST = "http://search-api.zoo";
const MEILI_KEY = "zooMasterKey123456789";
const INDEX = "zoo-pages";
const PROXY = "http://localhost:3128";

interface CurlOptions {
  method?: string;
  headers?: Record<string, string>;
  data?: string;
}

function curl(url: string, options: CurlOptions = {}): string {
  const headers = options.headers || {};
  headers.Authorization = `Bearer ${MEILI_KEY}`;

  let cmd = `curl --proxy ${PROXY} -s`;

  if (options.method) {
    cmd += ` -X ${options.method}`;
  }

  for (const [key, value] of Object.entries(headers)) {
    cmd += ` -H "${key}: ${value}"`;
  }

  if (options.data) {
    cmd += ` -d '${options.data}'`;
  }

  cmd += ` "${url}"`;

  try {
    const output = execSync(cmd, { encoding: "utf8" });
    return output;
  } catch (error) {
    console.error("Error executing curl command:", error);
    process.exit(1);
  }
}

function parseJson(data: string): any {
  try {
    return JSON.parse(data);
  } catch {
    return data;
  }
}

function formatJson(data: any): string {
  if (typeof data === "string") {
    return data;
  }
  return JSON.stringify(data, null, 2);
}

function base64UrlSafe(str: string): string {
  return Buffer.from(str)
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
}

async function prompt(question: string): Promise<string> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer);
    });
  });
}

const commands: Record<string, (args: string[]) => Promise<void>> = {
  async search(args: string[]) {
    const query = args[0];
    if (!query) {
      console.error('Usage: search-admin search "query"');
      process.exit(1);
    }

    console.log(`Searching for: ${query}`);
    const response = curl(
      `${MEILI_HOST}/indexes/${INDEX}/search?q=${encodeURIComponent(query)}&limit=5`,
    );
    console.log(formatJson(parseJson(response)));
  },

  async delete(args: string[]) {
    const url = args[0];
    if (!url) {
      console.error('Usage: search-admin delete "url"');
      process.exit(1);
    }

    const docId = base64UrlSafe(url);
    console.log(`Deleting document with URL: ${url}`);
    console.log(`Document ID: ${docId}`);

    const response = curl(`${MEILI_HOST}/indexes/${INDEX}/documents/${docId}`, {
      method: "DELETE",
    });
    console.log(formatJson(parseJson(response)));
  },

  async "delete-domain"(args: string[]) {
    const domain = args[0];
    if (!domain) {
      console.error('Usage: search-admin delete-domain "domain"');
      process.exit(1);
    }

    console.log(`Deleting all documents from domain: ${domain}`);

    // First, get all document IDs for this domain
    const searchResponse = curl(
      `${MEILI_HOST}/indexes/${INDEX}/search?filter=domain="${domain}"&limit=1000`,
    );
    const searchData = parseJson(searchResponse);

    if (!searchData.hits || searchData.hits.length === 0) {
      console.log(`No documents found for domain: ${domain}`);
      return;
    }

    // Delete each document
    for (const hit of searchData.hits) {
      console.log(`Deleting document: ${hit.id}`);
      const deleteResponse = curl(`${MEILI_HOST}/indexes/${INDEX}/documents/${hit.id}`, {
        method: "DELETE",
      });
      console.log(formatJson(parseJson(deleteResponse)));
    }
  },

  async stats() {
    console.log(`Index statistics for: ${INDEX}`);
    const response = curl(`${MEILI_HOST}/indexes/${INDEX}/stats`);
    console.log(formatJson(parseJson(response)));
  },

  async list(args: string[]) {
    const domain = args[0];
    let filter = "";

    if (domain) {
      console.log(`Listing documents from domain: ${domain}`);
      filter = `&filter=domain="${domain}"`;
    } else {
      console.log("Listing recent documents");
    }

    const response = curl(
      `${MEILI_HOST}/indexes/${INDEX}/search?limit=10&sort=timestamp:desc${filter}`,
    );
    const data = parseJson(response);

    if (data.hits) {
      for (const hit of data.hits) {
        console.log({
          url: hit.url,
          title: hit.title,
          timestamp: hit.timestamp,
        });
      }
    }
  },

  async get(args: string[]) {
    const url = args[0];
    if (!url) {
      console.error('Usage: search-admin get "url"');
      process.exit(1);
    }

    const docId = Buffer.from(url).toString("base64");
    console.log(`Getting document with URL: ${url}`);

    const response = curl(`${MEILI_HOST}/indexes/${INDEX}/documents/${docId}`);
    console.log(formatJson(parseJson(response)));
  },

  async "clear-index"() {
    console.log("WARNING: This will delete ALL documents from the index!");
    const confirm = await prompt("Are you sure you want to clear the entire index? (yes/no): ");

    if (confirm !== "yes") {
      console.log("Operation cancelled");
      return;
    }

    console.log(`Clearing all documents from index: ${INDEX}`);

    const response = curl(`${MEILI_HOST}/indexes/${INDEX}/documents`, {
      method: "DELETE",
    });
    console.log(formatJson(parseJson(response)));

    console.log("\nIndex cleared. You may want to reset the crawler state as well:");
    console.log("  ./scripts/crawler.sh reset");
  },
};

async function showHelp() {
  console.log("Search Admin - Manage the Meilisearch index");
  console.log("");
  console.log("Usage: search-admin [command] [args...]");
  console.log("");
  console.log("Commands:");
  console.log("  search <query>        - Search for documents");
  console.log("  delete <url>          - Delete a specific document by URL");
  console.log("  delete-domain <domain> - Delete all documents from a domain");
  console.log("  get <url>             - Get a specific document by URL");
  console.log("  list [domain]         - List documents (optionally filtered by domain)");
  console.log("  stats                 - Show index statistics");
  console.log("  clear-index           - Delete ALL documents from the index (with confirmation)");
  console.log("");
  console.log("Examples:");
  console.log('  search-admin search "wiki python"');
  console.log('  search-admin delete "http://wiki.zoo/wiki/Python"');
  console.log('  search-admin delete-domain "wiki.zoo"');
  console.log("  search-admin list wiki.zoo");
  console.log('  search-admin get "http://status.zoo"');
}

async function main() {
  const [command, ...args] = process.argv.slice(2);

  if (!command || !commands[command]) {
    await showHelp();
    process.exit(command ? 1 : 0);
  }

  await commands[command](args);
}

main().catch((error) => {
  console.error("Error:", error);
  process.exit(1);
});
