#!/usr/bin/env -S npx tsx

/**
 * Docker Image Analysis Script
 * Analyzes all Docker images using dive and generates a report
 */

import { execSync, spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { getAllSites } from "./sites-registry";
import { parseDockerCompose } from "./docker-compose-utils";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PROJECT_ROOT = path.join(__dirname, "..");

interface ImageData {
  image: string;
  sizeBytes: number;
  sizeHuman: string;
  wastedBytes: number;
  wastedHuman: string;
  efficiency: string;
  domain: string;
  isCore: boolean;
  description: string;
}

function bytesToHuman(bytes: number): string {
  if (bytes >= 1073741824) {
    return `${(bytes / 1073741824).toFixed(2)}GB`;
  } else if (bytes >= 1048576) {
    return `${(bytes / 1048576).toFixed(1)}MB`;
  } else if (bytes >= 1024) {
    return `${(bytes / 1024).toFixed(1)}kB`;
  }
  return `${bytes}B`;
}

interface ImageMetadata {
  domain: string;
  isCore: boolean;
  description: string;
}

function buildServiceToDomainMap(): Map<string, string> {
  const sites = getAllSites();
  const map = new Map<string, string>();

  for (const site of sites) {
    if (site.service) {
      map.set(site.service, site.domain);
    }
  }

  return map;
}

function getLabel(labels: string[] | Record<string, string> | undefined, key: string): string {
  if (!labels) return "";
  if (Array.isArray(labels)) {
    const match = labels.find((l) => l.startsWith(`${key}=`));
    return match ? match.slice(key.length + 1) : "";
  }
  return labels[key] || "";
}

function buildImageMetadataMap(): Map<string, ImageMetadata> {
  const serviceToDomain = buildServiceToDomainMap();
  const compose = parseDockerCompose();
  const imageMetadata = new Map<string, ImageMetadata>();

  // Get project name from compose config
  const projectName = (compose as any).name || "the_zoo";

  for (const [serviceName, serviceConfig] of Object.entries(compose.services)) {
    const domain = serviceToDomain.get(serviceName) || "";
    const labels = serviceConfig.labels;

    const isCore = getLabel(labels, "zoo.core") === "true";
    const description = getLabel(labels, "zoo.description");

    const metadata: ImageMetadata = { domain, isCore, description };

    // For services with explicit image
    if (serviceConfig.image) {
      imageMetadata.set(serviceConfig.image, metadata);
    }

    // For built images, the pattern is PROJECT_NAME-SERVICE_NAME:latest
    const builtImageName = `${projectName}-${serviceName}:latest`;
    imageMetadata.set(builtImageName, metadata);
  }

  return imageMetadata;
}

function getImages(): string[] {
  try {
    const result = execSync("docker compose images --format json 2>/dev/null", {
      encoding: "utf8",
      cwd: PROJECT_ROOT,
    });
    const images = JSON.parse(result);
    const uniqueImages = new Set<string>();

    for (const img of images) {
      uniqueImages.add(`${img.Repository}:${img.Tag}`);
    }

    return [...uniqueImages].sort();
  } catch {
    console.error("Failed to get images from docker compose");
    return [];
  }
}

function analyzeImage(image: string, imageMetadata: Map<string, ImageMetadata>): ImageData | null {
  // Check if image exists
  const inspectResult = spawnSync("docker", ["image", "inspect", image], {
    encoding: "utf8",
  });

  if (inspectResult.status !== 0) {
    console.log(`  Warning: Image not found locally, skipping...`);
    return null;
  }

  // Run dive with JSON output
  const tempFile = `/tmp/dive-${Date.now()}.json`;
  const diveResult = spawnSync("dive", [image, "--json", tempFile], {
    encoding: "utf8",
    stdio: "pipe",
  });

  if (diveResult.status !== 0 || !fs.existsSync(tempFile)) {
    console.log(`  Warning: Dive analysis failed`);
    return null;
  }

  try {
    const diveData = JSON.parse(fs.readFileSync(tempFile, "utf8"));
    fs.unlinkSync(tempFile);

    const sizeBytes = diveData.image.sizeBytes;
    const wastedBytes = diveData.image.inefficientBytes;
    const efficiencyScore = diveData.image.efficiencyScore;

    const metadata = imageMetadata.get(image) || { domain: "", isCore: false, description: "" };

    return {
      image,
      sizeBytes,
      sizeHuman: bytesToHuman(sizeBytes),
      wastedBytes,
      wastedHuman: bytesToHuman(wastedBytes),
      efficiency: (efficiencyScore * 100).toFixed(4),
      domain: metadata.domain,
      isCore: metadata.isCore,
      description: metadata.description,
    };
  } catch {
    console.log(`  Warning: Failed to parse dive output`);
    if (fs.existsSync(tempFile)) {
      fs.unlinkSync(tempFile);
    }
    return null;
  }
}

function generateTable(
  data: ImageData[],
  includeDomain: boolean,
): { lines: string[]; totalBytes: number } {
  // Sort by size descending
  data.sort((a, b) => b.sizeBytes - a.sizeBytes);

  const maxImageLen = Math.max(40, ...data.map((d) => d.image.length));
  const lines: string[] = [];

  if (includeDomain) {
    const maxDomainLen = Math.max(15, ...data.map((d) => d.domain.length));

    // Header with domain
    lines.push(
      [
        "Image".padEnd(maxImageLen),
        "Domain".padEnd(maxDomainLen),
        "Size".padEnd(12),
        "Wasted Space".padEnd(15),
        "Efficiency".padEnd(12),
      ].join(" | "),
    );

    // Separator
    lines.push(
      [
        "-".repeat(maxImageLen),
        "-".repeat(maxDomainLen),
        "-".repeat(12),
        "-".repeat(15),
        "-".repeat(12),
      ].join("-+-"),
    );

    // Data rows
    for (const d of data) {
      lines.push(
        [
          d.image.padEnd(maxImageLen),
          d.domain.padEnd(maxDomainLen),
          d.sizeHuman.padEnd(12),
          d.wastedHuman.padEnd(15),
          `${d.efficiency}%`.padEnd(12),
        ].join(" | "),
      );
    }
  } else {
    // Header without domain
    lines.push(
      [
        "Image".padEnd(maxImageLen),
        "Size".padEnd(12),
        "Wasted Space".padEnd(15),
        "Efficiency".padEnd(12),
      ].join(" | "),
    );

    // Separator
    lines.push(
      ["-".repeat(maxImageLen), "-".repeat(12), "-".repeat(15), "-".repeat(12)].join("-+-"),
    );

    // Data rows
    for (const d of data) {
      lines.push(
        [
          d.image.padEnd(maxImageLen),
          d.sizeHuman.padEnd(12),
          d.wastedHuman.padEnd(15),
          `${d.efficiency}%`.padEnd(12),
        ].join(" | "),
      );
    }
  }

  const totalBytes = data.reduce((sum, d) => sum + d.sizeBytes, 0);
  return { lines, totalBytes };
}

function generateReport(data: ImageData[]): string {
  // Split into core services and sites based on zoo.core label
  const coreServices = data.filter((d) => d.isCore);
  const sites = data.filter((d) => !d.isCore);

  const totalBytes = data.reduce((sum, d) => sum + d.sizeBytes, 0);

  const lines: string[] = [];

  lines.push("===================================================================");
  lines.push("Docker Image Analysis Report");
  lines.push(`Total images analyzed: ${data.length}`);
  lines.push(`Total size: ${bytesToHuman(totalBytes)}`);
  lines.push("===================================================================");

  // Sites table
  if (sites.length > 0) {
    const sitesTable = generateTable(sites, true);
    lines.push("");
    lines.push(`## Sites (${sites.length} images, ${bytesToHuman(sitesTable.totalBytes)})`);
    lines.push("");
    lines.push(...sitesTable.lines);
  }

  // Core services table
  if (coreServices.length > 0) {
    const coreTable = generateTable(coreServices, false);
    lines.push("");
    lines.push(
      `## Core Services (${coreServices.length} images, ${bytesToHuman(coreTable.totalBytes)})`,
    );
    lines.push("");
    lines.push(...coreTable.lines);
  }

  lines.push("");
  lines.push("Report generated by: analyze-images.ts");
  lines.push("See https://github.com/wagoodman/dive for details on metrics");

  return lines.join("\n");
}

interface JsonImageEntry {
  image: string;
  size: number;
  unit: string;
  label: string;
}

interface JsonReport {
  totalSize: string;
  sites: JsonImageEntry[];
  coreServices: JsonImageEntry[];
}

function formatSizeWithUnit(bytes: number): { size: number; unit: string } {
  if (bytes >= 1073741824) {
    return { size: parseFloat((bytes / 1073741824).toFixed(2)), unit: "GB" };
  } else if (bytes >= 1048576) {
    return { size: parseFloat((bytes / 1048576).toFixed(1)), unit: "MB" };
  } else if (bytes >= 1024) {
    return { size: parseFloat((bytes / 1024).toFixed(1)), unit: "kB" };
  }
  return { size: bytes, unit: "B" };
}

function generateJsonReport(data: ImageData[]): JsonReport {
  const coreServices = data.filter((d) => d.isCore);
  const sites = data.filter((d) => !d.isCore);

  // Sort both by size descending
  coreServices.sort((a, b) => b.sizeBytes - a.sizeBytes);
  sites.sort((a, b) => b.sizeBytes - a.sizeBytes);

  const totalBytes = data.reduce((sum, d) => sum + d.sizeBytes, 0);

  return {
    totalSize: bytesToHuman(totalBytes),
    sites: sites.map((d) => {
      const { size, unit } = formatSizeWithUnit(d.sizeBytes);
      return {
        image: d.image,
        size,
        unit,
        label: d.domain,
      };
    }),
    coreServices: coreServices.map((d) => {
      const { size, unit } = formatSizeWithUnit(d.sizeBytes);
      return {
        image: d.image,
        size,
        unit,
        label: d.description,
      };
    }),
  };
}

async function main() {
  const outputFile = process.argv[2] || path.join(PROJECT_ROOT, "docs/image-analysis-report.txt");

  console.log("===================================================================");
  console.log("Docker Image Analysis Report");
  console.log("===================================================================");
  console.log("");

  // Check for dive
  const diveCheck = spawnSync("which", ["dive"], { encoding: "utf8" });
  if (diveCheck.status !== 0) {
    console.error("ERROR: 'dive' is not installed.");
    console.error("Install it from: https://github.com/wagoodman/dive");
    console.error("");
    console.error("macOS: brew install dive");
    process.exit(1);
  }

  console.log("Building image metadata mapping...");
  const imageMetadata = buildImageMetadataMap();

  console.log("Extracting images from docker compose...");
  const images = getImages();

  if (images.length === 0) {
    console.error("No images found");
    process.exit(1);
  }

  console.log(`Found ${images.length} unique images`);
  console.log("");

  const results: ImageData[] = [];

  for (let i = 0; i < images.length; i++) {
    const image = images[i];
    console.log(`[${i + 1}] Analyzing: ${image}`);

    const data = analyzeImage(image, imageMetadata);
    if (data) {
      console.log(
        `  OK Size: ${data.sizeHuman}, Efficiency: ${data.efficiency}%, Wasted: ${data.wastedHuman}`,
      );
      results.push(data);
    }
  }

  const report = generateReport(results);
  console.log("");
  console.log(report);

  fs.writeFileSync(outputFile, `${report}\n`);
  console.log("");
  console.log(`Report saved to: ${outputFile}`);

  // Also write JSON report
  const jsonReport = generateJsonReport(results);
  const jsonOutputFile = outputFile.replace(/\.txt$/, ".json");
  fs.writeFileSync(jsonOutputFile, `${JSON.stringify(jsonReport, null, 2)}\n`);
  console.log(`JSON report saved to: ${jsonOutputFile}`);
}

main().catch(console.error);
