#!/usr/bin/env node

/**
 * @aligent/claude-toolchain CLI
 *
 * Commands:
 *   init     — Copy the toolchain into the current project
 *   update   — Update toolchain files (preserves project-specific config)
 *   version  — Print the installed version
 */

import {
  existsSync,
  cpSync,
  renameSync,
  readFileSync,
  mkdirSync,
  readdirSync,
  statSync,
} from "node:fs";
import { resolve, join, dirname, relative } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const TEMPLATE_DIR = resolve(__dirname, "..", "template");
const DEST_DIR = process.cwd();

const pkg = JSON.parse(
  readFileSync(resolve(__dirname, "..", "package.json"), "utf8"),
);

// ── Helpers ──────────────────────────────────────────────────────────────

function info(msg) {
  console.log(`\x1b[36m✓\x1b[0m ${msg}`);
}

function warn(msg) {
  console.log(`\x1b[33m!\x1b[0m ${msg}`);
}

function error(msg) {
  console.error(`\x1b[31m✗\x1b[0m ${msg}`);
}

/**
 * Files and directories that belong to the project, not the toolchain.
 * These are never overwritten by `init` or `update`.
 */
const PROJECT_OWNED = new Set([
  "CLAUDE.md",
  ".claude/settings.local.json",
  ".claude/hooks/config.sh",
  ".claude/setup-log.md",
  ".claude/stack-config.json",
  "docs/plans",
  "docs/features",
  "docs/requirements",
  ".env.development",
]);

/**
 * Files that are only relevant before first setup.
 * `update` skips these if the project already has generated equivalents.
 */
const EXAMPLE_ONLY = new Set(["CLAUDE.md.example", "docs/examples"]);

function isProjectOwned(relPath) {
  for (const owned of PROJECT_OWNED) {
    if (relPath === owned || relPath.startsWith(owned + "/")) return true;
  }
  return false;
}

function isExampleOnly(relPath) {
  for (const ex of EXAMPLE_ONLY) {
    if (relPath === ex || relPath.startsWith(ex + "/")) return true;
  }
  return false;
}

/**
 * Recursively list all files in a directory, returning paths relative to base.
 */
function walkDir(dir, base = dir) {
  const results = [];
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    const rel = relative(base, full);
    if (statSync(full).isDirectory()) {
      results.push(...walkDir(full, base));
    } else {
      results.push(rel);
    }
  }
  return results;
}

// ── Commands ─────────────────────────────────────────────────────────────

function cmdInit() {
  if (!existsSync(TEMPLATE_DIR)) {
    error(
      "Template directory not found. The package may not be installed correctly.",
    );
    process.exit(1);
  }

  // Safety check: warn if .claude/ already exists
  const claudeDir = join(DEST_DIR, ".claude");
  if (existsSync(claudeDir)) {
    warn(".claude/ already exists in this project.");
    warn("Use 'claude-toolchain update' to update an existing installation.");
    warn(
      "To reinstall from scratch, remove (and backup) .claude/ and docs/ first, then run init again.",
    );
    process.exit(1);
  }

  console.log();
  console.log(
    `Installing @aligent/claude-toolchain v${pkg.version} into ${DEST_DIR}`,
  );
  console.log();

  // Copy file-by-file, backing up any existing files
  const files = walkDir(TEMPLATE_DIR);
  let copied = 0;
  const backedUp = [];

  for (const relPath of files) {
    const src = join(TEMPLATE_DIR, relPath);
    const dest = join(DEST_DIR, relPath);

    mkdirSync(dirname(dest), { recursive: true });

    if (existsSync(dest)) {
      const bakPath = dest + ".bak";
      renameSync(dest, bakPath);
      backedUp.push(relPath);
    }

    cpSync(src, dest);
    copied++;
  }

  // Ensure empty project directories exist
  for (const dir of ["docs/plans", "docs/features", "docs/requirements"]) {
    mkdirSync(join(DEST_DIR, dir), { recursive: true });
  }

  info(`Copied ${copied} toolchain files`);
  info("Created docs/plans/, docs/features/, docs/requirements/");

  if (backedUp.length > 0) {
    console.log();
    warn(
      `${backedUp.length} existing file(s) were backed up with a .bak extension:`,
    );
    for (const f of backedUp) {
      console.log(`    ${f} -> ${f}.bak`);
    }
    console.log();
    console.log(
      "  Review the .bak files and merge any custom content, then delete them.",
    );
  }

  console.log();
  console.log("Next steps:");
  console.log(
    "  1. Merge .gitignore.toolchain into your .gitignore, then delete it",
  );
  console.log("  2. Open Claude Code in this project");
  console.log("  3. Run /detect-stack to auto-detect your technology stack");
  console.log(
    "  4. Run /setup-project to generate CLAUDE.md, rules, and configure the toolchain",
  );
  console.log();
}

function cmdUpdate() {
  const claudeDir = join(DEST_DIR, ".claude");
  if (!existsSync(claudeDir)) {
    error("No .claude/ directory found. Run 'claude-toolchain init' first.");
    process.exit(1);
  }

  if (!existsSync(TEMPLATE_DIR)) {
    error(
      "Template directory not found. The package may not be installed correctly.",
    );
    process.exit(1);
  }

  console.log();
  console.log(`Updating @aligent/claude-toolchain to v${pkg.version}`);
  console.log();

  const files = walkDir(TEMPLATE_DIR);
  let copied = 0;
  let skipped = 0;

  // Check if project has been set up (CLAUDE.md exists, not just the example)
  const isSetUp = existsSync(join(DEST_DIR, "CLAUDE.md"));

  for (const relPath of files) {
    const src = join(TEMPLATE_DIR, relPath);
    const dest = join(DEST_DIR, relPath);

    // Never overwrite project-owned files
    if (isProjectOwned(relPath)) {
      skipped++;
      continue;
    }

    // Skip example files if the project has already been set up
    if (isSetUp && isExampleOnly(relPath)) {
      skipped++;
      continue;
    }

    // Copy the file, creating directories as needed
    mkdirSync(dirname(dest), { recursive: true });
    cpSync(src, dest);
    copied++;
  }

  info(`Updated ${copied} toolchain files`);
  if (skipped > 0) {
    info(`Skipped ${skipped} project-owned or example files`);
  }

  console.log();
  console.log("Review the changes and commit when ready.");
  console.log(
    "If /setup-project was previously run, your CLAUDE.md, rules, and config.sh are preserved.",
  );
  console.log();
}

function cmdVersion() {
  console.log(`@aligent/claude-toolchain v${pkg.version}`);
}

function cmdHelp() {
  console.log(`
@aligent/claude-toolchain v${pkg.version}

Usage:
  claude-toolchain init      Copy the toolchain into the current project
  claude-toolchain update    Update toolchain files (preserves project config)
  claude-toolchain version   Print the installed version
  claude-toolchain help      Show this help message

Quickstart:
  cd your-project
  npx @aligent/claude-toolchain init
  # Open Claude Code, then run /detect-stack followed by /setup-project
`);
}

// ── Main ─────────────────────────────────────────────────────────────────

const command = process.argv[2];

switch (command) {
  case "init":
    cmdInit();
    break;
  case "update":
    cmdUpdate();
    break;
  case "version":
  case "--version":
  case "-v":
    cmdVersion();
    break;
  case "help":
  case "--help":
  case "-h":
  case undefined:
    cmdHelp();
    break;
  default:
    error(`Unknown command: ${command}`);
    cmdHelp();
    process.exit(1);
}
