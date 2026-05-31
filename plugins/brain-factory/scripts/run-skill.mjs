#!/usr/bin/env node
'use strict';
// scripts/run-skill.mjs — headless skill runner stub
// Traces to: BC-2.12.004 (headless execution), AC-005
//
// Usage: node run-skill.mjs <skill-name> [args...]
//
// Exit codes:
//   0 — skill name acknowledged (stub); full dispatch in STORY-034
//   1 — reserved for skill advisory (stub: not emitted)
//   2 — missing skill name argument

const nodeMajor = parseInt(process.versions.node.split('.')[0], 10);
if (nodeMajor < 22) {
  process.stderr.write(
    JSON.stringify({
      level: 'error',
      code: 'E-SKILL-002',
      message: `run-skill.mjs requires Node 22+; found ${process.versions.node}`,
    }) + '\n'
  );
  process.exit(1);
}

const [, , skillName, ...args] = process.argv;

if (!skillName) {
  process.stderr.write(
    JSON.stringify({
      level: 'error',
      code: 'E-SKILL-001',
      message: 'Usage: run-skill.mjs <skill-name> [args...]',
    }) + '\n'
  );
  process.exit(2);
}

// Stub: print skill name and args to stdout, exit 0.
// Full Claude Code skill dispatch is delivered in STORY-034.
process.stdout.write(`run-skill.mjs stub: skill=${skillName} args=${JSON.stringify(args)}\n`);
process.exit(0);
