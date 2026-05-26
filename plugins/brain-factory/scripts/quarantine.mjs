// quarantine.mjs — Prompt-injection detection corpus and CLI
// BC-2.10.003: single source of truth for injection patterns
// No npm dependencies — pure Node 22+ ES module built-ins only.

/**
 * INJECTION_PATTERNS — named RegExp objects for prompt-injection detection.
 * Each entry is a RegExp. The `.source` property (the pattern string) is used
 * as the `pattern_matched` label in block verdicts.
 */
export const INJECTION_PATTERNS = [
  /ignore.previous.instructions/i,
  /you.are.now.a/i,
  /system.prompt/i,
  /disregard.your.instructions/i,
];

// CLI entry point: node quarantine.mjs --check
// Reads content from stdin, tests each pattern, exits 2 with block verdict if
// matched, exits 0 with clean verdict if not.
if (process.argv[2] === '--check') {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const content = Buffer.concat(chunks).toString('utf8');

  for (const pattern of INJECTION_PATTERNS) {
    if (pattern.test(content)) {
      process.stdout.write(
        JSON.stringify({
          verdict: 'blocked',
          code: 'E-QUARANTINE-001',
          pattern_matched: pattern.source,
          message: 'Prompt-injection pattern detected. Content quarantined.',
        }) + '\n',
      );
      process.exit(2);
    }
  }

  process.stdout.write(JSON.stringify({ verdict: 'clean' }) + '\n');
  process.exit(0);
}
