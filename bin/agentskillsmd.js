#!/usr/bin/env node
'use strict';

/*
 * agentskillsmd executable.
 *
 * Thin launcher: it requires the compiled CLI, which launches the interactive
 * TUI by default (or handles advanced subcommands and the non-TTY fallback).
 * All logic lives in dist/ so there is a single implementation.
 */

const path = require('node:path');
const fs = require('node:fs');

const entry = path.join(__dirname, '..', 'dist', 'cli', 'entry.js');

if (!fs.existsSync(entry)) {
  process.stderr.write(
    '[agentskillsmd] Build output is missing: ' + entry + '\n' +
    '[agentskillsmd] Run `npm run build` (or reinstall the package).\n'
  );
  process.exit(1);
}

require(entry);
