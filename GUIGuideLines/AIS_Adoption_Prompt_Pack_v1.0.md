# AIS Adoption Prompt Pack

**Version 1.0 · Asternest Labs**
**Companion to:** Asternest Interface Standard (AIS) v1.0
**Applies to:** any Asternest Labs application, any stack

---

## Part 0 — Which Prompt to Use

| Situation | Prompt |
|---|---|
| Starting a new app | **P-1** Domain Profile → **P-2** Token & theme layer → **P-3** Validation layer → **P-4** Error & diagnostics → **P-5** Shells → **P-6** Navigation → **P-7** Conformance suite |
| Existing app, want to know where it stands | **P-8** Conformance audit (read-only) |
| Existing app, adopting AIS incrementally | **P-8** audit → **P-9** remediation plan → run P-2…P-7 selectively |
| Adding a screen to a conformant app | **P-10** Screen scaffold |
| Adding a component | **P-11** Component addition |
| Adding a new stack to AIS | **P-12** Stack binding |

**Build P-1 first, always.** Every other prompt reads the Domain Profile. Without it an agent invents domain semantics, and they will be wrong.

**P-7 before any feature work.** A conformance suite written after the fact tests what was built rather than what was required.

---

## Part 1 — Prompts

---

### P-1 — Domain Profile

```
Read the Asternest Interface Standard (AIS) v1.0 in full before answering,
especially §7.

TASK: Draft the Domain Profile for <APP NAME>.

APP CONTEXT
- What it does: <one paragraph>
- Primary users and what they are trying to accomplish: <...>
- Stack: <SwiftUI / Flutter / web / other>
- Platforms: <...>
- Existing brand direction, if any: <...>

PRODUCE the Domain Profile in the §7 template. For each section:

1. ADDED SEMANTIC TOKENS
   Propose tokens ONLY where the core nine (AIS §2.2) genuinely cannot express a
   meaning this app must convey. For each, state what it means and WHY the core
   set is insufficient. A token that is a synonym for an existing one is
   rejected. Expect to add between zero and three. Adding more is a signal you
   are encoding appearance rather than meaning.

2. REQUIRED VALUE ANNOTATIONS (§3.1)
   For each consequential value type this app displays, list the annotations
   without which the number is misleading. Ask yourself: if a user screenshotted
   this figure and sent it to a colleague with no context, what would they get
   wrong? Those are the required annotations.

3. INVARIANT-BEARING SCREENS (§1.2)
   List every screen where child lines must satisfy an assertion the header
   makes, and state the assertion precisely. If there are none, say so — not
   every app has them, and inventing one is worse than having none.

4. AGGREGATION REFUSAL CASES (§3.3)
   List every case where a total would be WRONG rather than merely unavailable —
   mixed units, mixed currencies, mixed grain, mixed basis, mixed period.

5. BREAKPOINTS — three pixel values with a rationale.

6. PALETTE — propose light and dark values for all core tokens plus any added.
   Report the computed contrast ratio for each against its surface. Do not
   propose a value you have not checked.

7. EXCEPTIONS — leave empty for a new app.

CONSTRAINTS
- Do NOT redefine or remove a core token. Adding is the only permitted change.
- Do NOT copy another Asternest app's palette. Apps should not look alike.
- Where you are unsure whether something is a domain semantic or a brand choice,
  say so and ask rather than guessing.

OUTPUT the profile as a markdown file at docs/DOMAIN_PROFILE.md, then STOP.
Do not write any code.
```

---

### P-2 — Token and Theme Layer

```
Read AIS v1.0 §2, §6, §10. Read docs/DOMAIN_PROFILE.md.

TASK: Build the token and theme layer for <APP NAME> in <STACK>.

BUILD
1. All nine core tokens (AIS §2.2) plus every token added by the Domain Profile,
   defined for every theme the app ships.
2. Each token's REQUIRED PAIRED ICON, declared alongside it so the pairing is
   data, not convention.
3. Typography, spacing, radius and elevation as numeric scales. No one-off
   values anywhere in screen code.
4. The three breakpoints from the Domain Profile.
5. Stack binding per AIS §10 for <STACK>. Follow it — do not invent a different
   mechanism.

BINDING RULES
- A color literal outside the token definition is a conformance failure (C-02).
- A token used without its paired icon is a conformance failure (C-03).
- state.unavailable must be distinguishable from a zero or empty value by MORE
  THAN COLOR. This one carries real meaning — "no value" and "a value of zero"
  are opposites.

TESTS — write these now, not later
- C-01: compute every token/surface contrast ratio in every theme, assert AA.
  Automated. Do not rely on visual inspection.
- C-02: source scan for color literals outside the token file. Plant a violation
  and assert the scan catches it.
- C-03: a token used without its icon fails. Plant one; assert caught.
- state.unavailable vs zero: assert they differ in more than color.
- Render a gallery of every token at all three breakpoints, both themes.

DEFINITION OF DONE
[ ] Every token AA-verified automatically in every theme
[ ] Icon pairing enforced; planted violation caught
[ ] No color literals outside tokens; planted violation caught
[ ] unavailable distinguishable from zero by more than color
[ ] Gallery renders at all three breakpoints

STOP after the DoD with the contrast output. Do not build screens.
```

---

### P-3 — Validation and Formatting Layer

```
Read AIS v1.0 §5. Read docs/DOMAIN_PROFILE.md.

TASK: Build the validation and formatting layer for <APP NAME>.

CRITICAL FRAMING
This layer has NO UI FRAMEWORK DEPENDENCY. It is importable by client and server
alike so a rule cannot drift between them. If the stack makes that impossible,
say so and stop — do not build a UI-coupled validator and call it done.

Regex is correct for a MINORITY of these formats. AIS §5.2 is binding. Do not
substitute regex where it forbids it, and do not add a regex convenience method
"for consistency."

BUILD
1. A result type carrying: validity, a stable error code enum, a localized user
   message, and the normalized value.
2. Every format in the AIS §5.2 table, using the technique that table specifies.
3. Every validator accepts a country parameter. NOTHING defaults to one country.
4. Formatters that return display strings and never mutate stored values.
5. Composable validators returning ALL failures, not the first.
6. Money: routes through this application's exact decimal type. Currency is
   REQUIRED with no default. Never regex, never floating point.

TESTS
- C-18: same validator, client and server, 100 randomized inputs per format,
  identical results.
- C-19: source scan — no regex in the money, phone, date, time or URL paths; no
  floating-point type in any money signature. Plant a violation; assert caught.
- C-20: phone, postal code and administrative area for four countries on
  different continents. A one-country assumption fails three of four.
- C-21: an ambiguous date with no explicit format is REJECTED, not guessed.
- A time with no timezone is rejected.
- Money with no currency is rejected.
- Email: three legal-but-unusual addresses that naive regex rejects must PASS.
- URL: javascript: and data: schemes rejected; embedded credentials rejected.
- An unknown country ACCEPTS free text for postal code rather than rejecting.
- C-24: no hardcoded user-facing string.
- Source scan: zero UI framework imports.
- C-31: date fields provide BOTH popup calendar picker AND keyboard text entry.
- C-32: time fields provide BOTH popup time picker AND keyboard text entry.
- C-33: date/time formats match system locale; format hints visible.
- C-34: date and time are SEPARATE fields, never a single ambiguous input.

DEFINITION OF DONE
[ ] Zero UI framework imports, proven by scan
[ ] Client/server parity across all formats
[ ] No regex where §5.2 forbids it, proven by scan
[ ] Four countries pass
[ ] Ambiguous dates rejected, not guessed
[ ] No payment-card input path exists (§5.5)
[ ] Date inputs have dual entry (calendar picker + keyboard)
[ ] Time inputs have dual entry (time picker + keyboard)
[ ] Date/time formats are locale-aware with format hints
[ ] DateTime uses separate date and time fields

STOP after the DoD with the parity and scan output.
```

---

### P-4 — Error Envelope and Diagnostics

```
Read AIS v1.0 §4. Read docs/DOMAIN_PROFILE.md.

TASK: Build the error envelope and copyable diagnostics for <APP NAME>.

CRITICAL
The copied block is designed to be pasted into a support ticket or an AI chat.
IT LEAVES THE TRUST BOUNDARY. Redaction is a correctness requirement, and
C-15 admits NO EXCEPTION under AIS §9. If redaction is incomplete, this unit is
not done.

BUILD
1. The error envelope with every field in AIS §4.1.
2. A redaction step reusing THE APPLICATION'S SINGLE REDACTION FILTER. If none
   exists, build it here as a shared component — do not write a second one.
   Redacted values become typed markers: [REDACTED:email].
3. The copyable block: human-readable AND machine-parseable, correlation ID
   retained.
4. Presentation variants — inline, blocking, transient — using the tokens from
   P-2, always icon-paired. Technical detail behind an expander, collapsed by
   default. Present, never forced.
5. An error catalogue: every code registered with a localized user message.
6. Capture integration per AIS §4.3: global shortcut, offered on error, preview
   MANDATORY before it leaves the device, never auto-saved or auto-sent.

TESTS
- C-15 (GATES THIS UNIT): trigger an error whose context contains an email, a
  phone number, an access token, a password field value and a person's name.
  Assert NONE appears in the copied block and each is a typed marker.
- C-16: the correlation ID in the block matches the server log line for the same
  request.
- C-13: enumerate the error code enum; every code has a localized message. Plant
  a gap; assert caught.
- C-14: scan every registered message for stack traces, class names, SQL
  fragments and the word "exception". Assert none.
- C-17: a capture cannot be attached or transmitted without preview
  acknowledgement.
- The block parses back into its fields.
- Copy places the exact block on the clipboard.
- Technical detail collapsed by default.
- Error UI meets AA in every theme.

DEFINITION OF DONE
[ ] C-15 green for all five personal-data classes
[ ] Correlation ID joins to server logs
[ ] Every code has a localized message; planted gap caught
[ ] No jargon in any user message, proven by scan
[ ] Capture requires preview acknowledgement

STOP after the DoD with the FULL redaction test output.
```

---

### P-5 — Shells

```
Read AIS v1.0 §1, §3. Read docs/DOMAIN_PROFILE.md. Read AIS §10 for <STACK>.

TASK: Build the reusable shells for <APP NAME>.

BUILD IN THIS ORDER

1. DATA GRID (§3.4) — Excel-like grid for tabular data
   - EDITABLE CELLS: double-click or F2 to edit, Enter to commit, Escape to cancel.
   - MULTI-COLUMN SORT with shift-click to add secondary sorts.
   - PER-COLUMN FILTERS with type-appropriate filter UI.
   - KEYBOARD NAVIGATION: arrow keys, Tab across columns, Page Up/Down for rows.
   - COLUMN RESIZE and reorder with drag handles.
   - EXPORT to CSV/Excel preserving visible state (filters, sort, columns).
   - VIRTUALIZATION: only render visible rows for large datasets.
   - SELECTION: single row, multi-row with Ctrl/Cmd, range with Shift.

2. GRID LAYOUT (§3.5) — responsive card layouts
   - Adaptive columns based on available width and minimum child width.
   - Consistent spacing between items.
   - Maintains aspect ratios and alignment.

3. MEDIA PICKER (§3.6) — file upload/download with metadata
   - ALLOWED TYPES: image, video, audio, pdf, csv, text — each with its icon.
   - FILE SIZE LIMIT configurable with clear feedback when exceeded.
   - DRAG-AND-DROP support alongside traditional file dialog.
   - FILE INFO RETURN: id, fileName, extension, mimeType, sizeBytes, folderPath,
     fullPath, mediaType, createdAt, modifiedAt, thumbnailPath (images/video),
     duration (audio/video), width/height (images/video), checksum, status.
   - UPLOAD STATUS: pending, uploading with progress, completed, failed with error.
   - PREVIEW: images show thumbnail, audio/video show duration badge.
   - MULTIPLE FILES: configurable min/max count with visual feedback.

4. LIST-DETAIL SHELL (§1.1) — the primary screen pattern, build first
   - Left: search, filters, virtualized list, result count, sort, new-record.
   - Right: the record's CRUD surface.
   - LIST KEEPS ITS PLACE: selection, scroll, filter and sort survive an
     edit-save cycle and survive navigating away and back. This is the most
     common failure of this pattern — treat it as the primary requirement, not a
     refinement.
   - Unsaved changes BLOCK A SELECTION CHANGE, not just navigation. The selection
     does not move until the person decides.
   - Compact viewport: separate routes, back restores scroll position.
   - Deep link addresses a record and restores surrounding list state.
   - Keyboard: arrows move selection, tab crosses panes, escape returns to list.
   - TWO empty states: no-records and no-matches, visually distinct, the second
     offering clear-filters.

2. HEADER/DETAIL SHELL (§1.2) — right-panel content, only where an invariant
   exists. Build only if the Domain Profile lists invariant-bearing screens.
   - The invariant is a REQUIRED parameter. Construction without one must fail —
     at compile time where the language allows.
   - Running total, target and RESIDUAL always visible.
   - Save BLOCKED while residual ≠ 0.
   - Uneven-split remainders EXPLICITLY ASSIGNED, never lost.

3. REPORT SHELL (§1.3) — if the app reports
   - Period, comparison, grouping, drill path.
   - DRILL-THROUGH TO SOURCE ROWS, mandatory.
   - Footing assertion: non-zero residual FLAGGED, never hidden.
   - Annotation bar carrying the Domain Profile's required annotations.
   - Export carries the annotation bar.

4. HISTORY VIEWER (§1.4) — if the app audits
   - Two entry points: standalone, AND from the record itself.
   - Field-level before/after diff.
   - READ-ONLY. No mutation affordance anywhere.

5. VALUE COMPONENT (§3.1)
   - Requires its Domain Profile annotations as constructor parameters, so a
     bare consequential value CANNOT BE RENDERED. Compile error, not review
     catch.

TESTS
- C-05: filter, select, edit, save → list retains filter, sort, scroll,
  selection. THE decisive test.
- C-06: unsaved changes block selection change; selection does not move behind
  the prompt.
- C-07: two empty states render differently; filtered state offers clear-filters.
- C-08: save blocked at residual ≠ 0 in both directions; residual correct;
  uneven split assigns the remainder visibly.
- C-09: a header/detail constructed with no invariant fails.
- C-10: drill-through reaches source rows; the drilled set reconciles to the
  parent figure.
- C-04: the value component cannot render without its annotations.
- C-30: history exposes no mutation affordance; assert by widget scan.
- C-35: data grid keyboard: arrow keys navigate, Enter/F2 edits, Escape cancels, Tab
  crosses columns.
- C-36: data grid export: exported data matches visible grid state (filters, sort,
  columns applied).
- C-37: media picker type filter: picker only accepts files matching configured types.
- C-38: media picker size limit: picker rejects files exceeding configured max size.
- C-39: file info completeness: picker returns all required fields for database storage.
- C-40: media type icons: each media type displays its designated icon.
- C-41: upload status display: upload shows status (pending, uploading, completed, failed)
  with appropriate visual feedback.
- C-42: grid layout responsive: layout adapts columns to width respecting min child width.
- Compact/medium/expanded all render without horizontal overflow.
- C-22, C-23: keyboard reach and assistive labels on all shells.

DEFINITION OF DONE
[ ] Data grid supports keyboard navigation and editing
[ ] Data grid export preserves visible state
[ ] Media picker filters by allowed types and size
[ ] File info returns all database-required fields
[ ] Grid layout adapts columns responsively
[ ] List retains state across an edit-save cycle
[ ] Selection guard blocks selection change, not just navigation
[ ] Invariant blocks save; no-invariant construction impossible
[ ] Drill-through reconciles to parent
[ ] Bare consequential value unrenderable
[ ] History read-only

STOP after the DoD.
```

---

### P-6 — Navigation

```
Read AIS v1.0 §1.5. Read docs/DOMAIN_PROFILE.md.

TASK: Build navigation for <APP NAME>.

BUILD
1. TASK-oriented grouping. Group by what someone is trying to DO, not by entity
   name. Propose the grouping and state your reasoning before building it.
   Maximum TWO levels — a third means the grouping is wrong.
2. Fold/unfold per category, state persisted per user.
   NOT AN ACCORDION — expanding one does not collapse others. A collapsed
   category containing the active route shows an indicator.
   The category containing the current route auto-expands on load.
3. PERMISSION FILTERING SERVER-SIDE. The client must not receive items it may
   not use. Forbidden items are ABSENT, not disabled — a disabled item
   advertises what someone cannot have.
4. UNAVAILABLE ≠ UNAUTHORIZED. An item outside the user's plan or licence is
   visible with an upgrade path and looks DIFFERENT from a forbidden one.
5. Command palette with fuzzy search, applying IDENTICAL filtering.
6. Adaptive shell at the three breakpoints; breadcrumbs; deep links restoring
   full state.
7. Menu items use action.neutral. Module identity is carried by ICON — and
   optionally a header accent — never by re-coloring actions.

TESTS
- C-27: the server's menu payload contains NO forbidden item. Assert on the
  PAYLOAD, not the rendered UI. Client-side hiding is not authorization.
- C-28: the palette applies identical filtering; a forbidden target is
  unreachable by search. This is the most likely place for the bug.
- Deep link to a forbidden route redirects with an explanation and does not leak
  whether the record exists.
- Unavailable-by-plan renders distinctly from forbidden-by-role.
- C-29: fold state persists across restart; two categories expanded at once;
  active-route category auto-expands; collapsed-with-active shows an indicator.
- Three breakpoints; keyboard reach; screen-reader structure announcement.
- C-24: no hardcoded labels.
- No per-item color — assert menu items use only action.neutral.

DEFINITION OF DONE
[ ] Filtering proven on the server payload
[ ] Palette filtering identical, proven
[ ] Unavailable visually distinct from unauthorized
[ ] Two levels max; fold persists; not an accordion

STOP after the DoD with the payload and palette test output.
```

---

### P-7 — Conformance Suite

```
Read AIS v1.0 §8 in full. Read docs/DOMAIN_PROFILE.md.

TASK: Implement the AIS conformance suite for <APP NAME> in <STACK>.

CRITICAL
Write this suite BEFORE feature work, or as the first step of adoption. A
conformance suite written afterwards tests what was built rather than what was
required, which is the opposite of its purpose.

BUILD
- All 42 tests from AIS §8, in this stack's test framework.
- Runnable as one command with a clear pass/fail per test ID.
- EVERY test that detects a violation must be proven by PLANTING one. A scan
  that has never caught anything has not been shown to work. This applies at
  minimum to C-02, C-03, C-04, C-09, C-13, C-14, C-19, C-24.
- Tests for rules the Domain Profile declares as exceptions are still WRITTEN,
  marked skipped with the exception reason as the skip message — so the gap
  stays visible rather than disappearing.

OUTPUT
- The suite.
- docs/CONFORMANCE.md: a table of test ID, status (pass / fail / excepted), and
  for exceptions the reason and planned resolution.

DEFINITION OF DONE
[ ] All 42 implemented or explicitly excepted with a reason
[ ] Every detection test proven by a planted violation
[ ] Single command runs the suite with per-ID results
[ ] CONFORMANCE.md generated

STOP after the DoD with the full suite output.
```

---

### P-8 — Conformance Audit (read-only, for an existing app)

```
Read AIS v1.0 in full.

TASK: Audit <APP NAME> at <PATH> against AIS v1.0. REPORT ONLY.

DO NOT CHANGE ANY CODE IN THIS TASK. Not a rename, not a color value, not a
"quick fix." The output is a report. Remediation is P-9, and it is a human
decision.

METHOD
Work through AIS §1 to §6 in order. For each rule, inspect the actual code and
classify:

  CONFORMS       — evidence: file and line
  DEVIATES       — what it does instead, where, and the effort to close
  NOT APPLICABLE — why this app genuinely does not need it
  UNKNOWN        — could not determine; say what you would need to look at

Be specific. "Colors are inconsistent" is useless. "37 color literals outside
any token definition, concentrated in views/reports/ — list attached" is useful.

PAY PARTICULAR ATTENTION TO — these are where existing apps usually deviate:
- Color literals scattered through view code rather than tokenized (C-02)
- List screens that lose scroll or selection after an edit (C-05)
- Save allowed while a total does not foot (C-08)
- Error messages containing exception text shown to users (C-14)
- Diagnostics with no redaction, or no copyable diagnostics at all (C-15)
- Validation duplicated between client and server (C-18)
- Money in a floating-point type anywhere (C-19)
- Hardcoded user-facing strings (C-24)
- Menu filtering done client-side (C-27)

ALSO PRODUCE
A draft Domain Profile INFERRED from what the app actually does — what its
consequential values are, what invariants its screens already enforce, what
aggregations would be wrong. This is often more accurate than one written from
scratch, because the app already encodes these decisions implicitly.

OUTPUT docs/AIS_AUDIT.md:
1. Summary: conformance count by category
2. Rule-by-rule findings with file references
3. Inferred Domain Profile draft
4. Deviations ranked by (user impact x effort to close)
5. Anything that looks like a genuine BUG rather than a standards deviation,
   listed separately — an audit often finds these and they matter more

STOP. Change nothing.
```

---

### P-9 — Remediation Plan

```
Read AIS v1.0 §9. Read docs/AIS_AUDIT.md.

TASK: Turn the audit into a staged remediation plan for <APP NAME>.

CONSTRAINT THAT SHAPES EVERYTHING
Partial conformance with a published exception list BEATS a stalled rewrite. Do
not propose a rewrite. Propose stages that each leave the app shippable.

PRODUCE

1. STAGE 0 — NON-NEGOTIABLE
   Only C-15 (diagnostic redaction) and C-19 (money discipline, where the app
   handles money). AIS §9 admits no exception to these. Anything else here is
   wrong.

2. STAGE 1 — FOUNDATION
   Changes that unblock later stages: token layer, validation layer, error
   envelope. Typically mechanical, high line-count, low behavioural risk.

3. STAGE 2 — STRUCTURAL
   Shell adoption. Higher risk because it changes interaction. Stage per screen
   family, not all at once.

4. STAGE 3 — POLISH
   Accessibility gaps, localization, responsive.

5. PERMANENT EXCEPTIONS
   Deviations not worth closing. For each, the reason and an honest statement
   that there is no planned resolution. "We will not do this" is a legitimate
   entry; a silent gap is not.

FOR EACH STAGE: files touched, estimated effort, what could break, how to verify.

ALSO: state which stages can run in parallel and which must be sequential.

OUTPUT docs/AIS_REMEDIATION.md. Change no code. STOP.
```

---

### P-10 — Screen Scaffold

```
Read AIS v1.0 §1, §3. Read docs/DOMAIN_PROFILE.md. Read docs/CONFORMANCE.md.

TASK: Scaffold the <SCREEN NAME> screen for <APP NAME>.

SCREEN CONTEXT
- What the user is trying to do: <...>
- Primary entity: <...>
- Child lines, if any: <...>
- Invariant, if any: <...>
- Consequential values displayed: <...>

BUILD using EXISTING shells and components. Do not create new ones — if you
believe one is needed, stop and use P-11 instead.

- List-detail shell for the outer structure.
- Header/detail inside it ONLY if there is a declared invariant.
- Existing value component for every consequential value, with the Domain
  Profile's required annotations.
- Existing error presentation. No bespoke error handling in this screen.
- Existing tokens. No new colors. No literals.

TESTS — the screen-level subset
- C-05 list state retention on THIS screen
- C-06 selection guard
- C-07 two empty states
- C-08 invariant, if this screen has one
- C-04 every consequential value annotated
- C-22, C-23 keyboard and assistive labels
- C-26 three breakpoints
- C-24 no hardcoded strings

DEFINITION OF DONE
[ ] Uses only existing shells, components and tokens
[ ] Screen-level conformance subset green
[ ] No new color, no new component, no bespoke error handling

STOP after the DoD.
```

---

### P-11 — Component Addition

```
Read AIS v1.0 §2, §3. Read docs/DOMAIN_PROFILE.md.

TASK: Evaluate and, if justified, add <COMPONENT NAME> to <APP NAME>.

STEP 1 — JUSTIFY BEFORE BUILDING. Answer these first and STOP if the answer is
no:
- Which existing component is closest, and specifically why is it insufficient?
- Is this a genuinely new INTERACTION, or the same interaction with different
  styling? If the latter, the answer is a variant, not a component.
- Will this be used on more than one screen? If not, it belongs in that screen.
- Does it need a new semantic token? If you think so, re-read AIS §2.2 — the
  answer is almost always no, and a new token is a much bigger commitment than
  a new component.

Present the justification and WAIT for a decision. Do not build first.

STEP 2 — if approved, BUILD
- Bound to existing tokens. No new color unless a token was explicitly approved.
- Icon-paired if it carries a semantic token.
- Keyboard operable; labelled for assistive technology.
- Renders at all three breakpoints and in every theme.
- Handles empty, loading and error states.

TESTS
- C-01 contrast in every theme
- C-03 icon pairing if semantic
- C-22, C-23 keyboard and labels
- C-26 three breakpoints
- Empty, loading and error states render
- Added to the component gallery

STOP after STEP 1 for a decision. Do not proceed to STEP 2 unapproved.
```

---

### P-12 — Stack Binding

```
Read AIS v1.0 §8, §10.

TASK: Produce the AIS §10 binding for <NEW STACK>.

For each AIS concept in the §10 table, give this stack's idiomatic mechanism:
token set, list-detail shell, list state retention, selection guard, annotation
enforcement, keyboard, accessibility, reduce-motion, capture, validation layer
placement, localization.

THEN, for each of the 42 conformance tests in §8, state:
- The mechanism that implements it in this stack, OR
- That it cannot be expressed here — and why

A rule that cannot be expressed becomes a documented exception under §9, not a
silent omission. Be explicit about which those are; that list is the honest
measure of how well this stack fits.

FLAG SPECIFICALLY:
- Where compile-time enforcement is available (annotation requirements,
  invariant parameters). Compile-time beats test-time; use it where the language
  allows.
- Where only runtime enforcement is possible.
- Where only a source scan is possible.
- Where nothing is possible — and say so plainly.

OUTPUT a §10 subsection in the same format as the existing bindings, plus the
per-test mapping table. Change no application code. STOP.
```

---

## Part 2 — Reusable CLAUDE.md Block

Paste into the `CLAUDE.md` of any AIS-conformant app.

```markdown
## Interface standard

This app conforms to Asternest Interface Standard (AIS) v1.0.
Read docs/DOMAIN_PROFILE.md and docs/CONFORMANCE.md before any UI work.

- Semantic tokens only. Never assign a color to an individual control. If an
  action does not fit an existing token, reconsider the action, do not add a
  token.
- Every semantic token is icon-paired. Color is never the only signal.
- A consequential value may not be rendered without the annotations its Domain
  Profile requires. Use the value component; it requires them.
- "Unavailable" must look different from "zero", by more than color.
- The list in a list-detail screen keeps its filter, sort, scroll and selection
  across an edit-save cycle. Verify it after any change to that screen.
- Header/detail screens declare an invariant and block save on a non-zero
  residual. No invariant means the wrong shell.
- History UI is read-only. No mutation affordance may exist.
- Validation lives in the shared platform-free layer. Regex only where AIS §5.2
  permits it. Money is never regex-parsed and never floating point.
- Date/time inputs require dual entry: popup picker AND keyboard text entry.
  Formats are locale-aware with visible format hints. Date and time are separate
  fields, never a single ambiguous input.
- Data grids support keyboard navigation (arrows, Enter/F2 to edit, Escape to
  cancel, Tab across columns). Export preserves visible state (filters, sort).
- Media picker returns complete file info for database storage: id, fileName,
  extension, mimeType, sizeBytes, folderPath, fullPath, mediaType, status.
  Each media type has its designated icon. Upload status is always visible.
- Grid layouts adapt columns responsively to available width.
- Every error carries a plain-language actionable message and a REDACTED
  copyable diagnostic block. Redaction has no exception.
- Screen capture is global and previewed. Never auto-saved, never auto-sent,
  never an icon on every screen.
- Menu filtering is server-side. Client-side hiding is not authorization.
- No hardcoded user-facing strings.

Run the conformance suite before declaring any UI work done. Report actual
output; do not claim it passed without showing it.
```

---

## Part 3 — Adoption Order for an Existing App

Recommended sequence when retrofitting. Each stage leaves the app shippable.

| Stage | Prompts | Risk | Note |
|---|---|---|---|
| Understand | P-8 | None — read-only | Also yields an inferred Domain Profile, often better than one written from scratch |
| Decide | P-1 (refine the inferred profile), P-9 | None | Human decision on scope and exceptions |
| Measure | P-7 | Low | Suite first, so progress is visible from the start |
| Non-negotiable | remediation Stage 0 | Medium | Redaction and money discipline only |
| Foundation | P-2, P-3, P-4 | Low behavioural, high line-count | Mechanical; mostly mechanical replacement |
| Structural | P-5, P-6 | **Highest** | Changes interaction. One screen family at a time |
| Ongoing | P-10, P-11 | Low | Every new screen conforms by default |

**Do not run the structural stage across every screen at once.** It changes how people use the app, and a regression there is more damaging than any inconsistency it fixes.

---

*AIS Adoption Prompt Pack v1.0 | Asternest Labs*
