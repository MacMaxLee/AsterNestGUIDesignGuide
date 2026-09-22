# Asternest Interface Standard (AIS)

**Version 1.0 · Asternest Labs**
**Status:** Baseline
**Applies to:** every Asternest Labs application, on every platform
**Companion:** AIS Adoption Prompt Pack v1.0

---

## 0. What This Is, and What It Is Not

### 0.1 The core rule

**AIS fixes meaning and structure. It does not fix appearance.**

An accounting ledger, a marketing ERP, an I Ching study app and an exam tool should not look alike. They should *behave* alike: the same action type is always the same color within an app, destructive actions always announce themselves, a list never loses its place after an edit, an error is always copyable, a number is never shown without the context that makes it meaningful.

So AIS specifies **semantic slots, structural patterns, and conformance tests.** Each application chooses its own palette, typography and voice to fill those slots, subject to the constraints in §2.

A standard that dictated hex values across four unrelated products would be ignored within a year, and correctly so.

### 0.2 Three layers

| Layer | Owner | Changes |
|---|---|---|
| **Core** (this document) | Asternest Labs | Rarely. Versioned. Apps declare conformance to a version |
| **Domain Profile** | Each application | Adds semantics the core cannot know about |
| **Brand Expression** | Each application | Palette, type, illustration, voice |

A Domain Profile may **add** semantic tokens and annotation requirements. It may **never redefine or remove** a core one. If an app needs `action.destructive` to mean something else, the app is wrong.

### 0.3 Conformance is tested, not asserted

Every rule in §1 through §6 has a corresponding test in §8. **A standard nobody can verify is decoration.** An application claims "AIS 1.0 conformant" only when the §8 suite passes, or when it publishes an exception list (§9).

---

## 1. Structural Patterns

### 1.1 List-detail is the primary screen shell

Left: search, filters, master list. Right: the record's CRUD surface.

```
+---------------------+--------------------------------------+
| search / filter     |  record form                         |
|---------------------|                                      |
| o record 1          |  (optionally: header + child lines)  |
| * record 2   <--    |                                      |
| o record 3          |                                      |
+---------------------+--------------------------------------+
```

**Binding rules:**

- **The list keeps its place.** Selection, scroll position, filter and sort survive an edit-save cycle and survive navigating away and back. This is the single most common failure of this pattern and the first thing §8 tests.
- **Unsaved changes block a selection change**, not just navigation away. The prompt appears before the selection moves, and the selection does not move until the person decides.
- **Narrow viewports split into two routes.** Drill in, and back returns to the list at its prior scroll position.
- **Deep links address a record** and restore the surrounding list state.
- **Two empty states, never one.** "No records exist" and "no records match your filter" are different situations and must look different. The second offers a way to clear the filter.

### 1.2 Header/detail with a declared invariant

Used *inside* the list-detail right panel, only where child lines must satisfy an assertion the header makes.

| Example | Invariant |
|---|---|
| Journal entry / lines | Debits equal credits |
| Cost record / allocations | Allocations total the cost amount |
| Invoice / lines | Lines plus tax equal the total |
| Budget / periods | Period amounts total the budget |

**Binding rules:**

- The invariant is a **required parameter** of the shell. A header/detail screen with no invariant is using the wrong shell — enforce at compile time where the language allows.
- The **residual is always visible**, never only at save time.
- **Save is blocked while the residual is non-zero.**
- **Rounding residuals are explicitly assigned, never lost.** An amount that does not divide evenly across child lines must have its remainder placed somewhere visible.

### 1.3 Report shell

- Period selector, comparison period, grouping, drill path.
- **Drill-through to source records is mandatory.** A reported figure must be traceable to the rows that produced it. A number nobody can trace is a number nobody trusts.
- **Footing assertion:** where components must sum to a total, the residual is displayed and a non-zero one is flagged as an error, never hidden.
- **Annotation bar** (§3.2) on every report.
- Export carries the annotation bar.

### 1.4 History is reachable from the record

Any application that records an audit trail exposes it **two ways**: a standalone history screen, and a "history" affordance on the record itself. The second is the one people actually use.

**History UI is read-only.** No edit or delete affordance may exist anywhere in it.

### 1.5 Navigation

- **Task-oriented grouping, not entity-oriented.** Group by what someone is trying to do.
- **Maximum two levels.** A third level means the grouping is wrong.
- **Categories fold and unfold**, state persisted per user.
- **Not an accordion** — expanding one category does not collapse others. A collapsed category containing the active route shows an indicator.
- **Permission filtering happens server-side.** The client must not receive items it may not use. Hiding in the client is not authorization.
- **Unavailable is not the same as unauthorized.** An item outside the user's plan or licence shows a distinct state from one their role forbids. Forbidden items are absent; unavailable items are visible with an upgrade path.
- A **command palette** respects identical filtering. A palette that bypasses menu filtering is a security defect, and it is the most likely place for that bug.

---

## 2. Color and Semantics

### 2.1 Semantic tokens, never per-control color

**Rejected:** assigning a distinct color to each button, menu item or chip.

Two reasons. Accessibility guidance forbids color as the sole carrier of meaning, and arbitrary per-control color destroys the predictability that makes an interface fast to use. Eight consistent meanings beat forty arbitrary hues.

### 2.2 Core token set

Every application implements exactly these. A Domain Profile may add; it may not redefine.

| Token | Meaning |
|---|---|
| `action.primary` | The main forward action |
| `action.confirm` | Approval, authorization, acceptance |
| `action.destructive` | Irreversible or data-removing |
| `action.caution` | Consequential or externally visible — sends, publishes, spends, changes what others see |
| `action.neutral` | Non-committal — cancel, close, back |
| `state.info` | Informational, non-blocking |
| `state.warning` | Needs attention, not yet an error |
| `state.error` | Failed or invalid |
| `state.unavailable` | Cannot be computed or does not apply — **visually distinct from zero or empty** |

### 2.3 Binding rules

- **Every token pairs with a required icon.** A token used without its icon is a conformance failure. Color alone never carries meaning.
- **Every token passes contrast requirements against its surface in every theme the app ships.**
- **No color literal outside the token definition.** Enforced by source scan.
- **Module or section identity is carried by icon, and optionally by an accent used in headers and breadcrumbs — never by re-coloring actions.** A save button is the same color in every section.
- `state.unavailable` is load-bearing. "No value" and "a value of zero" must be distinguishable by more than color, because they mean opposite things.

### 2.4 Brand expression

Each app chooses its own palette to fill the slots. The constraints are: the semantic mapping holds, contrast passes, and the same meaning is consistent within the app. Nothing requires two Asternest apps to share a hue.

---

## 3. Data Presentation

### 3.1 No bare consequential values

A value whose meaning depends on context is never rendered without that context. This is the most transferable rule in the standard and the one each Domain Profile extends.

| App type | A bare value would omit |
|---|---|
| Any monetary | Currency |
| Accounting | Currency, period, basis (accrual/cash), posted vs draft |
| Marketing analytics | Currency, cost basis, attribution model, data sufficiency, freshness |
| Any computed metric | Definition version, denominator, data sufficiency |
| Any imported figure | Source, import time, reconciliation status |

**Implementation:** a shared value component that *requires* its annotations, so omitting them is a compile error or a throw rather than a code-review catch.

### 3.2 Annotation bar

Every report and every dashboard figure carries its annotations — inline, as a badge, or in a header bar. The Domain Profile lists which annotations are required for that app.

### 3.3 Grid, list, tree

- **Virtualized.** State a row-count target and test against it.
- Multi-column sort with visible precedence; per-column typed filters.
- Column show/hide, reorder, resize; layout persisted per user per screen.
- **Export reflects the current view** — filters, sort, column visibility. Exporting something different from what is on screen is a defect.
- **Aggregation refuses rather than lying.** Where a footer cannot correctly aggregate — mixed currency, mixed grain, mixed basis — it states the refusal and why. It does not show a number.
- Full keyboard navigation; row and column context announced to assistive technology.

### 3.4 Data Grid (Excel-like)

For tabular data entry and display, an Excel-like data grid provides familiar interaction patterns:

**Core Features:**
- **Editable cells** with type-aware editing (text, number, currency, date, time, boolean, select)
- **Column operations:** resize, reorder, show/hide; layout persisted per user per screen
- **Multi-column sort** with visible precedence indicators (1, 2, 3...)
- **Per-column typed filters** with real-time filtering
- **Row selection** (single or multi-select mode)
- **Keyboard navigation:** arrow keys move focus, Enter/F2 edits, Escape cancels, Tab crosses columns

**Binding rules:**
- **Virtualized rendering** for performance. State a row-count target and test against it
- **Export reflects current view** — filters, sort, column visibility (C-12)
- **Cell values follow annotation rules** — a currency cell displays with currency symbol
- **Copy/paste support** for clipboard interoperability
- **Row numbers optional** but recommended for large datasets
- **Footer shows:** row count, selected count, filter status, sort status

**Pagination:**
Pagination provides navigation through large datasets:

| Element | Purpose | Required |
|---|---|---|
| Page indicator | Shows "Page X of Y" or "1-10 of 100" | Yes |
| Previous/Next buttons | Navigate between adjacent pages | Yes |
| First/Last buttons | Jump to extremes of dataset | Optional |
| Page size selector | Choose rows per page (10, 25, 50, 100) | Yes |
| Page number input | Direct navigation to specific page | Optional |

**Pagination Binding Rules:**
- **Page size persisted** per user per grid — user preference survives session
- **Page resets on filter change** — new filter always shows page 1
- **Sort preserves page** where feasible — if data allows, maintain position after re-sort
- **Disabled states clear** — Previous/First disabled on page 1; Next/Last disabled on final page
- **Loading state** — pagination controls disabled during data fetch
- **Empty state** — pagination hidden when zero records exist
- **Total count required** — "Page 1 of ?" is not acceptable; fetch count before or with data
- **Keyboard accessible** — all pagination controls reachable by keyboard

### 3.5 Grid Layout

For card-based or tile-based displays:

- **Responsive columns:** adapt to available width with minimum child width constraint
- **Consistent spacing:** use design token spacing values
- **Aspect ratio control:** maintain consistent card proportions
- **Adaptive mode:** automatically calculate column count based on container width

### 3.6 Autocomplete

Type-ahead autocomplete provides efficient selection from large option sets:

**Core Features:**
- **Type-ahead filtering** with debounced input for performance
- **Keyboard navigation:** Arrow Up/Down to highlight, Enter to select, Escape to close
- **Custom suggestion rendering** with support for icons, secondary text, and custom layouts
- **Clear button** to reset selection
- **Loading state** for async data fetching
- **Error state** with validation message display
- **Selection indicator** showing currently selected item

**Binding Rules:**
- **Suggestions are filtered client-side or server-side** depending on data volume
- **Maximum visible suggestions** configurable (default: 8) to prevent overwhelming dropdowns
- **Mouse and keyboard parity:** both interaction methods must be fully functional
- **Focus management:** dropdown appears on focus, closes on blur (with delay for click handling)
- **Accessibility:** ARIA attributes for combobox pattern, announced to assistive technology
- **Placeholder text** indicates expected input format
- **Display text extraction** from complex objects via configurable function

**Visual Styles:**
| Style | Use Case |
|---|---|
| Standard | Default appearance with subtle border |
| Outlined | Emphasized border for form context |
| Filled | Filled background for visual grouping |

### 3.7 Media and File Handling

Applications handling file uploads/downloads implement a unified file information structure:

**File Information Structure (for database handling):**

| Field | Purpose | Required |
|---|---|---|
| `id` | Unique identifier for database reference | Yes |
| `fileName` | Original file name with extension | Yes |
| `extension` | File extension (e.g., `.pdf`, `.jpg`) | Yes |
| `mimeType` | MIME type (e.g., `image/jpeg`, `application/pdf`) | Yes |
| `sizeBytes` | File size in bytes | Yes |
| `folderPath` | Directory/folder path where file is located | Yes |
| `fullPath` | Complete file path including filename | Yes |
| `mediaType` | Classification (image, video, audio, pdf, csv, text, document, spreadsheet) | Yes |
| `createdAt` | File creation timestamp | No |
| `modifiedAt` | File modification timestamp | No |
| `thumbnailPath` | Path to thumbnail (for images/videos) | No |
| `durationSeconds` | Duration in seconds (for audio/video) | No |
| `width` | Width in pixels (for images/videos) | No |
| `height` | Height in pixels (for images/videos) | No |
| `checksum` | Hash for integrity verification | No |
| `status` | Upload status (pending, uploading, completed, failed, cancelled) | Yes |
| `errorMessage` | Error description if upload failed | No |

**Supported Media Types:**

| Type | Extensions | Icon Required |
|---|---|---|
| Image | .jpg, .jpeg, .png, .gif, .webp, .svg, .bmp | Yes |
| Video | .mp4, .mov, .avi, .mkv, .webm, .m4v | Yes |
| Audio | .mp3, .wav, .aac, .ogg, .flac, .m4a | Yes |
| PDF | .pdf | Yes |
| CSV | .csv | Yes |
| Text | .txt, .md, .json, .xml, .html | Yes |
| Document | .doc, .docx, .odt, .rtf | Yes |
| Spreadsheet | .xls, .xlsx, .ods | Yes |

**Media Picker Binding Rules:**
- **Drag-and-drop zone** with visual feedback on drag-over
- **Click-to-browse** fallback for accessibility
- **Type filtering** by allowed extensions
- **Size validation** with configurable maximum
- **Multiple selection** mode with file count limit
- **Preview before upload** for images/videos where feasible
- **Progress indication** during upload
- **Status display:** pending, uploading, completed, failed with error message
- **Download action** for completed uploads
- **Remove action** with confirmation for destructive operations
- **File info display:** formatted size, dimensions, duration as applicable
- **Database-ready output:** all fields populated for immediate storage

### 3.8 Document Scanning and OCR

Applications requiring document capture (invoices, receipts, bills) implement a multi-stage pipeline:

**Pipeline Stages:**
```
Media Picker → OCR → Field Extraction → Line Item Parsing → Review → Commit
```

**OCR Provider Chain:**

| Tier | Provider | Platform | Notes |
|---|---|---|---|
| 0 | Self Mapping | All | Manual entry fallback |
| 1 | Platform Vision | iOS/macOS: Apple Vision, Android: ML Kit | On-device, free, offline |
| 2 | Local AI | Desktop: MLX/Ollama | On-device inference |
| 3 | Browser OCR | Web | Tesseract.js for browser-based OCR |
| 4 | Cloud LLM | All | Claude / ChatGPT / Gemini (user-selectable) |

**Line Item Parsing Binding Rules:**
- **Skip keywords excluded:** SUBTOTAL, TOTAL, TAX, CASH, CREDIT, PAYMENT, AMOUNT, WHOLESALE, etc.
- **Skip patterns excluded:** Location identifiers (e.g., "Eastvale #1317"), masked card numbers, date lines
- **Costco format supported:** SKU + description on one line, price on next line
- **Price format required:** Decimal prices only (###.##) to avoid false positives
- **Tax code validation:** Single uppercase letter only (A-Z); OCR artifacts like "Ii" are ignored
- **Minimum description length:** At least 2 consecutive letters required

**Extracted Invoice Structure:**

| Field | Type | Required | Description |
|---|---|---|---|
| `invoiceNumber` | String | No | Extracted invoice/receipt number |
| `vendorName` | String | Yes | Vendor name (with store number if detected) |
| `vendorAddress` | String | No | Street address (excludes store number prefix) |
| `invoiceDate` | Date | No | Transaction date |
| `totalAmount` | Decimal | Yes | Total amount |
| `subtotal` | Decimal | No | Subtotal before tax |
| `taxAmount` | Decimal | No | Tax amount |
| `lineItems` | Array | Yes | Parsed line items |
| `rawOCRText` | String | No | Original OCR text for debugging |

**Line Item Structure:**

| Field | Type | Required | Description |
|---|---|---|---|
| `description` | String | Yes | Item description |
| `quantity` | Decimal | Yes | Quantity (default: 1) |
| `unitPrice` | Decimal | Yes | Price per unit |
| `amount` | Decimal | Yes | Line total |
| `taxCode` | String | No | Single letter tax code (A, E, etc.) |
| `confidence` | Decimal | No | Extraction confidence (0.0-1.0) |

**Review Output Display:**
- **Text tab:** Formatted invoice text with line items table, totals, and provider info
- **JSON tab:** Structured JSON output for API/database integration
- **Copy to clipboard:** Both formats must be copyable
- **Selectable text:** All output text must be selectable for manual copying

**Conformance Tests (C-51 to C-55):**
- **C-51:** Line item parser skips non-item lines (SUBTOTAL, TAX, location identifiers)
- **C-52:** Tax code validation accepts only single uppercase letters
- **C-53:** OCR output displays both Text and JSON formats with tab selector
- **C-54:** Copy to clipboard works for both Text and JSON output
- **C-55:** Line items display shows description, quantity, unit price, amount, and tax code

---

## 4. Errors and Diagnostics

### 4.1 Error envelope

Every error carries:

| Field | Purpose |
|---|---|
| `errorCode` | Stable enum, never a bare string |
| `userMessage` | Plain language, actionable, no jargon, states what the person can do |
| `technical` | Exception type, message, location, failing operation |
| `context` | Correlation ID, user, route, app version, platform, OS, locale, timestamp |
| `serverContext` | Request ID, endpoint, status, server version, where applicable |

**Every error code has a registered, localized user message.** A test enumerates the enum and fails on any code lacking one — an unregistered code must not be able to reach a user.

**No user message contains a stack trace, class name, SQL fragment, or the word "exception."**

### 4.2 Copyable diagnostics — and redaction

The error is copyable as one formatted block containing both the human explanation and the technical payload.

**The block is designed to be pasted into a support ticket or an AI chat. It leaves the trust boundary. Redaction is therefore a correctness requirement, not a courtesy.**

- Personal data, credentials, tokens and secrets are removed before the block is assembled.
- Redacted values appear as a typed marker — `[REDACTED:email]` — so a reader knows a value existed and what kind, without seeing it.
- The correlation ID is retained. It is how support joins the report to server logs and carries no personal data.
- **Redaction reuses the application's single redaction filter.** Not a second implementation.

### 4.3 Capture

- Screen capture is available by **global shortcut**, not by an icon on every screen.
- It is **automatically offered when reporting an error**, which is when it is actually wanted.
- **Preview before it leaves the device is mandatory.** A capture contains whatever personal data was on screen.
- Never auto-saved, never auto-transmitted.

---

## 5. Validation and Formatting

### 5.1 One shared, platform-free layer

Validation lives in a module with **no UI framework dependency**, importable by client and server alike, so a rule cannot drift between them.

### 5.2 Binding technique table

Regex is correct for a minority of formats and wrong for most.

| Format | Technique |
|---|---|
| Email | Permissive pattern only. Reject the clearly malformed. Real validation is a confirmation message |
| URL | Native URL parser, not regex. Scheme allowlist. Reject embedded credentials |
| Phone | Phone-number library. **Not regex.** Format is country-dependent |
| **Money** | **The application's exact decimal type. Never regex, never floating point.** Currency required, no default |
| Date | Date library with an **explicit** format. Reject ambiguous input rather than guessing day/month order |
| Time | Explicit timezone required. A time without a zone is invalid input, not a defaultable value |
| **Date input** | **Locale-aware format (system localization). Dual entry: popup calendar picker AND keyboard entry in locale format (e.g., MM/dd/yyyy or dd/MM/yyyy). Both methods must be available.** |
| **Time input** | **Locale-aware format (12-hour or 24-hour per system). Dual entry: popup time picker AND keyboard entry in locale format. Both methods must be available.** |
| **DateTime** | **Combined date and time fields. Each follows its respective rules above. Never combine into a single ambiguous text field.** |
| Postal code | Per-country rules. Regex acceptable **per country**. Unknown country accepts free text |
| Administrative area | Per-country list where known, free text otherwise |
| Numeric | Explicit parse, locale-aware separators. Not regex |
| Payment card | **Out of scope by default.** See §5.4 |

### 5.3 Date and Time Input Requirements

Date and time inputs are frequent sources of user error and localization bugs. The following rules are binding:

**Date input:**
- **Dual entry required:** Both popup calendar picker AND keyboard text entry must be available
- **Locale-aware format:** Display format follows system localization (e.g., MM/dd/yyyy for US, dd/MM/yyyy for UK/EU)
- **Format hint:** Show the expected format pattern as placeholder or hint text
- **Parse on change:** Validate and parse typed input in real-time, not just on submit
- **Calendar picker:** Opens with current value selected; respects min/max date constraints

**Time input:**
- **Dual entry required:** Both popup time picker AND keyboard text entry must be available
- **Locale-aware format:** 12-hour (e.g., 2:30 PM) or 24-hour (e.g., 14:30) per system locale
- **Format hint:** Show the expected format pattern as placeholder or hint text
- **Parse on change:** Validate and parse typed input in real-time

**DateTime (combined):**
- **Separate fields:** Date and time are separate input fields, never a single ambiguous text input
- **Each follows its rules:** Date field follows date rules; time field follows time rules
- **Clear relationship:** Visual grouping indicates they belong together

### 5.4 Universal rules

- **No validator defaults to one country.** Every one accepts a country parameter.
- **Formatting never mutates a stored value.** Formatters return display strings and take no mutable input.
- Validators return all failures, not the first.
- Every user-facing message is localized. No hardcoded strings.

### 5.5 Payment card data

**Accepting or storing a card number places the application in payment-industry compliance scope**, a burden almost never proportionate to the feature. Default position: no Asternest application accepts a card number into any form or persists one in any table. Where payment is required, the processor's hosted fields or tokenization handles the number and it never reaches the application.

---

## 6. Accessibility, Localization, Responsiveness

### 6.1 Accessibility baseline

Every application meets WCAG 2.1 Level AA on all primary workflows:

- Contrast verified automatically, in every theme, not by eye.
- Every interactive element reachable and operable by keyboard, with visible focus and logical order.
- Semantic labels on every control; state changes announced.
- Color never the sole signal (§2.3).
- Motion respects the platform's reduce-motion setting.

### 6.2 Localization

- **No hardcoded user-facing string.** Enforced by source scan.
- Per-user or per-tenant language, timezone, currency and date format, without code change.
- Layouts tolerate text expansion. Test with a long-string locale.

### 6.3 Responsiveness

Three breakpoints minimum — compact, medium, expanded — with the list-detail split at §1.1. Each app states its pixel values; the standard requires that all three are tested.

---

## 7. Domain Profile

Each application publishes a short profile declaring its extensions.

```markdown
# <App> Domain Profile — conforms to AIS 1.0

## Added semantic tokens
| Token | Meaning | Why the core set is insufficient |

## Required value annotations (§3.1)
| Value type | Required annotations |

## Invariant-bearing header/detail screens (§1.2)
| Screen | Invariant |

## Aggregation refusal cases (§3.3)
| Case | Why it cannot aggregate |

## Breakpoints
| Compact | Medium | Expanded |

## Palette
| Token | Light | Dark |

## Exceptions to AIS 1.0 (§9)
| Rule | Reason | Planned resolution |
```

### 7.1 Worked example — a marketing analytics app

| Addition | Detail |
|---|---|
| Token `state.ai` | AI-generated or AI-suggested content must be distinguishable from executed action |
| Token `state.provisional` | Figures inside a restatement window are not yet final |
| Annotations | Every monetary figure: currency, cost basis, data sufficiency, freshness |
| Refusal cases | Mixed-currency footer without an exchange rate; mixed-grain aggregation |

### 7.2 Worked example — a double-entry accounting app

| Addition | Detail |
|---|---|
| Token `state.posted` vs `state.draft` | Posted entries are immutable; the distinction must be unmissable |
| Annotations | Every amount: currency, period, posted status |
| Invariants | Journal entry lines balance; subledger totals reconcile to control accounts |
| Refusal cases | Cross-period aggregation without a stated basis |

---

## 8. Conformance Test Suite

Stack-neutral. Each application implements all of these, in its own framework.

| # | Test | Passes when |
|---|---|---|
| **C-01** | Contrast | Every token against every surface, every theme, meets AA — automated, not visual |
| **C-02** | Token purity | No color literal outside the token definition. Plant one; the scan catches it |
| **C-03** | Icon pairing | A token used without its paired icon fails. Plant one; caught |
| **C-04** | Annotation enforcement | A consequential value cannot be rendered without its required annotations. Omission is a compile error or a throw |
| **C-05** | List state retention | Filter, select, edit, save → list retains filter, sort, scroll and selection |
| **C-06** | Selection guard | Unsaved changes block a selection change; selection does not move behind the prompt |
| **C-07** | Two empty states | No-records and no-matches render differently; the second offers clear-filters |
| **C-08** | Invariant enforcement | Save blocked while residual ≠ 0; residual always visible; uneven-split remainder explicitly assigned |
| **C-09** | Wrong-shell detection | A header/detail screen with no declared invariant fails to construct |
| **C-10** | Drill-through | A reported figure traces to source rows, and the drilled set reconciles to the parent figure |
| **C-11** | Aggregation refusal | A footer that cannot correctly aggregate shows a stated refusal and **no number** |
| **C-12** | Export fidelity | Exported rows, order and columns match the visible view exactly |
| **C-13** | Error registry | Every error code has a localized user message. Plant a gap; caught |
| **C-14** | No jargon | No user message contains a stack trace, class name, SQL fragment or "exception" |
| **C-15** | Redaction | Trigger an error whose context holds an email, a phone number, a token, a password value and a person's name. **None appears in the copied block**; each is a typed marker |
| **C-16** | Correlation join | The correlation ID in the copied block matches the server log line for the same request |
| **C-17** | Capture consent | A capture cannot be attached or transmitted without preview acknowledgement |
| **C-18** | Validation parity | The same validator, client and server, same input, identical result |
| **C-19** | Money discipline | No monetary value is parsed by regex or held in a floating-point type. Source scan |
| **C-20** | Multi-country | Phone, postal code and administrative area validate correctly for four countries on different continents |
| **C-21** | Ambiguity refusal | An ambiguous date without an explicit format is rejected, not guessed |
| **C-22** | Keyboard reach | Every interactive element reachable and operable by keyboard; focus visible |
| **C-23** | Assistive labels | Every control labelled; state changes announced |
| **C-24** | No hardcoded strings | Source scan finds no user-facing literal outside localization files |
| **C-25** | Text expansion | Layouts survive a long-string locale without truncation or overflow |
| **C-26** | Breakpoints | All three breakpoints render without horizontal overflow |
| **C-27** | Menu filtering | The menu payload from the server contains no forbidden item — asserted on the payload, not the rendered UI |
| **C-28** | Palette filtering | The command palette applies identical filtering; a forbidden target is unreachable by search |
| **C-29** | Fold persistence | Category expansion persists across restart; expanding one does not collapse others |
| **C-30** | History read-only | History UI exposes no mutation affordance anywhere |
| **C-31** | Date input dual entry | Date fields provide BOTH popup calendar picker AND keyboard text entry |
| **C-32** | Time input dual entry | Time fields provide BOTH popup time picker AND keyboard text entry |
| **C-33** | Date/time locale format | Date and time display formats match system locale; format hint shown |
| **C-34** | DateTime separation | Date and time are separate fields, never combined into single ambiguous input |
| **C-35** | Data grid keyboard | Data grid supports arrow keys, Enter/F2 to edit, Escape to cancel, Tab across columns |
| **C-36** | Data grid export fidelity | Exported data matches visible grid state (filters, sort, columns) |
| **C-37** | Media picker type filter | Media picker only accepts files matching configured allowed types |
| **C-38** | Media picker size limit | Media picker rejects files exceeding configured maximum size |
| **C-39** | File info completeness | File picker returns all required fields for database storage |
| **C-40** | Media type icons | Each media type displays its designated icon |
| **C-41** | Upload status display | File upload shows status (pending, uploading, completed, failed) with appropriate visual |
| **C-42** | Grid layout responsive | Grid layout adapts columns to available width respecting minimum child width |
| **C-43** | Pagination page indicator | Pagination shows current page and total pages or record range |
| **C-44** | Pagination navigation | Previous/Next buttons work correctly; disabled at boundaries |
| **C-45** | Pagination page size | Page size selector allows choosing rows per page; preference persisted |
| **C-46** | Pagination filter reset | Changing filter resets to page 1 |
| **C-47** | Pagination keyboard access | All pagination controls reachable and operable by keyboard |
| **C-48** | Autocomplete keyboard nav | Arrow Up/Down highlights suggestions; Enter selects; Escape closes dropdown |
| **C-49** | Autocomplete clear | Clear button resets selection and input text |
| **C-50** | Autocomplete accessibility | ARIA combobox attributes present; state announced to assistive technology |
| **C-51** | Line item parser skip | Line item parser excludes SUBTOTAL, TAX, AMOUNT, location identifiers, masked cards |
| **C-52** | Tax code validation | Tax code accepts only single uppercase letter (A-Z); rejects OCR artifacts like "Ii" |
| **C-53** | OCR output tabs | OCR output displays both Text and JSON formats with tab selector |
| **C-54** | OCR output copy | Copy to clipboard works for both Text and JSON output formats |
| **C-55** | Line items display | Line items table shows description, quantity, unit price, amount, and tax code columns |

---

## 9. Exceptions

**Partial conformance with a published exception list beats a stalled rewrite.**

An application may declare an exception in its Domain Profile:

| Rule | Reason | Planned resolution |
|---|---|---|

Rules for exceptions:

- **C-15 (redaction) admits no exception.** A diagnostic block that leaks personal data is a privacy incident, not a style deviation.
- **C-19 (money discipline) admits no exception** in any application handling money.
- All other rules may be excepted with a stated reason and a resolution intent.
- An exception with no planned resolution is permitted, provided it says so honestly. "We will not do this" is a legitimate entry; a silent gap is not.

---

## 10. Per-Stack Binding

The standard is stack-neutral. These are the mappings for the stacks in use.

### 10.1 SwiftUI (macOS, iOS)

| AIS concept | SwiftUI |
|---|---|
| Token set | Color assets in an asset catalog with light/dark variants, surfaced through a custom `EnvironmentKey` or a `Theme` struct in `@Environment` |
| List-detail shell | `NavigationSplitView` — it is this pattern natively, including the compact-width collapse |
| List state retention | Hold selection and scroll state in the view model, not in view state, so it survives view recreation |
| Selection guard | Intercept the selection binding; do not commit the new value until resolved |
| Annotation enforcement | A `View` whose initializer requires the annotation parameters — omission becomes a compile error |
| Keyboard | `.focusable()`, `.focused()`, `.onKeyPress`, `@FocusState` |
| Accessibility | `.accessibilityLabel`, `.accessibilityValue`, `.accessibilityAddTraits`; `.accessibilityRespondsToUserInteraction` |
| Reduce motion | `@Environment(\.accessibilityReduceMotion)` |
| Capture | `ImageRenderer` for view capture; `CGWindowListCreateImage` for full-window on macOS |
| Contrast testing | Compute ratios in unit tests from the asset catalog values — do not eyeball |
| Localization | String catalogs; enforce by scanning for literal `Text("...")` |

### 10.2 Flutter (six platforms)

| AIS concept | Flutter |
|---|---|
| Token set | A `ThemeExtension<T>` holding the semantic tokens. Material's `ColorScheme` alone is **not sufficient** — it has no vocabulary for `state.unavailable` or domain tokens |
| List-detail shell | Custom adaptive scaffold; `Row` of two panes at medium/expanded, separate routes at compact |
| List state retention | State held above the route, in a controller or provider, not in the `State` of a disposed widget |
| Annotation enforcement | Required named parameters on the value widget's constructor |
| Keyboard | `Shortcuts`, `Actions`, `FocusTraversalGroup`, `CallbackShortcuts` |
| Accessibility | `Semantics`; Flutter's accessibility guideline tests for contrast, tap-target size and labels |
| Reduce motion | `MediaQuery.disableAnimationsOf(context)` |
| Capture | `RepaintBoundary` + `toImage`; note the platform constraints on web |
| Validation layer | A pure Dart package with **no Flutter import** — assert by source scan, so server and client share it |
| Localization | ARB files; enforce by scanning for literal strings in widget code |

### 10.3 Web

| AIS concept | Web |
|---|---|
| Token set | CSS custom properties on `:root`, redefined under `prefers-color-scheme: dark` and under an explicit theme attribute |
| List-detail shell | CSS grid two-column at wide; single column with routed detail at narrow |
| List state retention | Filter and selection in the URL query string — it makes deep linking and restoration the same mechanism |
| Keyboard | Native focus order; avoid positive `tabindex` |
| Accessibility | Semantic HTML first, ARIA only where HTML has no equivalent; automated contrast and landmark checks in CI |
| Reduce motion | `@media (prefers-reduced-motion: reduce)` |
| Capture | Browser capture is constrained; degrade with a clear message rather than a broken control |

### 10.4 Adding a stack

A new stack is admitted to AIS when it can demonstrate the §8 suite. If a rule cannot be expressed in that stack, it becomes a documented exception (§9) — not a silent omission.

---

## 11. Versioning

- AIS is versioned semantically. Applications declare their conformance version in the Domain Profile.
- A **major** bump changes or removes a core rule and requires each app to re-declare.
- A **minor** bump adds a rule; existing apps may adopt at their own pace and list the gap as an exception until they do.
- The conformance suite is versioned with the standard.

---

*Asternest Interface Standard v1.0 | Asternest Labs*
