#!/usr/bin/env node
// defuddle-fetch.mjs — Defuddle fetch wrapper for /brain:ingest-url
//
// Usage: defuddle-fetch.mjs <url>
//
// Exit codes:
//   0 — success; writes "TITLE:<title>\n---\n<markdown>" to stdout
//   2 — error; writes JSON error envelope to stderr
//
// Error codes:
//   E-INGEST-002 — non-200 HTTP response
//   E-INGEST-003 — Defuddle returned empty content
//   E-INGEST-005 — Node 22+ required

import { Defuddle } from 'defuddle/node';

// ---------------------------------------------------------------------------
// Node version check — must be v22 or later (ESM fetch is built-in from v21,
// but v22+ is the supported LTS baseline for brain-factory).
// ---------------------------------------------------------------------------
const [major] = process.versions.node.split('.').map(Number);
if (major < 22) {
  process.stderr.write(
    JSON.stringify({
      code: 'E-INGEST-005',
      message: `Node 22+ required for Defuddle. Install from nodejs.org. (found v${process.versions.node})`,
    }) + '\n',
  );
  process.exit(2);
}

const url = process.argv[2];
if (!url) {
  process.stderr.write('Usage: defuddle-fetch.mjs <url>\n');
  process.exit(2);
}

// ---------------------------------------------------------------------------
// Fetch the page
// ---------------------------------------------------------------------------
let response;
try {
  response = await fetch(url);
} catch (err) {
  process.stderr.write(
    JSON.stringify({
      code: 'E-INGEST-002',
      message: `Network error fetching ${url}. Ingest aborted. (${err.message})`,
    }) + '\n',
  );
  process.exit(2);
}

if (!response.ok) {
  process.stderr.write(
    JSON.stringify({
      code: 'E-INGEST-002',
      message: `HTTP ${response.status} fetching ${url}. Ingest aborted.`,
    }) + '\n',
  );
  process.exit(2);
}

const html = await response.text();

// ---------------------------------------------------------------------------
// Parse through Defuddle — request markdown output
// ---------------------------------------------------------------------------
let result;
try {
  result = await Defuddle(html, url, { markdown: true });
} catch (err) {
  process.stderr.write(
    JSON.stringify({
      code: 'E-INGEST-003',
      message: `Defuddle parse error for ${url}. Page may not be extractable. (${err.message})`,
    }) + '\n',
  );
  process.exit(2);
}

const body = (result.content || '').trim();
if (!body) {
  process.stderr.write(
    JSON.stringify({
      code: 'E-INGEST-003',
      message: `Defuddle returned empty content for ${url}. Page may not be extractable.`,
    }) + '\n',
  );
  process.exit(2);
}

const title = (result.title || '').trim() || 'Untitled';

// ---------------------------------------------------------------------------
// Write output: TITLE line, separator, markdown body
// ---------------------------------------------------------------------------
process.stdout.write(`TITLE:${title}\n---\n${body}\n`);
process.exit(0);
