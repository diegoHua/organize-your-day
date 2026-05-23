# Organize Your Day

A personal daily-planning system that runs entirely inside a conversation with Claude. No app, no UI, no database. The "backend" is a single `CLAUDE.md` of agent instructions plus four Markdown files of runtime state on your local disk.

Built on a research base ([investigacion.md](investigacion.md)) drawing on Zeigarnik tension, decision fatigue, BRAC ultradian cycles, chronotype synchrony, and Parkinson's Law.

---

## Why this exists

Most task managers fail in three ways:

1. **They show you a backlog.** Your prefrontal cortex pays the metabolic bill — every visible option triggers comparison, ranking, and conflict monitoring. Decision fatigue accumulates before you've done any work.
2. **They ignore biology.** Analytical work scheduled at your circadian trough costs you double the energy and yields worse output. Most tools treat 9am and 3pm as interchangeable. They aren't.
3. **They treat unfinished tasks as completion debt.** The research (Masicampo & Baumeister, 2011) shows the opposite: a specific plan for when/where/how a task will be executed discharges the cognitive tension as effectively as completing it.

This system is a constraint engine, not a productivity hack. It enforces:

- **Forced scarcity** — only one analytical priority visible at a time.
- **Plan-as-completion** — captured tasks must be planned, not left open.
- **Chronotype alignment** — work modality matched to circadian state.
- **Hard timeboxes** — 90-minute BRAC blocks, no overruns.

---

## What you need

- [Claude Code](https://docs.claude.com/claude-code) installed locally, **or**
- Access to claude.ai with this repository as a project
- *(Optional)* Google Calendar MCP for fixed commitments and conflict detection
- *(Optional)* Gmail MCP for capturing tasks from email triage

---

## Setup

```bash
git clone <this repo> organiza-tu-dia
cd organiza-tu-dia
```

Then open Claude Code in that directory and start with:

> "Hola, quiero empezar el sistema."  *(or in English: "Let's start.")*

Claude reads `CLAUDE.md`, detects you're a new user (no `memory/` directory yet), and runs the onboarding flow:

1. **Calibration** — chronotype, daily capacity, timezone. *(~5 min)*
2. **First capture** — frictionless brain-dump of everything pending. *(~10 min)*
3. **First triage and plan** — single priority, BRAC blocks for today. *(~15 min)*

Total: under 30 minutes. After that, every conversation joins you mid-flow at the right layer.

---

## What lives where

| Path | Role |
|------|------|
| [`CLAUDE.md`](CLAUDE.md) | Agent instructions. The engine. |
| [`investigacion.md`](investigacion.md) | Theoretical base. Reference for the agent and for you. |
| `templates/` | Empty templates to seed your runtime files. |
| `docs/` | Architecture, daily flow, FAQ. |
| `inbox.md` *(generated)* | Your captured tasks. **Git-ignored.** |
| `plan_actual.md` *(generated)* | Today's BRAC schedule. **Git-ignored.** |
| `bitacora.md` *(generated)* | Append-only log of closed blocks. **Git-ignored.** |
| `memory/` *(generated)* | Your chronotype, preferences, project facts. **Git-ignored.** |

**Nothing personal is ever committed.** The [`.gitignore`](.gitignore) enforces this. The repository ships templates and an engine; your data stays on your machine.

---

## How it works (one paragraph)

Each conversation, Claude reads your inbox and the current plan, identifies which of five layers you're in — onboarding, capture, triage, assignment, or closure — and runs the matching flow. Tasks are placed into 90-minute BRAC blocks aligned with your chronotype: analytical at the circadian peak, creative at the trough, admin at transitions. Every block closes with three lines (completed / open / next physical action) before recovery starts. Timeboxes are hard. The backlog is hidden by default. The system protects you from yourself.

---

## Customizing

The agent's behavior is defined entirely by [`CLAUDE.md`](CLAUDE.md). Edit it to change:

- Block durations (default: 90/20).
- Maximum blocks per day (default: 2–3 weekday, 3–4 protected weekend).
- Onboarding questions.
- Hard rules.

If you change something fundamental, update the matching section of [`investigacion.md`](investigacion.md) so the agent stays aligned with the theoretical base.

---

## Status

Personal project shared as-is. No support contract. Issues and PRs welcome — but expect "intentional" responses. The system is opinionated by design.

---

## License

MIT — see [LICENSE](LICENSE).

---

## Acknowledgements

Built with [Claude Code](https://claude.com/claude-code) by Anthropic. The research base assembles work by Bluma Zeigarnik, Kurt Lewin, Roy Baumeister, E. J. Masicampo, Nathaniel Kleitman, Cyril Northcote Parkinson, Sophie Leroy, and others — citations in [`investigacion.md`](investigacion.md).
