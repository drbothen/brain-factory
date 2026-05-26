#!/usr/bin/env node
// defuddle-fetch.mjs — Defuddle fetch wrapper for /brain:ingest-url
//
// Usage: defuddle-fetch.mjs <url>
//
// Exit codes:
//   0 — success; writes cleaned markdown to stdout; writes {"title":"..."} JSON to stderr
//   2 — error; writes JSON error envelope to stderr
//
// Error codes:
//   E-INGEST-002 — non-200 HTTP response or network error
//   E-INGEST-003 — Defuddle returned empty content
//   E-INGEST-005 — Node 22+ required
//   E-INGEST-012 — Invalid URL or unsupported URL scheme (only http/https permitted)

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
// URL scheme validation — only http: and https: are permitted (SSRF guard).
// BC-2.02.001 precondition 3: URL must use http or https scheme.
// ---------------------------------------------------------------------------
let parsed;
try {
  parsed = new URL(url);
} catch {
  process.stderr.write(
    JSON.stringify({
      code: 'E-INGEST-012',
      message: `Invalid URL: ${url}. Only HTTP and HTTPS URLs are supported.`,
    }) + '\n',
  );
  process.exit(2);
}
if (!['http:', 'https:'].includes(parsed.protocol)) {
  process.stderr.write(
    JSON.stringify({
      code: 'E-INGEST-012',
      message: `Only HTTP and HTTPS URLs are supported. Got: ${parsed.protocol} (${url})`,
    }) + '\n',
  );
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
// Write output: raw markdown to stdout; title metadata to stderr.
// stdout = cleaned markdown body (AC-001: "writes cleaned markdown to stdout")
// stderr = JSON metadata for the caller to extract title without parsing markdown
// ---------------------------------------------------------------------------
process.stderr.write(JSON.stringify({ title }) + '\n');
process.stdout.write(body + '\n');
process.exit(0);
