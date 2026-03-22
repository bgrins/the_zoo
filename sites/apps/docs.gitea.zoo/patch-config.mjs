import fs from "node:fs";

const configPath = "/src/docusaurus.config.js";
let config = fs.readFileSync(configPath, "utf8");

config = config.replaceAll("https://docs.gitea.com", "https://docs.gitea.zoo");
config = config.replace(/^\s*\[\n\s*"docusaurus-plugin-plausible"[\s\S]*?^\s*\],\n/m, "");

if (!config.includes('url: "https://docs.gitea.zoo"')) {
  throw new Error("Failed to rewrite docs site URL");
}

fs.writeFileSync(configPath, config);
