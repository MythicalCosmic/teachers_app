# Staff mobile product and permission specification

## Scope

This repository contains one mobile app for education-center staff. CEO,
manager, parent, and student dashboards, navigation, accounts, and settings are
out of scope. Parent and student records may appear only as objects inside an
authorized staff workflow; leadership may appear as a message sender but never
as a management console.

## Stable navigation

The five positions remain stable so muscle memory survives role changes:

| Role | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Teacher | Today | Groups | Tasks | Inbox | More |
| Assistant | Today | Groups | Tasks | Inbox | More |
| Methodist | Today | Quality | Tasks | Inbox | More |
| Reception | Today | Leads | Admissions | Inbox | More |
| Auditor | Audit | Signals | Cases | Alerts | More |

Contextual features such as attendance, cards, assignments, printing, surveys,
materials, reports, and immutable logs live inside the relevant workspace or
the More hub. They are not silently truncated from navigation.

## Permission rules

- Teachers manage assigned groups, attendance, recognition cards,
  assignments, authorized conversations, surveys, and print requests. They do
  not see payment data.
- Assistants work only in assigned groups. Attendance and other consequential
  actions remain capability-gated; recognition cards are off by default.
- Methodists can review academic quality, teachers, groups, fairness, reports,
  tests, and scoped AI analysis. They do not administer finance.
- Reception can manage leads, admissions, placement, approved contact fields,
  payment status, and audited reminders. They cannot access private teaching
  notes or teaching AI.
- Auditors read source records and immutable logs but may create, annotate,
  assign, escalate, resolve, or dismiss audit cases. Every disposition is
  expected to be logged by the eventual production service.

Routes, fields, and actions must all enforce capability checks. Hiding a tab is
not a security boundary.

## Interaction and visual rules

- Preserve the warm editorial visual system: pearl/cream surfaces, restrained
  geometric texture, strong mono numerals, rounded physical cards, semantic
  color, and the eight-point StarForge mark.
- Use liquid glass only for compact navigation chrome and sheets on supported
  Apple platforms. Dense content stays on legible surfaces. Android uses a
  native opaque Material treatment. Users can disable the effect.
- Motion is interruptible and normally 180–320 ms. Reduced-motion removes
  spatial movement while preserving state feedback.
- Consequential actions require clear confirmation or provide undo. Routine
  actions use optimistic feedback and subtle optional haptics.
- Controls use at least 44–48 logical-pixel targets, keyboard-safe layouts,
  screen-reader labels, and status cues that do not rely on color alone.
- First-use guidance is short and contextual; empty, loading, error, offline,
  and retry states explain what the user can do next.

## Data boundary

The checked-in app currently uses a deterministic local repository so every
screen and action can be exercised without an undocumented server. It is not a
claim of production authentication, printing, push delivery, AI, or sync. A
production adapter must provide authenticated sessions, server-issued
capabilities, tenant scope, encrypted token storage, conflict handling,
telemetry, and the organization’s API contracts without weakening the rules
above.
