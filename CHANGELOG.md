# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

When you upgrade your local clone, run `git pull` from the repo root. Personal data files (`inbox.md`, `plan_actual.md`, `bitacora.md`, `memory/`) are git-ignored and untouched by `git pull`.

---

## [Unreleased]

### Changed

- **Hard rule reinforced in AGENTS.md §7**: the agent MUST verify the current system time (`Get-Date`) before presenting any plan, listing tasks, or suggesting blocks — not just at session start (§4 step 0) but on ANY turn that involves scheduling. Added as an explicit bullet in Section 7 to prevent clock-drift errors between turns.

---

## [1.0.0] — 2026-05-23

First public release. The system is functional end-to-end and agent-agnostic.

### Added

- **`AGENTS.md`** — the engine. Follows the [agents.md](https://agents.md) standard so any compatible agent (Claude Code, OpenCode, Cursor, Aider, Antigravity / Gemini CLI, Goose, Codeium) can run the system.
- **Stubs** `CLAUDE.md` and `.cursorrules` for clients that don't read AGENTS.md natively.
- **`investigacion.md`** — full neuro-behavioral research base (Zeigarnik tension, BRAC ultradian cycles, decision fatigue, Parkinson's Law, hyperbolic discounting, chronotype synchrony).
- **`templates/`** — seed files for `inbox.md`, `plan_actual.md`, and the `memory/` directory.
- **`README.md`** with setup, philosophy, and architecture.
- **`LICENSE`** (MIT).
- **`.gitignore`** anchored to repo root only, so `templates/memory/` ships while runtime `memory/` does not.
- **Section 3a "Reentrada"** in AGENTS.md — canonical read order of the five state files so any agent can pick up the user's state on first contact of a session.
- **Section 6.5 "Eisenhower matrix"** in AGENTS.md — persistent 2×2 triage view at the top of `inbox.md`, plus clarification of the three legitimate planning horizons (daily / weekly / monthly). Corrects a common agent error of refusing weekly planning by citing decision fatigue.
- **Step 0 "Upstream check"** in Section 3a — the agent runs `git fetch` at session start and notifies the user if there are new commits from the public repo, then offers to pull. Acts as the system's own update-notification channel: users don't need to subscribe to anything on GitHub.

### Project

- Repo published at https://github.com/diegoHua/organize-your-day
- Engine language: English (runtime conversation is bilingual — agent matches the user's language).
