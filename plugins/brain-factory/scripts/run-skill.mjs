#!/usr/bin/env node
// scripts/run-skill.mjs — headless skill runner stub
// Full implementation delivered in STORY-033.
// Traces to: BC-2.12.001 (lobster workflow runtime dependency)
//
// Exit codes:
//   0 — skill invocation acknowledged (stub)
//   2 — missing skill name argument

const [, , skillName, ...args] = process.argv;

if (!skillName) {
  process.stderr.write(
    JSON.stringify({
      level: "error",
      code: "E-SKILL-001",
      message: "Usage: run-skill.mjs <skill-name> [args...]",
    }) + "\n"
  );
  process.exit(2);
}

// Stub: echo the invocation and exit 0
// STORY-033 will replace this with actual Claude Code skill dispatch.
process.stderr.write(
  JSON.stringify({
    level: "info",
    stub: true,
    skill: skillName,
    args,
    message: "run-skill.mjs stub — real dispatch in STORY-033",
  }) + "\n"
);
process.exit(0);
