# StarForge Staff deep bug, security, performance, and dead-design audit

**Audit date:** 2026-07-21
**Audited application:** `app/` (the shipped Flutter staff application)
**Baseline branch/commit:** `main` at `d75c7b0`
**Staff-only scope:** teacher, assistant, methodist, reception, and auditor. CEO/manager, parent, and student applications are intentionally excluded.

## Executive conclusion

The application had a clean analyzer and a passing test suite before this audit, but it was not production-truthful in several important places. Some routes that appeared to be real methodist, reception, audit, recognition, profile, search, and refresh features were actually backed by demo stores, hard-coded people, local-only mutations, or no backend operation at all. There were also concrete security defects: production message content and staff PII were persisted as plaintext, cache keys were not tenant-scoped, rejected manager accounts could leave a valid token in secure storage, tenant discovery could downgrade to remote cleartext HTTP, logout did not purge messaging data, Android allowed backups, and attachment uploads were unbounded.

This pass catalogued **46 findings**:

| Severity | Count | Fixed now | Mitigated now | Still open |
| --- | ---: | ---: | ---: | ---: |
| Critical | 4 | 4 | 0 | 0 |
| High | 20 | 11 | 4 | 5 |
| Medium | 18 | 7 | 3 | 8 |
| Low / maintenance | 4 | 1 | 1 | 2 |
| **Total** | **46** | **23** | **8** | **15** |

“Mitigated” means the application no longer lies to the user or accepts the original unsafe behavior, but a complete product/backend implementation is still required. “Open” means no honest small local patch can finish the work safely in this pass.

The most important outcome is that production mode now fails or guides honestly instead of silently substituting demo data. The remaining release blockers are Android production signing, background push notifications, durable production task overlays, transactional multi-step mutations, several architecture/performance issues, and unavailable specialized backend contracts.

## Audit method

The review followed the real runtime path, not only static-analysis output:

1. Mapped startup, session restore, center discovery, secure-token storage, role/capability checks, router redirects, production controllers, local demo stores, and persistence boundaries.
2. Traced production routes for every in-scope staff role and compared visible actions with the API calls they actually make.
3. Audited message, notification, task, form, assignment, recognition, profile, audit, reception, and methodist flows.
4. Reviewed Android/iOS native configuration, CI workflows, signing behavior, backups, transport policy, App Store toolchain compatibility, and artifact structure.
5. Reviewed async mutation rollback, ordering, pagination, upload buffering, polling, app-wide rebuild triggers, localization, dead UI, and test coverage.
6. Added targeted regression tests before running the entire test suite and a release-mode Android build.

The audit did **not** include a live production-server penetration test, real Apple signing, a macOS CocoaPods/Xcode build, device-side memory profiling, or a Play/App Store submission. Those need the appropriate server, credentials, hardware, and external accounts.

## Severity model

- **Critical:** a production route presents invented operational data as real, or a platform cannot reliably integrate its required native dependencies.
- **High:** sensitive-data exposure, account/session isolation failure, a prominent production action that does not work, data loss/corruption, or a release blocker.
- **Medium:** material performance/reliability debt, incomplete product behavior, misleading fallback, weak test coverage, or scalability failure.
- **Low:** maintenance and UX consistency issues that should be repaired but are unlikely to corrupt data directly.

## Complete finding ledger

### Critical findings

| ID | Finding | Evidence at audit start | Status |
| --- | --- | --- | --- |
| SF-001 | Production reception routes used a global in-memory `DemoReceptionWorkspaceStore`, including fake PII and mutations that disappeared on restart. | `app/lib/router.dart`, `app/lib/screens/reception/` | **Fixed.** Production reception routes now use the real Staff Operations backend surface; demo stores remain demo-only. |
| SF-002 | The methodist quality dashboard invented named staff signals and displayed a fallback `92%` even when no server signal source existed. | `app/lib/screens/staff/methodist_quality_screen.dart` | **Fixed.** Hard-coded signals and score were removed. The empty state now states that server quality signals are not connected. |
| SF-003 | Auditor dashboard/signals/cases exposed local fake case mutations while only the immutable server audit log was authoritative. | `app/lib/router.dart`, `app/lib/screens/audit/` | **Fixed.** Production auditor routes now open the backend audit log. Local anomaly/case workflows are restricted to demo mode. |
| SF-004 | The iOS project had no `ios/Podfile` even though included Flutter plugins require CocoaPods integration. The xcconfig files also omitted Pods target-support includes. | `app/ios/`, `app/pubspec.yaml` | **Fixed statically.** A standard Flutter Podfile and Pods xcconfig includes were added. A macOS `pod install`/Xcode build is still required for platform proof. |

### High findings

| ID | Finding | Impact | Status |
| --- | --- | --- | --- |
| SF-005 | A manager/HOD could authenticate successfully at the API layer, have the bearer token written to secure storage, and then be rejected by the staff-only membership policy without clearing the token. The same issue existed during restore. | Excluded-role credentials could remain active on the device after the UI rejected the account. | **Fixed.** `staff_app_only` now signs out, revokes where possible, clears the secure vault, and has fresh-login and restore regression tests. |
| SF-006 | Production messaging persisted full contacts, phone numbers, usernames, bios, message bodies, attachment keys, and reactions in plaintext SharedPreferences. The key used only user ID, allowing cross-center collisions, and logout did not delete it. | Sensitive staff/student communications survived logout and could be restored into the wrong tenant context or Android backup. | **Fixed.** Production cache v2 stores only folder/hidden/pin/mute/archive/reaction metadata; keys include center slug, canonical server URL, and user; legacy PII caches are deleted; and logout/session expiry purge only the captured tenant scope. |
| SF-007 | The general production `AppSnapshot` wrote server tasks, forms/answers, attendance, recognition, print, and audit state to plaintext SharedPreferences. | Server-owned and potentially sensitive domain state remained on disk and in backup without a defined offline-data policy. | **Fixed.** Production persistence now stores settings only; authoritative domain state reloads from the backend. Demo mode retains its standalone snapshot behavior. |
| SF-008 | Center discovery, saved tenant connections, direct-center configuration, WebSocket URLs, and signed media URLs accepted unsafe remote cleartext or insufficiently validated endpoints. | Credentials or protected content could be sent over HTTP/WS after malicious or incorrect discovery/configuration. | **Fixed.** HTTPS/WSS is required outside canonical loopback development hosts; user-info URLs and unsafe saved/discovered connections are rejected and invalid vault entries are cleared. |
| SF-009 | Image/video attachments were read fully into memory, had no byte ceiling, and network upload/drain operations had no timeout. | Large videos could terminate the app through OOM, duplicate buffers, or leave the composer stuck indefinitely. | **Mitigated.** A 25 MiB pre-read and controller limit, HTTPS validation, redirect refusal, and two-minute request/response timeouts were added. The final design should stream from disk and transcode video instead of retaining a bounded whole-file buffer. |
| SF-010 | Notification `markRead` remembered a list index across an awaited network call. A realtime insertion/re-sort could make failure rollback overwrite the wrong notification or address an invalid index. | Incorrect read state or runtime exceptions under normal realtime activity. | **Fixed.** Rollback re-finds the immutable notification ID and preserves concurrent content. A race regression test reproduces the former failure. |
| SF-011 | `markAllRead` restored an entire old list on failure, deleting notifications received through realtime while the request was in flight. | Actual notifications could disappear from memory after a transient API failure. | **Fixed.** Only IDs changed by the optimistic action are reverted; newly arrived records remain. Covered by regression test. |
| SF-012 | The iOS App Store workflow used the macOS 15 default Xcode 16.4, and Codemagic pinned 16.4. Apple requires Xcode 26+ with the iOS 26 SDK for uploads beginning 2026-04-28. | Signed artifacts could build yet be rejected by App Store Connect. | **Fixed in configuration.** GitHub now uses `macos-26` with an Xcode-major guard; Codemagic pins Xcode 26.4. See [Apple's current requirement](https://developer.apple.com/news/upcoming-requirements/) and the [GitHub macOS 26 image](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md). |
| SF-013 | Android `release` silently falls back to the debug signing config whenever production keystore variables are absent. | An artifact named release cannot be published safely and cannot later upgrade to a differently signed production app. | **Open release blocker.** The newly built APK is release-mode but debug-signed. Introduce an explicitly named QA flavor and make production release fail closed without the real key. |
| SF-014 | There is no FCM/APNs integration, background handler, Android 13 notification permission flow, iOS push entitlement, token registration, or local-notification presentation. Realtime sockets pause in the background. | Staff receive no reliable task/message/audit alerts when the app is backgrounded or closed. | **Open product/backend feature.** Requires push-provider, backend device-token, permissions, and deep-link contracts. |
| SF-015 | Production task favorites, checklists, tags, and notes are device-side overlays, but the secure settings-only production persistence policy cannot durably store them. A restart can discard them. | The UI promises organization features that are not reliably durable in production. | **Open data-contract decision.** Put overlays on the server, or define an encrypted per-tenant local store with TTL, purge, migration, and conflict rules. Do not put them back into plaintext SharedPreferences. |
| SF-016 | `/cards` was a local/empty recognition workspace although the backend recognition path is tied to server group/student profiles. | A visible feature appeared nonfunctional despite related server capability elsewhere. | **Mitigated.** Production legacy cards routes now guide users to the server-backed group/student recognition flow. A dedicated backend-backed cards inbox remains unimplemented. |
| SF-017 | Edit Profile exposed username, bio, and avatar controls even though production update requests only persisted the supported name/email/phone fields. The success message implied all edits were saved. | Users saw false success and lost changes after reload. | **Fixed.** Unsupported production fields are disabled/hidden with an administrative-management explanation; success text names only server-saved fields. Demo mode keeps local profile customization. |
| SF-018 | Survey submission treated every HTTP 409 as successful and the local `submittedAt` state was transient. | Real conflicts could be misreported as success; a successful state could disappear after refresh. | **Mitigated.** Only the explicit `already_submitted` API code is idempotent success. Durable submitted state still depends on a backend response/list contract and needs follow-up. |
| SF-019 | The production `/student` route opened a legacy demo student surface, while real server student rows were not consistently linked through that route. | Users could see invented or disconnected student behavior. | **Fixed.** Production legacy student navigation is blocked with an honest guide to Groups and the server-backed profile. |
| SF-020 | The staff Today refresh action only slept/incremented a revision counter; it did not reload tasks or messages. | Users believed current operational data had refreshed when it had not. | **Fixed.** Refresh now awaits task and messaging refreshes before updating the visible refresh stamp. |
| SF-021 | Several task mutations are launched unawaited or surface failures only through controller state, without action-specific rollback/toast/error UX. | Network failures can look successful until a later refresh, and rapid interactions can race. | **Open.** Convert task actions to awaited, per-item mutation state with rollback and explicit failure feedback. |
| SF-022 | Assignment creation is “create, then publish”; revision feedback is “grade, then return.” These are separate server writes without idempotency or compensation. | Partial failure can leave an unpublished assignment or a graded submission not returned for revision. | **Open backend/API reliability issue.** Prefer transactional server endpoints; otherwise add idempotency keys, reconciliation, and recoverable partial-state UX. |
| SF-023 | Specialized methodist quality signals and reception desk CRUD do not have complete authoritative backend contracts in this client. | The former UI could not be made fully functional without inventing data. | **Mitigated.** Production now routes to real staff operations/audit data or a truthful unavailable state. Complete specialized APIs are still required. |
| SF-045 | Async API/controller work was not consistently bound to the session that started it. A stale 401, delayed logout, message error, cache cleanup, password rotation, or task/form/profile response from account A could clear or overwrite a newer account B. Unknown-user cleanup could also purge every tenant cache. | Cross-account sign-out, data leakage, or state corruption during normal account switches and network races. | **Fixed.** API calls capture session identity; AppState/controllers use session generations and expected-token guards; cleanup targets the captured tenant scope; password rotation pauses realtime before token replacement; and stale-operation/cross-tenant regressions were added. |

### Medium findings

| ID | Finding | Status |
| --- | --- | --- |
| SF-024 | App snapshot writes could complete out of order, allowing an older settings/state snapshot to overwrite a newer one and making `isPersisting` inaccurate. | **Fixed.** Writes are serialized and pending writes are counted. The initial serializer caused a Flutter `FakeAsync` deadlock; the audit caught it, changed idle writes to start directly, and added full-suite proof. |
| SF-025 | Every production messaging mutation encoded and rewrote the entire contact/thread/message history synchronously with unbounded growth. | **Mitigated.** Production now serializes metadata only, not message bodies, contacts, or attachments. The thread-preference, reaction, folder, and hidden-thread metadata maps are still unbounded and need pruning, TTL, and count/size caps. Demo mode remains a local standalone workspace. |
| SF-026 | `AppState` forwards messaging/notification changes and `MaterialApp.router` listens to the whole state, so many message, upload, and notification events rebuild themes/router scaffolding and unrelated UI. | **Open performance architecture issue.** Split session/settings/domain notifiers or introduce narrow selectors while keeping `MaterialApp` stable. |
| SF-027 | Reachability polls every 15 seconds online and 5 seconds offline, drains an HTTP response each time, and blocks the whole application when its health probe fails. | **Open performance/availability issue.** Use OS connectivity/lifecycle signals, API/WebSocket failures, exponential backoff with jitter, and a non-blocking offline banner for established sessions. |
| SF-028 | Russian localization is incomplete and several production messages fall back to English or hard-coded Uzbek despite Russian being advertised as a supported locale. | **Open UX/content defect.** Move copy to ARB/gen_l10n, require key completeness in CI, and add route-level Russian tests. |
| SF-029 | The visual/golden suite is opt-in, outside normal `test/`, demo-backed, and absent from CI. | **Open regression gap.** Add production-adapter goldens on a pinned renderer and run them in CI. |
| SF-030 | A primary “Call” button only opened a local timer prototype and placed no phone or VoIP call. | **Fixed truthfully.** The action is hidden in production; the prototype remains available only in demo mode. |
| SF-031 | Production bootstrap constructs/parses demo state before replacing it with the remote empty snapshot. | **Open startup/architecture debt.** Branch before demo seed construction and store settings independently. |
| SF-032 | Global search used legacy local lists that are empty in production and normal production navigation could not reach it. | **Mitigated.** Direct production navigation is now blocked with a truthful guide. A real federated search API/controller remains absent. |
| SF-033 | Sensitive chats/student/audit screens remained visible in OS recent-app thumbnails. | **Fixed at Flutter layer.** A full-screen privacy shield appears while inactive/hidden/paused. Product policy should still decide whether Android `FLAG_SECURE` is required. |
| SF-034 | The app builds one large universal APK and CI builds only debug APKs, not a Play AAB or split-ABI direct-install artifacts. | **Open release/performance issue.** Add AAB and split-ABI jobs plus artifact size budgets. Current universal APK is 66.80 MiB. |
| SF-035 | Dependency debt includes `file_picker` 10.3.10 vs 11.0.2, `flutter_secure_storage` 9.2.4 vs 10.3.1, `go_router` 14.8.1 vs 17.3.0, and discontinued transitive `js 0.6.7`. The build also warns that `file_picker` still applies the Kotlin Gradle plugin. No specific CVE was proven. | **Open maintenance issue.** Upgrade in controlled batches with native plugin, routing, storage migration, and build tests. |
| SF-036 | `STARFORGE_CENTER_SLUG`/`ApiConfig.defaultCenterSlug` was defined but ignored by sign-in. | **Fixed.** Blank center input now falls back to the configured default slug. |
| SF-037 | iOS signing secrets were job-wide, and third-party GitHub actions are still referenced by mutable major-version tags rather than commit SHA. | **Mitigated.** Secrets are scoped to validation/install steps. Pin `actions/checkout` and `subosito/flutter-action` by reviewed commit SHA for stronger supply-chain control. |
| SF-038 | A malformed/unsafe saved tenant connection could be restored from the secure vault without validating base/WebSocket URLs. | **Fixed.** `TenantConnection.fromJson` validates transport and restore removes rejected vault entries. |
| SF-039 | Assistant root routing did not honor the `viewCohorts` capability before opening the cohort workspace. | **Fixed.** Assistants without that capability are sent to the services hub. |
| SF-040 | Several server-backed lists request a fixed first page of up to 100 entries without complete load-more behavior, notably messaging directory paths. | **Open scalability defect.** Implement cursor/page iteration or UI pagination and test datasets above 100 records. |
| SF-046 | Missing/malformed WebSocket configuration entered a permanent retry loop, while default reconnect delays used uncancellable `Future.delayed` work that survived pause/disposal. | Unnecessary wakeups/network work, leaked lifecycle timers, and test/runtime shutdown failures. | **Fixed.** Configuration errors now enter a terminal paused state until explicit resume; normal default reconnects use a stored cancellable timer; password-rotation and realtime lifecycle tests cover the behavior. |

### Low and maintenance findings

| ID | Finding | Status |
| --- | --- | --- |
| SF-041 | Coach-mark settings are largely unused and some haptic calls bypass the user preference. | **Open UX consistency issue.** Centralize haptics behind the setting and either implement or remove the coach-mark control. |
| SF-042 | Settings displayed a false `2.0 Experience Preview` label while the package version is `1.2.0+4`; repository docs also presented demo credentials and local fake stores too close to production truth. | **Fixed.** The false footer was removed and README/product-spec boundaries were rewritten. Package metadata can be added later if a visible version is desired. |
| SF-043 | Large demo-only screens/stores remain compiled beside production code, increasing dead-design surface and making accidental production routing easier. | **Open maintenance debt.** Continue extracting demo/catalog code behind explicit adapters or a separate flavor/package. |
| SF-044 | Route tests named fake local reception/audit states “production,” reinforcing the wrong mental model. | **Mitigated.** The misleading tests are now labeled demo. Dedicated production-router integration assertions for the replacement backend surfaces still need to be added. |

## Security review in detail

### Session and role boundary

Authentication and staff-app authorization are different decisions. The API may issue a token for an account that is valid for another StarForge product, while this app must accept only staff roles. Previously the app performed the second check after the API had already persisted the token, then threw an error without erasing it. Both fresh login and restore now funnel `staff_app_only` through an awaited sign-out/clear path. Regression tests assert token removal and revoke behavior for an excluded manager account.

This preserves the literal product boundary: this application is for teacher, assistant, methodist, reception, and auditor roles only. It does not add CEO/manager, parent, or student views.

### Local data at rest

The old production caches were not an acceptable offline strategy:

- SharedPreferences is not an encrypted message database.
- Message bodies, attachment keys, staff phone numbers, and profiles were serialized together.
- A user-only key was not sufficient tenant isolation.
- Logout cleared memory but not the stored value.
- Android backup was allowed by default.

Production now persists only messaging organization metadata and settings. The sensitive-content exposure is removed, but the remaining metadata still needs explicit pruning/TTL/size limits. Android backup is disabled, main release traffic is cleartext-disabled, and the debug manifest explicitly re-enables local cleartext development. This is a safer default, but it intentionally means the app is not a full offline messaging/task client. If offline content becomes a product requirement, it needs an encrypted database, record-level retention policy, tenant/user key derivation, logout purge, backup exclusion, schema migration, and conflict reconciliation.

### Transport and media

One transport policy now guards API base URLs, WebSockets, saved/discovered tenant connections, upload grants, and signed downloads:

- remote: HTTPS/WSS only;
- local development: `localhost`, loopback IPv4, or loopback IPv6 may use HTTP/WS;
- URL user-info is rejected;
- redirects are not followed for attachment upload;
- invalid stored connections are removed rather than retried with credentials.

The 25 MiB attachment limit prevents unbounded allocation, but the client still reads an allowed file into memory. Streaming from `XFile.path` into the request and server-coordinated video compression are the correct next steps.

### Remaining security/release risk

The largest remaining device-distribution risk is Android signing. The build script currently selects debug signing in release mode when no keystore variables exist. The audit deliberately did not change this silently because a correct solution requires a release-channel decision:

1. `prodRelease`: fail if any signing input is missing;
2. `qaRelease`: explicitly debug/test signed, differently identified, never uploaded to Play;
3. CI: verify the expected production certificate digest before publishing.

The iOS workflow now scopes signing secrets more narrowly, but action tags should be pinned to reviewed commit SHAs.

## Functional truth by staff role

| Role | Production source of truth now | Known remaining gap |
| --- | --- | --- |
| Teacher | Server groups/students, tasks, assignments, forms, messaging, recognition through server student context | Background push, durable local task overlays, transactional assignment actions |
| Assistant | Capability-gated cohorts or real staff services | Some features depend on center-granted capabilities and backend coverage |
| Methodist | Real Staff Operations and immutable audit/operational data | No dedicated server quality-signal contract; hard-coded quality dashboard removed |
| Reception | Real Staff Operations | No complete authoritative desk/walk-in CRUD contract; demo reception store is no longer presented as production |
| Auditor | Backend immutable audit log | No authoritative server anomaly/case-management contract in this client; local case store is demo-only |

### Dead or misleading designs corrected

- Production methodist quality no longer fabricates named staff alerts or a 92% score.
- Production reception no longer modifies a process-global demo store containing fake PII.
- Production audit no longer claims local anomaly/case mutations are server operations.
- Production legacy `/lesson`, `/student`, `/cards`, and `/search` routes no longer open disconnected demo screens.
- The Today refresh now refreshes real data.
- The Call prototype and unsupported production profile controls are hidden/disabled.
- Settings no longer calls the shipped app an “Experience Preview.”

The routing changes are intentionally conservative. Where no backend contract exists, an honest guide or real operations/audit surface is safer than retaining attractive but false controls.

## Reliability and concurrency review

### Fixed races

Notification optimistic rollback now uses immutable IDs and operation timestamps, and REST refresh merges realtime arrivals instead of overwriting them. Message loads use per-thread request versions so an older response cannot replace a newer one. App persistence is serialized so a slow older write cannot overwrite a newer snapshot. The serializer tracks all pending writes and reports persistence state accurately.

Remote operations now carry session generations and captured user/token identity. A stale 401, send failure, profile/task/form response, logout, password rotation, or cache cleanup from session A cannot clear or overwrite a newer session B. Messaging is initialized centrally for every accepted session; tenant cleanup is scope-specific; password rotation pauses realtime before token replacement; and WebSocket reconnect timers are canceled on pause/disposal. Missing or malformed WebSocket configuration now pauses for an explicit retry instead of creating a permanent retry loop.

During verification, the first serializer implementation uncovered a test/runtime scheduling defect: even an idle write was attached with `Future.then`, and widget tests awaiting settings/logout under Flutter `FakeAsync` could deadlock. The failing full-suite run was not ignored. It was narrowed to English navigation logout and messaging locale update, reproduced in isolation, and fixed by starting idle writes directly while chaining only genuinely overlapping writes. The full suite then passed cleanly.

### Still open

- Notification preference updates can still race if several switches are toggled quickly and responses complete out of order. Serialize/coalesce preference writes.
- Task mutations need per-item in-flight guards, idempotency, rollback, and visible error states.
- Assignment create/publish and grade/return need transaction or compensation semantics.
- Pagination needs to be completed across every production list, not only Staff Operations.
- Reachability should not replace the entire authenticated UI because one health endpoint is unavailable.

## Performance review

### Fixed or reduced

- Production no longer serializes whole message histories on every local organization change.
- Attachment size is bounded before full read and again at the controller boundary.
- Invalid remote media endpoints fail before network work begins.
- Missing WebSocket configuration no longer creates an endless reconnect loop, and default reconnect timers are physically cancellable.
- The privacy overlay is a simple full-screen layer, not a second application tree.

### Still open and measurable

1. **App-wide rebuild fan-out:** `app/lib/main.dart:101` listens to the complete `AppState`, which also forwards backend controller notifications. Profile with Flutter DevTools while receiving messages and move to narrower notifiers/selectors.
2. **Reachability traffic:** `app/lib/features/connectivity/backend_reachability.dart:102` defaults to 15-second online polling and five-second offline polling. An eight-hour foreground shift can generate roughly 1,920 online health requests or 5,760 offline retries before considering other API traffic.
3. **Startup demo allocation:** production should not seed and then discard local demo domain graphs.
4. **Large artifact:** the current universal release-mode APK is 66.80 MiB. Use AAB for Play and split APKs for direct distribution, then establish per-ABI and download-size budgets.
5. **Unbounded overlay metadata:** production no longer caches content, but thread preferences, reactions, folders, and hidden-thread IDs still need pruning/TTL/count and byte-size budgets.
6. **Large source surfaces:** production and demo branches coexist in several very large files, increasing rebuild and maintenance cost even when tree shaking removes some code.

## Native and release audit

### iOS

Fixed in repository configuration:

- standard Flutter CocoaPods `Podfile`;
- iOS 13 platform target;
- Runner and RunnerTests pod installation;
- Flutter post-install build settings;
- Pods xcconfig includes;
- GitHub macOS 26 runner and Xcode 26+ guard;
- Codemagic Xcode 26.4;
- signing secrets limited to the steps that require them.

Still required before calling iOS release-ready:

1. Run `flutter pub get`, `pod install`, and an Xcode build on macOS.
2. Exercise the GitHub/Codemagic workflow with real certificate/profile secrets.
3. Verify bundle ID, team ID, entitlements, embedded provisioning profile, and `codesign --verify` output.
4. Pin third-party actions to reviewed commit SHAs.

### Android

Fixed:

- backups disabled;
- release cleartext disabled;
- debug loopback cleartext override explicit;
- native config regression tests added.

Still required:

- fail-closed production signing and separate QA identity;
- AAB/split artifacts;
- expected signer digest verification in CI;
- background-notification permission/service integration;
- controlled plugin upgrades, especially the Kotlin-plugin warning from `file_picker`.

## Dependency review

`flutter pub outdated` showed upgrade debt but did not prove a vulnerability:

| Package | Current/locked | Newer observed | Note |
| --- | --- | --- | --- |
| `file_picker` | 10.3.10 | 11.0.2 | Upgrade needs native picker regression tests; current build emits a Kotlin plugin migration warning. |
| `flutter_secure_storage` | 9.2.4 | 10.3.1 | Treat as a storage migration and verify existing token accessibility/purge. |
| `go_router` | 14.8.1 | 17.3.0 | Major routing upgrade; verify every role redirect and deep link. |
| transitive `js` | 0.6.7 | discontinued | Identify owning dependency during the upgrade batch. |

No package should be labelled vulnerable without a package advisory/CVE audit tied to the resolved dependency graph.

## Changes made in this pass

### Security and privacy

- Added centralized transport validation in `app/lib/data/api/transport_security.dart`.
- Validated discovered, direct, and restored tenant connections before credentials or tokens are used.
- Wired the default center slug.
- Revoked/cleared excluded-role tokens on login and restore rejection.
- Replaced production message-content persistence with tenant/user-scoped metadata-only persistence.
- Added awaited logout/session-expiry cache purge and legacy cache deletion.
- Removed production domain objects from the plaintext app snapshot.
- Disabled Android backups and release cleartext; retained explicit debug loopback development.
- Added bounded attachment validation, HTTPS media policy, redirect refusal, and timeouts.
- Added an app-switcher privacy shield.

### Correctness and product truth

- Repaired notification rollback races.
- Added session-generation guards across authentication, API expiry, task/form/profile mutations, messaging, and notifications.
- Added per-thread message request ordering and realtime-safe notification refresh merging.
- Made tenant cache cleanup scope-specific and protected newer sessions from stale logout/401 cleanup.
- Made password rotation pause/resume token-aware realtime and removed uncancellable/invalid WebSocket retry loops.
- Serialized app persistence writes and fixed the caught idle-queue deadlock.
- Removed invented methodist quality data.
- Routed production methodist/reception/auditor users to authoritative backend surfaces.
- Capability-gated the assistant cohort root.
- Blocked legacy production lesson/student/cards/search demo routes with truthful guidance.
- Made Today refresh reload tasks and messaging.
- Disabled unsupported production profile fields and corrected save confirmation.
- Narrowed idempotent survey conflict handling to `already_submitted`.
- Hid the fake Call action in production.
- Corrected settings and documentation claims.

### Platform and delivery

- Added the iOS Podfile and Pods xcconfig integration.
- Updated GitHub/Codemagic to Xcode 26-era configuration.
- Scoped iOS signing secrets to necessary workflow steps.
- Added native configuration tests.

## Verification evidence

All commands below were run after the final fixes:

| Check | Result |
| --- | --- |
| `flutter analyze --no-pub` | **PASS** — no issues |
| Targeted API/session/messaging/notification/persistence tests | **PASS** — 45 tests |
| Realtime/password-rotation lifecycle regressions | **PASS** — 10 tests |
| Native platform configuration tests | **PASS** — 3 tests |
| English navigation isolated regression | **PASS** — 1 test after persistence deadlock fix |
| Messaging screen isolated regression | **PASS** — 5 tests after persistence deadlock fix |
| Full `flutter test --reporter compact` | **PASS** — **303 tests**, 49.9 seconds wall time |
| `flutter build apk --release` | **PASS** — release-mode universal APK, 66.80 MiB |
| `git diff --check` | **PASS** |

Built artifact:

- Path: `app/build/app/outputs/flutter-apk/app-release.apk`
- Size: `70,048,848` bytes (`66.80 MiB`)
- SHA-256: `4195CA4314224AF031F4EC8CD27B607745BADA981F26D318801AB94AF7FD5023`
- Signer: `C=US, O=Android, CN=Android Debug`
- Signer SHA-256: `f4c3aa4c00b96de960668b50185cfa2f6a480ccc7a6aa1799edcae105a724067`

**Important:** this APK is suitable only as a QA/install artifact under the existing debug-signing fallback. It is not a Play production artifact and must not be represented as one.

## Prioritized remaining backlog

### P0 — release and reliable alerts

1. Split Android QA and production identities; fail production builds without a real keystore and verify certificate digest in CI.
2. Run and repair the iOS CocoaPods/Xcode build on macOS with real signing, then execute IPA verification end to end.
3. Implement FCM/APNs device registration, permissions, background handling, local presentation, and notification deep links.

### P1 — prevent lost or false work

4. Decide and implement the durable production task-overlay data contract.
5. Make task mutations awaited, idempotent, rollback-safe, and visibly failed per item.
6. Replace assignment multi-step writes with transactional endpoints or explicit reconciliation/compensation.
7. Make survey submission state authoritative after refresh.
8. Serialize/coalesce notification preference writes.
9. Finish pagination/load-more for every backend list and test above 100 entries.

### P1 — complete missing staff workflows

10. Define backend contracts for methodist quality signals and reception desk workflows before restoring dedicated production UI.
11. Define an authoritative audit anomaly/case-management API if auditors must mutate cases; keep immutable audit log as the current truth.
12. Build real federated production search or remove the route entirely.
13. Decide whether recognition needs a dedicated cards inbox in addition to group/student recognition.

### P2 — performance and maintainability

14. Split AppState/controller notifications so messaging events do not rebuild the whole application shell.
15. Replace fixed health polling with lifecycle/connectivity signals and exponential backoff; keep authenticated cached UI usable offline.
16. Stream/compress media from disk instead of buffering even the allowed 25 MiB.
17. Add TTL/pruning/count and byte-size caps to production messaging overlay metadata.
18. Move production bootstrap off demo seed construction.
19. Migrate localization to generated complete catalogs, especially Russian.
20. Add production-backed goldens to CI, including replacement production router surfaces.
21. Produce AAB/split-ABI artifacts with size budgets.
22. Upgrade dependencies in controlled batches and remove the Kotlin plugin warning.
23. Separate demo/catalog code from production adapters to reduce accidental dead routing.

## Release recommendation

The current tree is materially safer and more truthful than the audited baseline, and its analyzer, 303-test suite, and Android release-mode compilation pass. It is appropriate for continued QA.

It is **not yet production-store ready** because Android is debug-signed, iOS has not been built on macOS after restoring CocoaPods integration, background notifications are absent, and several user-visible workflows require backend contracts or reliability work. Those limitations should remain explicit until their P0/P1 items are completed and verified against a live center.
