---
name: domino-notes-expert
description: >-
  This skill should be used when the user asks to "create a Domino Notes
  application", "design a Notes form", "write LotusScript", "write Formula
  Language", "design a Notes view", "create a Notes agent", "analyze a Notes
  database", "implement a workflow in Notes", maintain an on-disk-project
  (ODP/DXL) export of an .nsf, or works on any HCL Domino / Lotus Notes
  development task. Also triggers on Chinese phrasing such as "建立 Domino
  應用", "設計 Notes 表單", "寫 LotusScript", "分析 Notes 資料庫". Provides
  architectural patterns, naming and coding conventions, a document-level
  security model, and reusable design templates derived from a small
  Formula-and-LotusScript Notes Client application (a student attendance /
  簽到 system on Domino 12.0.2).
version: 1.0.0
---

# Domino / Notes Expert

Apply this skill when designing, extending, analyzing, or migrating a classic
(Formula + LotusScript) HCL Domino / Lotus Notes application, especially one
stored as an on-disk project (ODP) of DXL files. The conventions below are
distilled from a real small Notes Client database — a student attendance /
sign-in system built on Domino 12.0.2 using only Forms, Views, one LotusScript
agent, and a Frameset+Outline navigator — and generalized into reusable
patterns. Treat the concrete prefixes, field names, and view names shown here as
placeholders to be substituted with the target project's own equivalents. When
the target project already has its own conventions, mirror those instead of
imposing these; the goal is to fit a new project into a proven structure, not to
rewrite an existing one. Use the reference files for depth and the example files
as starting templates, and run the audit checklist before delivering changes.

## ① Application Architecture Overview

Model a classic Notes app as a small set of **document forms**, a set of
**views** that index and filter those documents, and a thin layer of **agents**
for batch operations. Identify each form with the document type it represents
and pick one **master form** that other documents reference. Before designing
anything new, inventory the existing elements: enumerate Forms, Views, Agents,
Subforms, Pages, Framesets, Outlines, and any Shared Fields, Shared Actions, or
Script Libraries, and record what references each one. The database script
(`dbscript`/`Code/dbscript.lsdb`) holds global events (PostOpen, QuerySave) and
is often empty in small apps — check it before assuming where global logic
lives. The element-type taxonomy is in `references/naming-conventions.md`, and
dimension 1 of `scripts/design-audit-checklist.md` drives the inventory pass.

Relate documents with **loose foreign-key coupling**, not the Notes
Response/Response-to-Response hierarchy. Store a logical key (for example a
person or record identifier) on the master document, expose it through a
dedicated **hidden lookup view** sorted by that key, and pull related fields
into child documents with `@DbLookup`. This keeps documents independent,
survives re-keying, and reads more like a relational join than a Notes parent
chain. The lookup view's column order is a contract: reordering its first
sorted column breaks every dependent formula. To add a new related document
type, reuse the existing lookup view and its key rather than building a parallel
lookup; only create a new lookup view when the key itself differs. See
`references/data-model.md` and `references/design-patterns.md`.

Provide navigation with a **Frameset** (a navigation Outline on one side, a
default view on the other) plus a SiteMap **Outline** linking the main views.
Remember to add every new important view to that Outline, or users cannot reach
it. Keep server-side logic minimal: prefer Formula on forms and views, and
reserve LotusScript for batch or UI-driven actions. As an application grows,
factor repeated layout into Subforms and repeated logic into Shared Actions or
Script Libraries rather than copying it across elements.

## ② Design Conventions Quick Reference

Name every design element `{TypeLetter}{AppPrefix}{NN}`:

- `TypeLetter` — `F`=Form, `V`=View, `A`=Agent, `S`=Subform, `P`=Page.
- `AppPrefix` — a short fixed application code (2–4 letters), kept identical
  across all elements of one app.
- `NN` — a two-digit sequence; **gaps are normal** (a deleted `04` is fine).

Carry both a human title and the code alias in `$TITLE`, separated by `|`
(`{Code} 中文名稱|{Code}`). Build view-menu hierarchy with backslashes
(`{Code} 主題\子分類|{Code}`). In all Formula and LotusScript, **reference
elements by their code alias** (`"V{AppPrefix}03"`), never by the localized
name, so renaming the display title never breaks code.

Name fields in `camelCase` English; use the suffixes `XxxStatus`, `XxxDate`,
`XxxTime`, and `isXxx` for state, temporal, and boolean fields, and keep one
consistent foreign-key field name across every form. Choose the field compute
mode deliberately: `Editable` for input, `Computed` for values that should
track a changing master record, `Computed when Composed` for snapshots that
must freeze at creation (document numbers, the author, an approved amount), and
`Computed for Display` for view-only values. Store DateTime fields as DXL
`type='400'`. Recognize and refuse two inherited anti-conventions: localized
(non-English) field names and auto-suffixed `_1` fields born from name
collisions — never create new instances of either. Full rules:
`references/naming-conventions.md`.

## ③ Development Workflow

To add or change design elements in an ODP/DXL project:

1. **Read before writing.** Locate elements by code with `grep`
   (`grep -rl "V{AppPrefix}03" Views/`). Field lists live in each form's
   `$Fields` item and `placeholder` item declarations; view selection logic
   lives in `$Formula`/`$SelQuery`.
2. **Edit structure in Domino Designer, not by hand.** The `$Body`,
   `$ViewFormat`, `$V5ACTIONS`, and `$FrameSet` items are base64-encoded binary
   CD records; editing them as text corrupts the element. Only view
   `$Formula`/`$SelQuery`/`$TITLE`/`$Flags` and agent LotusScript are safely
   text-reviewable (LotusScript still recompiles in Designer).
3. **Reuse the established patterns.** For lookups apply the `@DbLookup`
   template; for batch updates apply the `UnprocessedDocuments` + `StampAll`
   agent skeleton; for new lookup keys clone the hidden lookup view. Templates
   are in `examples/form-template.dxl`, `examples/view-template.dxl`,
   `examples/agent-template.ls`, and the workflow walkthrough in
   `examples/workflow-pattern.md`.
4. **Re-sign every changed `sign='true'` element** with an ID that has
   execution rights, or the server may refuse to run it.
5. **Audit before delivery** using `scripts/design-audit-checklist.md`.

Always pass `"NoCache"` to `@DbLookup` so updated master data is not served
stale, and wrap lookups with `@If(@IsError(...); ""; ...)` because an unmatched
key returns `@Error`. Pair every lookup-driven field with an Input Validation
formula that rejects unknown keys at save time. When reading an agent from an
ODP export, decode its LotusScript from the base64 `$AssistAction` item; the
trigger type lives in `$AssistTrigger` (manual selection-acting agents use the
"unprocessed documents" collection). Formula recipes are in
`references/formula-cookbook.md`; LotusScript recipes — the standard
`(Options)/(Declarations)/Initialize` layout, the `UnprocessedDocuments` +
`StampAll` batch skeleton, scheduled-agent logging with `Print`, and the
`On Error GoTo` guard absent from many legacy agents — are in
`references/lotusscript-cookbook.md`.

## ④ Security Model Summary

Layer access control in three tiers, documented in `references/security-model.md`:

- **ACL** sets the baseline role per person/server/group (Manager → Editor →
  Author → Reader → Depositor → No Access). Training and demo databases often
  ship with a loose `-Default-` of Author; tighten this before production and
  block foreign-domain servers (`No Access`).
- **Reader/Author fields** enforce document-level (row-level) isolation. A
  database with none exposes every document to every Author-level user — add a
  Readers field (applicant + approvers + an admin Role) to any form holding
  private data.
- **Roles** (`[Admin]`, `[Approver]`, …) defined in the ACL and tested with
  `@UserRoles` / `session.UserRoles` drive feature- and field-level
  authorization. Define Roles before building approval gates.

Beyond these tiers, use **Controlled Access Sections** to restrict who may edit
a region of a form, the **ECL** to govern which signed code a workstation will
run, and field or document **encryption** for confidential data in transit and
at rest. Re-sign agents and design elements with a production identity after any
change to a `sign='true'` item; restricted LotusScript agents (`$Restricted=1`)
require the signer to hold the matching server execution rights, or the server
silently refuses to run them. Treat a database that ships with no Reader/Author
fields and no Roles as an unfinished security model, not a finished one.

## ⑤ Common Pitfalls to Avoid

When analyzing an inherited database, distinguish a deliberate convention from a
latent defect before copying it forward — the patterns below recur in
hand-built Notes apps and are mistakes to fix, not styles to imitate:

- **Mismatched view selection formula** — a view named for one document type
  whose `SELECT` filters another (a frequent copy-paste defect). Verify
  `SELECT form = "{Code}"` matches the view's purpose and add status filters
  where intended.
- **Residual auto-suffixed fields** — `_1`-suffixed fields appear when names
  collide; some are dead leftovers. Never reference them in new code; never
  create new ones — fix the underlying name collision instead.
- **Mixed-language / inconsistent field names** — do not propagate localized
  field names; standardize on `camelCase` English for new fields.
- **No input validation on lookups** — an unmatched key makes `@DbLookup`
  return `@Error`; add Input Validation and `@IsError` guards.
- **No error handling in LotusScript** — add `On Error GoTo` to every agent.
- **Unmodularized duplication** — repeated lookup formulas and logic belong in
  Subforms, Shared Actions, or Script Libraries once the app grows.
- **Open workflow loops** — status fields with no action/agent to advance them
  leave manual, unaudited state changes. Close the loop with an action that
  sets status, stamps `@Now`, and optionally notifies.

These and their severities are catalogued in `references/known-issues.md`.

## ⑥ Additional Resources

- `references/data-model.md` — form/field templates, lookup-key relationships,
  the 32K summary limit.
- `references/business-logic.md` — workflow walkthroughs (batch stamp, lookup
  fill, approval state machine, navigation).
- `references/design-patterns.md` — the master+lookup-view+`@DbLookup` pattern
  and other reusable structures.
- `references/security-model.md` — ACL, Reader/Author fields, Roles, signing.
- `references/formula-cookbook.md` — parameterized `@Function` snippets.
- `references/lotusscript-cookbook.md` — agent skeletons and back-end class use.
- `references/integration-guide.md` — `@DbLookup`/`@DbColumn`, ODBC, REST,
  external-system touchpoints and how to externalize them.
- `references/naming-conventions.md` — full naming and encoding rules.
- `examples/` — ready-to-adapt `form-template.dxl`, `view-template.dxl`,
  `agent-template.ls`, `workflow-pattern.md`.
- `scripts/design-audit-checklist.md` — a pre-delivery review checklist organized
  by ten analysis dimensions.

Read the relevant reference before making a non-trivial change, adapt the
matching example template rather than writing from scratch, and treat the audit
checklist as the definition of done.
