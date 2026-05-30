---
artifact_type: dtu-assessment
document_type: dtu-assessment
level: L3
version: "1.0"
status: draft
project: brain-factory
producer: "vsdd-factory:architect"
timestamp: 2026-05-25T00:00:00
phase: phase-1c
created: 2026-05-25
last_updated: 2026-05-25
dtu_required: true
inputs:
  - architecture/ARCH-INDEX.md
  - architecture/subsystems/SS-09-publishing-pipeline.md
  - architecture/subsystems/SS-13-github-action-templates.md
  - prd/prd-supplements/interface-definitions.md
  - prd/prd-supplements/error-taxonomy.md
  - product-brief.md
traces_to: architecture/ARCH-INDEX.md
---

# DTU Assessment: brain-factory

## Summary

| Metric | Value |
|--------|-------|
| External dependencies identified | 4 |
| DTU clones recommended | 1 |
| Services not requiring DTU | 3 |
| Total clone story points | 2 |
| Estimated Wave 1 capacity needed | 2 points |

**DTU_REQUIRED: true** — brain-factory has one external service dependency (LinkedIn Posts
API) that requires a behavioral clone for integration testing. The clone is scoped to a
lightweight HTTP mock server, not a full Docker-compose clone service.

---

## Integration Surface Inventory

### Inbound Data Sources (External → Product)

Systems the product reads from: APIs polled, feeds consumed, webhooks received, sensor
data ingested.

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| 1 | Readwise API | REST/HTTPS (GH Action) | L2 (Stateful) | NO | Called only by `readwise-sync.yml` GH Action template (v0.5+). The GH Action template is a YAML file shipped in the plugin tarball — brain-factory ships the template, not the integration logic. The operator configures credentials in CI secrets. Rate-limit handling is covered by `api-retry.sh` wrapper tested with fixture 429 responses. No in-process Readwise API call occurs in plugin code during a Claude session; template behavior under 429 is fully exercised with a fixture 429 response, not a real API. |
| 2 | Raindrop API | REST/HTTPS (GH Action) | L2 (Stateful) | NO | Same rationale as Readwise — called only by `raindrop-sync.yml` GH Action template (v0.5+). Plugin ships the template; operator owns credentials. Rate-limit behavior tested with fixture 429 fixture. |
| 3 | RSS feeds (arbitrary) | HTTP/HTTPS (GH Action) | L1 (API Shape) | NO | Consumed by `ingest-rss.yml` GH Action template (v0.1 core set). No in-process RSS parsing in plugin code. The template calls `lobster-run` which processes feed items from operator-configured `feeds.yaml`. RSS response format is operator-controlled configuration, not a third-party service with a behavioral contract brain-factory must match. |

### Outbound Operations (Product → External)

Systems the product writes to or triggers: notifications, publishing, payments, command
execution.

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| 1 | LinkedIn Posts API (Community Management) | REST/HTTPS | L3 (Behavioral) | **YES** | `scripts/linkedin-post.mjs` makes a direct API call during a `/brain:publish-content` skill execution inside a Claude session. The call posts content to the Posts API (`/rest/posts`) with `LINKEDIN_ACCESS_TOKEN` from the environment, reads the 201 response, and writes the returned `linkedin_post_id` back to frontmatter. VP-020 explicitly requires a LinkedIn DTU mock for integration testing — the bats test at `tests/validate-publish-state.bats` must call a mock server at `LINKEDIN_API_BASE` to assert endpoint shape, request body format, response handling, and file-not-moved-until-201 atomicity. The real LinkedIn Posts API cannot be called in CI (no credentials, rate limits, would create real posts). A behavioral mock is the only viable integration-test path. Also covers the `--finalize --url` manual-article flow (BC-2.09.002) and performance pull via `/brain:monthly-perf` (BC-2.09.006). |

### Identity & Access (Bidirectional — auth flow)

Authentication, authorization, secrets management, credential stores.

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| — | None identified | — | — | — | brain-factory has no identity provider integration. LinkedIn API access uses a static `LINKEDIN_ACCESS_TOKEN` bearer token from environment — no OAuth flow, no OIDC, no credential store. The token is operator-configured in `.brain/.env` or CI secrets; brain-factory reads the token and passes it as an HTTP header. Token presence/absence is validated locally (E-PUBLISH-005 if not configured). No auth-flow DTU required. |

### Persistence & State (Product ↔ Storage)

External databases, caches, object stores, message queues, distributed state.

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| — | None identified | — | — | — | brain-factory's entire persistence layer is the local filesystem (the brain vault's git-backed directory tree). `manifest.json`, `policies.yaml`, wiki pages, source files, and log records are all local files. No external database, cache, object store, or message queue is called. The plugin's state is fully local. |

### Observability & Export (Product → Monitoring)

Systems the product emits data to: logging aggregators, metrics platforms, tracing,
analytics.

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| — | None identified | — | — | — | brain-factory logs to local JSONL files under `.brain/logs/` (hooks-*.jsonl, ingest-tokens.jsonl, perf-YYYY-MM.jsonl). The product brief explicitly excludes OTEL-gRPC, DataDog, and Honeycomb until v1.0+. No external observability sink exists in v0.x. |

### Enrichment & Lookup (External → Product, on-demand)

External data that augments product decisions, fetched on demand during a session.

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| 1 | Defuddle CLI (Node 20+) | subprocess (local binary) | L1 (API Shape) | NO | `scripts/defuddle-fetch.mjs` invokes the Defuddle CLI to fetch and clean web content for the `/brain:ingest-url` skill. Defuddle is a **local CLI tool installed on the operator's machine** — it is not a remote API. It runs as a subprocess (`node scripts/defuddle-fetch.mjs <url>`) and returns cleaned markdown via stdout. There is no network call to a Defuddle service; the network call is the operator's browser-equivalent URL fetch performed by the tool itself. The integration surface is a local subprocess contract (stdin/stdout), testable with a mock URL or a local file fixture. No DTU clone is needed or applicable. |

---

## Dependency Summary

| # | Service | Category | Fidelity | DTU? | Points | Justification |
|---|---------|----------|----------|------|--------|---------------|
| 1 | LinkedIn Posts API | Outbound Operations | L3 (Behavioral) | **YES** | 2 | In-process API call with atomicity guarantee, endpoint shape assertion, and credential-absence error path — all require a controllable HTTP mock for bats integration tests per VP-020 |
| 2 | Readwise API | Inbound Data Sources | L2 (Stateful) | NO | 0 | GH Action template only; no in-process call; fixture 429 sufficient |
| 3 | Raindrop API | Inbound Data Sources | L2 (Stateful) | NO | 0 | GH Action template only; no in-process call; fixture 429 sufficient |
| 4 | Defuddle CLI | Enrichment & Lookup | L1 (API Shape) | NO | 0 | Local subprocess, not a remote service |

---

## Services NOT Requiring DTU

| # | Service | Reason |
|---|---------|--------|
| 1 | Readwise API | Called only from GH Action YAML template (v0.5+ context, external CI runner). Plugin ships the template; rate-limit behavior tested with fixture 429 HTTP response via `api-retry.sh` wrapper in bats. No in-process call during Claude session. |
| 2 | Raindrop API | Same rationale as Readwise. GH Action template (v0.5+). No in-process call. |
| 3 | Defuddle CLI | Local Node.js subprocess, not a remote service. Integration tested with real URL (in end-to-end local-dev-test.sh) or a fixture local file. No behavioral clone applicable. |

---

## DTU Architecture

### LinkedIn DTU Mock

The LinkedIn clone is a lightweight in-process HTTP mock server, not a Docker container.
This is appropriate because:
- VP-020's bats harness starts and stops the mock within the test run
- The mock only needs to capture and log the request (endpoint, headers, body) and return
  a configurable response code + stub post ID
- Docker-compose overhead is unnecessary for a single-endpoint mock

| Component | Location | Port | Fidelity | Dependencies |
|-----------|----------|------|----------|--------------|
| linkedin-mock | `tests/dtu/linkedin-mock.sh` | `${DTU_PORT}` (dynamic, bats-allocated) | L3 (Behavioral) | bash, nc or netcat (or node --http-server for portability) |

The mock is a bash HTTP server (using `netcat` or a minimal `node --require` script) that:
1. Accepts one POST to `/rest/posts`
2. Validates the `Authorization: Bearer <token>` header is present
3. Logs the full request to a file (`$mock_log`)
4. Returns HTTP 201 with `{"id": "urn:li:share:TEST123456"}` (happy path)
5. Returns `LINKEDIN_API_MOCK_STATUS` code (configurable for failure scenarios)

The mock implements `start_linkedin_dtu_mock` and ensures the server is torn down in
`teardown` to prevent port leaks between tests.

### Environment Variable Overrides

| Variable | Production Value | DTU Value |
|----------|-----------------|-----------|
| `LINKEDIN_API_BASE` | `https://api.linkedin.com` | `http://localhost:${DTU_PORT}` |
| `LINKEDIN_API_MOCK_STATUS` | N/A (not set) | `201` (happy), `429` (rate limit), `500` (server error) |

`scripts/linkedin-post.mjs` reads `LINKEDIN_API_BASE` to construct the endpoint URL,
defaulting to `https://api.linkedin.com` when the variable is absent. Setting it to
`http://localhost:${DTU_PORT}` in bats redirects all API calls to the mock without
modifying the production script. This override pattern is confirmed compatible with the
Node.js script design in SS-09.

---

## Clone Development Approach

The LinkedIn DTU mock will be developed as part of the VP-020 story (publishing pipeline
verification). It is not a standalone story — it ships as test infrastructure alongside
`tests/validate-publish-state.bats` in the same story delivery.

Behavioral contracts derived from:
- LinkedIn Community Management Posts API documentation (endpoint: `POST /rest/posts`)
- VP-020 counterexamples (endpoint assertion, atomicity guarantee, deprecated UGC API
  avoidance)
- Error taxonomy: E-PUBLISH-003 (content too long), E-PUBLISH-004 (rate limit),
  E-PUBLISH-005 (credentials not configured)

Contract tests embedded in VP-020 bats harness:
- Posts to `/rest/posts` (not `/ugcPosts`)
- Authorization header present
- Body ≤ 3000 chars for native post
- 201 response → file moved + frontmatter updated
- Non-201 response → file stays in `to-publish/`; E-PUBLISH-NNN error code emitted

The mock is scheduled with the SS-09 publishing pipeline stories (Wave 1 or Wave 2
depending on wave schedule). Stories that depend on it (BC-2.09.001, BC-2.09.006) must
list it as a prerequisite.
