#!/usr/bin/env node
/**
 * Sync the version from package.json into every file that shows it.
 *
 * The single source of truth is package.json. Run automatically by the npm
 * "version" lifecycle hook (so `npm version 2.3.0` updates everything), or
 * manually with:
 *
 *     node scripts/sync-version.js
 *
 * It rewrites the banner line in README.md so a bump never has to be repeated.
 */

const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const version = pkg.version;

if (!/^\d+\.\d+\.\d+/.test(version)) {
  console.error(`Invalid version in package.json: ${version}`);
  process.exit(1);
}

// README: the banner shows "Multi-agent skills manager  •  vX.Y.Z".
const readmePath = path.join(root, 'README.md');
let readme = fs.readFileSync(readmePath, 'utf8');
const before = readme;
readme = readme.replace(
  /(Multi-agent skills manager\s+•\s+)v\d+\.\d+\.\d+/g,
  `$1v${version}`
);
if (readme !== before) {
  fs.writeFileSync(readmePath, readme, 'utf8');
  console.log(`README.md -> v${version}`);
} else {
  console.log('README.md already up to date (or banner not found).');
}

console.log(`Version is ${version} in package.json (source of truth).`);
