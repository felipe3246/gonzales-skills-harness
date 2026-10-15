# Gonzales Skills and Harness

My personal curation of Agent Skills and plugins for coding agents. This isn't
a general-purpose skill store — it's the specific set I picked, adapted, and
cross-wired to work the way I work, across whichever of **Claude Code**,
**Codex**, or **Kiro** I happen to be using that day. Clone it, run
`./setup.sh`, pick your tool(s), and you get the same skills and plugins I use.

## What's in here

- `skills/` — the canonical copy of every skill, one directory per skill,
  each with a `SKILL.md`. This is the only place you edit.
- `guidelines/AGENTS.md` — always-on coding guidelines (Karpathy's four
  principles plus my additions), installed into each tool's global
  instruction file. Same rule: edit only here. See "Guidelines" below.
- `.claude/skills/`, `.agents/skills/`, `.kiro/skills/` — symlink farms so
  Claude Code, Codex, and Kiro each see the same skills without three copies
  of the content.
- `setup.sh` — installs the skills and the guidelines (and, optionally, the
  curated plugins) into your actual tool config, not just inside this repo.
  Skills land there as real copies, not symlinks; the guidelines as a
  marker-delimited block.

## Quick start

```bash
git clone <this-repo>
cd gonzales-skills-harness
./setup.sh                       # interactive menu
./setup.sh --all                 # all three tools, skills only
./setup.sh --claude --codex      # pick tools via flags
./setup.sh --all --with-plugins  # also install the curated plugins, no prompt
./setup.sh --all --dry-run       # show what it would do, change nothing
```

Skills are installed as **user-scope copies** (`~/.claude/skills`,
`~/.agents/skills` for Codex, `~/.kiro/skills`), so they work in every project
afterward, not just inside this repo, and keep working even if you move or
delete this clone. The guidelines go in next to them (see "Guidelines"
below). Because they are copies, **edits in `skills/` or `guidelines/` only
reach the global install when you re-run `./setup.sh`**. Plugins are installed with
`claude plugin install ... --scope user -y` and `codex plugin add ...` — the
same commands listed in the tables below, just automated. Kiro has no plugin
system, so it never enters that part.

Re-running the script is safe. Every copy it makes carries a
`.installed-from` marker file (containing the source path), which is how it
tells its own installs apart from anything else at the destination:

- its own copies are refreshed when the source changed and left alone when it
  didn't;
- symlinks left behind by older versions of this script (which used to link
  instead of copy) are replaced by copies;
- anything else found at the destination is moved aside as `.bak-<timestamp>`
  instead of being overwritten;
- the guidelines block is replaced in place between its two markers; whatever
  else lives in the same file (your own notes, a block another plugin wrote)
  is left untouched;
- marketplace registrations and plugin installs are never duplicated (both
  commands are idempotent).

`--dry-run` runs those same checks against your real destinations and prints
the decision per skill (unchanged, update, convert old link, back up and
install, install) and per guidelines file, without writing anything.

## How it works

All three tools implement the same open Agent Skills spec
(agentskills.io/specification): a directory named after the skill, containing
a `SKILL.md` with `name` + `description` frontmatter. What differs between
them is **where each one looks for that directory**, not the file format —
so one canonical source covers all of them. Inside this repo (project scope)
that is done with three symlink trees; in your home directory (user scope)
`setup.sh` makes real copies.

- `skills/<name>/` — the source. Edit here.
- `.claude/skills/<name>` → symlink to `../../skills/<name>` (Claude Code,
  project scope).
- `.agents/skills/<name>` → symlink to `../../skills/<name>` (Codex; confirmed
  by reading `codex-rs/ext/skills` — it scans `.agents/skills` at every
  directory between the repo root and the cwd).
- `.kiro/skills/<name>` → symlink to `../../skills/<name>` (Kiro workspace
  skills; confirmed against a real Kiro install).

Editing `skills/<name>/SKILL.md` propagates instantly to all three tools
**when they run inside this repo** — zero content duplication at project
scope. The user-scope copies in your home directory are independent files:
re-run `./setup.sh` after editing to refresh them. Git tracks the in-repo
trees as real symlinks (mode `120000`), so a clone on macOS/Linux just works.
**Caveat:** symlinks don't survive a `git clone` on Windows without
`git config core.symlinks true` (and Developer Mode / admin rights) — without
that, they land as text files containing a path instead of directories. The
user-scope install is not affected, since `setup.sh` copies.

`skills/reflect/` is deliberately **not** in any of the three symlink trees,
and `setup.sh` skips it as well.
Its body is written for OpenCode specifically (mentions `oh-my-opencode-slim`,
OpenCode logs), so surfacing it in Claude Code, Codex, or Kiro would instruct
the agent about a tool it isn't running. The frontmatter format is compatible;
the content isn't.

## Guidelines

Skills load on demand. `guidelines/AGENTS.md` is the opposite kind of
content: short behavioral rules that should be in context in **every**
session, whichever tool is running. It is Andrej Karpathy's four principles
(think before coding, simplicity first, surgical changes, goal-driven
execution), each with a condensed example from the upstream `EXAMPLES.md`,
plus three additions of mine: a rule that a project's own instructions win
over these guidelines when they contradict (Claude Code and Codex have no
formal precedence between user-level and project files; only Kiro does), a
rule for unattended runs, where the agent cannot stop to ask, and a fifth
principle about deleting temporary work (scratch files, downloaded archives,
throwaway clones, worktrees) before reporting done, and passing that
instruction on to any sub-agent it spawns.

Each tool has one global file it always reads; `setup.sh` writes the
guidelines there as a block between `<!-- project-guidelines:start -->` and
`<!-- project-guidelines:end -->`, with the source path on the first line
inside the block:

| Tool | Destination | Why there |
|---|---|---|
| Claude Code | `~/.claude/rules/project-guidelines.md` | User-level rules apply to every project and load before project rules. A file of our own, so a `~/.claude/CLAUDE.md` you write by hand is never touched |
| Codex | `~/.codex/AGENTS.md` | Codex's global instruction file, loaded before the project's own `AGENTS.md` (verified in `codex-rs/codex-home/src/instructions/mod.rs`). The block coexists with whatever is already there (the context7 plugin writes its own `<!-- context7 -->` block into this file). Caveat: Codex checks `~/.codex/AGENTS.override.md` first and, if that exists and is non-empty, ignores `AGENTS.md` entirely, so don't create one, or move the block there |
| Kiro | `~/.kiro/steering/project-guidelines.md` | Global steering; files without frontmatter are "always included", which is what we want |

Behavior on each run: file missing, create it with the block; markers
present, replace only what sits between them; file present without markers,
warn that the file exists and that the block will be appended, then append
it at the end after a blank line; content identical, report "sem mudanças"
and change nothing. `--dry-run` runs the same checks and prints either
"sem mudanças" or which of the three actions it would take, including that
warning, and writes nothing.

The file is deliberately small (~130 lines, ~5 KB): it costs tokens in every
session, and Codex caps the combined size of its instruction files at 32 KiB
by default. The full upstream `EXAMPLES.md` is ~500 lines and is not
installed; the one-paragraph examples in the guidelines are condensed from
it.

This repo itself gets the guidelines through that global install; there is
no copy at the repo root, so nothing loads twice when working here.

## Supported tools

| Skill | Claude Code | Codex | Kiro | Notes |
|---|---|---|---|---|
| `grill-me` | ✅ native (`disable-model-invocation`) | ✅ via `agents/openai.yaml` (`allow_implicit_invocation: false`) | ⚠️ works, but no "manual-only" equivalent — Kiro may auto-invoke it from the description | Depends on `grilling/` also being reachable |
| `grill-with-docs` | ✅ native | ✅ via `agents/openai.yaml` | ⚠️ same as above | Depends on `grilling/` + `domain-modeling/` |
| `grilling` | ✅ | ✅ | ✅ | — |
| `domain-modeling` | ✅ | ✅ | ✅ | — |
| `handoff` | ✅ native | ✅ via `agents/openai.yaml` | ⚠️ same as above | — |
| `teach` | ✅ native | ✅ via `agents/openai.yaml` | ⚠️ same as above | Stateful workspace (files in the cwd) — works on any harness with file access |
| `codebase-design` | ✅ | ✅ | ✅ | `DESIGN-IT-TWICE.md` asks for 3+ parallel sub-agents — confirmed on all three: Claude Code (Task/Agent), Codex (built-in multiagent), Kiro (runs agents in parallel) |
| `research` | ✅ (spawns a background agent) | ⚠️ plausible, not tested | ✅ (Kiro runs agents in parallel) | Same sub-agent/background capability as above |
| `diagram-design` | ✅ | ✅ | ✅ | Only needs bash + python3, present on all three |
| `drawio` | ✅ | ✅ (`argument-hint` is ignored; the body states the format convention) | ✅ | Native `.drawio` output with official AWS icons. PNG/SVG/PDF export and Mermaid conversion need the draw.io Desktop CLI; without it the skill still delivers the `.drawio`. `scripts/validate-drawio.sh` needs `python3` (`xmllint` optional). Trigger overlap with `diagram-design` on "architecture/flowchart": drawio keys on `.drawio`/AWS icons, diagram-design on HTML/SVG |
| `skill-creator` | ✅ (already ships "Claude.ai-specific" and "Cowork-specific" sections) | ✅ for the core loop; the parallel eval step depends on sub-agents | ✅ | — |
| `frontend-design` | ✅ | ✅ | ✅ | Plain prose, no tool-specific dependency |
| `verification-planning` | ✅ | ✅ (frontmatter only has `name`+`description`, no Claude-only field) | ✅ | References `@librarian` — a project-specific agent/skill mention. Only resolves if something named `librarian` exists in the harness running it; otherwise step 4 (research) loses that shortcut and needs another path |

`disable-model-invocation` and `argument-hint` are Claude Code extensions that
**don't exist** in the open spec or in Codex's parser — Codex silently ignores
both (confirmed by reading `codex-rs/skills/src/parser.rs`: it only reads
`name`, `description`, `metadata.short-description`). That's why the four
skills using `disable-model-invocation: true` (grill-me, grill-with-docs,
handoff, teach) each got a companion `agents/openai.yaml` — the one file Codex
reads natively to replicate that behavior (real schema, not a third-party
convention: `policy.allow_implicit_invocation: false`). The other four
mattpocock skills (grilling, domain-modeling, codebase-design, research) ship an
`agents/openai.yaml` too, carrying only display metadata (`display_name`,
`short_description`) with no policy, matching upstream. Kiro has no equivalent
mechanism: any skill there can be auto-invoked from its description at any
time, so those four skills are "best effort" on Kiro, not "guaranteed manual."

## Skills — sources and credits

### From `mattpocock/skills` (MIT)

- `grill-me/` — a relentless interview to sharpen a plan or decision. Depends
  on `grilling/`.
- `grilling/` — the reusable interview skill behind grill-me.
- `grill-with-docs/` — same as grill-me, but also maintains `GLOSSARY.md`/ADRs.
  Depends on `grilling/` and `domain-modeling/`.
- `domain-modeling/` — builds and sharpens a project's domain model (glossary
  + ADRs).
- `handoff/` — compacts the current conversation into a handoff document for
  another agent to continue.
- `teach/` — teaches the user a topic across multiple sessions, using the
  current directory as a stateful learning workspace.
- `codebase-design/` — shared vocabulary for deep modules, seams, adapters.
- `research/` — spins up a background agent to investigate something against
  primary sources.

All eight ship an `agents/openai.yaml` for Codex (display name and short
description; the four manual-only skills also set
`policy.allow_implicit_invocation: false`). Last synced with upstream v1.3.1
(2026-10-05), which renamed the `CONTEXT.md`/`CONTEXT-MAP.md` convention to
`GLOSSARY.md`/`GLOSSARY-MAP.md`; a project that already has a `CONTEXT.md`
written by these skills needs `git mv CONTEXT.md GLOSSARY.md`.

### From `multica-ai/andrej-karpathy-skills` (MIT)

- `guidelines/AGENTS.md` — the four principles and the condensed examples
  come from that repo's `CLAUDE.md` and `EXAMPLES.md`; the project-precedence
  clause, the unattended-run clause in principle 1 and all of principle 5 are
  mine. Upstream also ships
  the same text as a Claude Code plugin and a Cursor rule; neither is used
  here, since the block install above covers all three tools.

### From `anthropics/claude-code` (plugin `frontend-design`)

- `frontend-design/` — guidance for distinctive, intentional visual design.

### From `anthropics/skills`

- `skill-creator/` — **Apache 2.0**, copied locally as `skill-creator/`.
  Creates, edits, and benchmarks other skills.
- `claude-api`, `docx`, `pdf`, `pptx`, `xlsx` — **built-in, not copied**. These
  ship under Anthropic's own proprietary skill license, which forbids
  retaining copies outside Claude/Claude Code. They're already bundled with
  the product, so there's nothing to install.

### From `cathrynlavery/diagram-design` (MIT)

- `diagram-design/` — architecture, flowchart, sequence, ER, Gantt, Sankey,
  and 40+ other diagram types as self-contained HTML/SVG, with its own
  editorial design system (palette, typography, grid, complexity budget) and
  `.drawio`/`.excalidraw`/Mermaid import. Only `skills/diagram-design/` was
  copied — the repo's `commands/` and `scripts/verify-*.py` are that plugin's
  own dev tooling (tests, lint, README screenshots), not part of the
  installed skill.

### From `akitaonrails/my-skills`

- `verification-planning/` — verification planning for non-trivial coding
  work: forces building an "evidence path" (what must become true, how the
  system can reveal that, when to add a verification affordance, when to
  research before committing to an approach) before implementing.
- `reflect/` — kept for the record but deliberately excluded from the symlink
  farms and from `setup.sh` (see "How it works" above): its body targets
  OpenCode specifically.

This source has no explicit license file. Its own README says these are
"Fabio Akita's personal skills... published for reference and inspiration"
and explicitly asks people to avoid reusing them verbatim rather than adapting
them. I'm keeping both as-is anyway, credited, in a private repo for my own
use — not redistributing them further. If you're reading this from a public
fork, don't assume that permission extends to you; go read the source and
make your own call.

## Plugins I pair with this

Plugins are managed by each tool itself (`/plugin` in Claude Code, `codex
plugin` in Codex), not by files in this repo — listed here for the install
commands. **Kiro has no plugin system** (confirmed: no marketplace or
third-party extension mechanism in its docs) — the closest thing, when a
plugin is "just" an MCP server, is configuring that same MCP server directly
in `.kiro/settings/mcp.json`; when it's a pure skill (`frontend-design`) it's
already available another way (see the compatibility table above); when it's
neither (`ralph-loop`, `superdesign` — behavior tied to the Claude/Codex
UI/CLI), there's no Kiro equivalent.

Every command below was verified by actually running it (`codex plugin
marketplace add` + `codex plugin list`, then removed again) — not just read
off documentation.

| Plugin | What it does | Install on Claude Code | Install on Codex | Kiro equivalent |
|---|---|---|---|---|
| `code-review` | Reviews a diff/PR for bugs, reuse, simplification, efficiency; adds `/code-review`, `/simplify` | `/plugin install code-review@claude-plugins-official` | `codex plugin marketplace add anthropics/claude-plugins-official`<br>`codex plugin add code-review@claude-plugins-official` | — |
| `context7` | MCP for up-to-date library/framework/SDK docs (`resolve-library-id` + `query-docs`) | `/plugin install context7@claude-plugins-official` | `codex plugin add context7@claude-plugins-official` (same marketplace as above) | Add the remote MCP (`https://mcp.context7.com/mcp`) directly to `.kiro/settings/mcp.json` |
| `frontend-design` | Already documented above ("From `anthropics/claude-code`") | `/plugin install frontend-design@claude-plugins-official` | `codex plugin add frontend-design@claude-plugins-official` | Already available via `.kiro/skills/frontend-design` |
| `playwright` | Microsoft's browser automation MCP — navigate, click, screenshot, read network/console | `/plugin install playwright@claude-plugins-official` | `codex plugin add playwright@claude-plugins-official` | Add the Playwright MCP server to `.kiro/settings/mcp.json` |
| `ralph-loop` | Autonomous loop within a session; `/ralph-loop`, `/cancel-ralph` | `/plugin install ralph-loop@claude-plugins-official` | `codex plugin add ralph-loop@claude-plugins-official` | No equivalent |
| `stripe` | Stripe integration: best practices, Connect, Apps, Metronome, test cards, docs.stripe.com | `/plugin install stripe@claude-plugins-official` | **Simpler:** `codex plugin add stripe@openai-api-curated` (already in OpenAI's own curated marketplace, no `marketplace add` step needed) | Skills bundled in `stripe/ai` (`providers/claude/plugin/skills/`) can be copied/symlinked manually into `.kiro/skills/` |
| `superdesign` | Design canvas (Superdesign): pages, decks, posters, comparing models | `/plugin install superdesign@claude-plugins-official` | `codex plugin marketplace add superdesigndev/superdesign-skill`<br>`codex plugin add superdesign@superdesign` (the marketplace name comes from `plugin.json`, not the repo name) | No equivalent (tied to the canvas UI) |
| `superpowers` | The process framework this repo's skills lean on: brainstorming, TDD, systematic debugging, code review, worktrees, etc. | `/plugin install superpowers@claude-plugins-official` | **Simpler:** `codex plugin add superpowers@openai-api-curated` (already in OpenAI's curated marketplace) | Skills bundled in `obra/superpowers/skills/` can be copied/symlinked into `.kiro/skills/` |
| `terraform` | MCP for the Terraform Registry / HCP Terraform (providers, modules, policies, workspaces) | `/plugin install terraform@claude-plugins-official` | `codex plugin add terraform@claude-plugins-official` | Add the Terraform MCP server to `.kiro/settings/mcp.json` |

If `claude-plugins-official` isn't already registered as a marketplace on
your Claude Code install, run `/plugin marketplace add
anthropics/claude-plugins-official` first.

## Suggested, not installed

- **[`humanizer`](https://github.com/blader/humanizer)** (MIT) — rewrites
  AI-sounding text (not-X-but-Y contrasts, one-line closers, forced triads,
  dashes everywhere, words like "crucial"/"delve"/"robust", everything bolded
  in a list) so it reads like a person wrote it, without changing what it
  says. Based on Wikipedia's "Signs of AI writing."

  Claude Code:
  ```
  /plugin marketplace add blader/humanizer
  /plugin install humanizer@humanizer
  ```
  Codex (verified):
  ```
  codex plugin marketplace add blader/humanizer
  codex plugin add humanizer@humanizer
  ```
  (the repo itself is the marketplace in both cases — no external marketplace
  needed.) Kiro: no plugin, but the `SKILL.md` at the root of
  `blader/humanizer` is a plain skill — it can be copied/symlinked into
  `.kiro/skills/humanizer` like any other.
