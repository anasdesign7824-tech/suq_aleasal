# UI Gap Register — عسلكم (Phase 0)

> كل فجوة تمنع بناء UI صحيحًا أو تعرض واجهة ببيانات مخترعة. الحالات: `OPEN`, `IN_PROGRESS`, `BLOCKED`, `RESOLVED`. لا حل بفيك بيانات.

| ID | Issue | Impact | Severity | Affected | Root cause | Recommended UI | Backend needed | Status |
|---|---|---|---|---|---|---|---|---|
| GAP-001 | Old shell uses 5-page `IndexedStack` | Following/Notifications/Requests not independent | Medium | app shell | current navigation | rebuild shell + route registry | no | OPEN |
| GAP-002 | Multiple screens use raw `MaterialPageRoute` | no typed deep links | Medium | all | registry unused | migrate to `AssalRoutes` | no | OPEN |
| GAP-003 | No user-following relation | Following People impossible | Medium | profile/following | repository lacks | show stores only; `UI_DATA_GAP` DG-01 | yes | BLOCKED |
| GAP-004 | No full Order contract | can't build cart/checkout | High | requests/CTA | only request entity | keep request/contact only | yes | BLOCKED |
| GAP-005 | Notification payload not typed | notifications no destination | High | notifications | payload map | read-only + mark read if no destination | yes | OPEN |
| GAP-006 | Conversation context minimal | no product/request context | Medium | messages | store-only contract | show store context; empty state for missing | yes | OPEN |
| GAP-007 | State renderer covers limited states | inconsistent partial/offline/forbidden | High | all | load-state limited | expand `EntityStateView` | partial | OPEN |
| GAP-008 | Profile email/phone no visibility policy | privacy risk | High | profile | no policy | own data only, document gap | yes | OPEN |
| GAP-009 | Profile location free text | inconsistent with reference | Medium | profile editor | dialog text field | canonical location selector when supported | yes | OPEN |
| GAP-010 | Product editor uses comma strings for reference lists | wrong taxonomy UX | High | product wizard | old form | chips/selectors from JSON | no | OPEN |
| GAP-011 | Admin entity presentation not aligned | incompatible visual semantics | Medium | admin | separate consoles | typed adapters + canonical renderers | partial | OPEN |
| GAP-012 | Landing web has no executable UI | no public path | Low | landing | only README | build in later phase | no | OPEN |
| GAP-013 | Storage public/private policy not enforced by UI | private doc exposure risk | High | media/verification | paths untype | media service guard, private docs never public | yes | BLOCKED |
| GAP-014 | Social login providers not verified in UI | cannot claim ready | Medium | auth | config gap | show only if supported | yes | BLOCKED |
| GAP-015 | Settings toggle not persistent | session-only | Low | settings | no repo op | local-only + report | yes | OPEN |
| GAP-016 | Product fields lost in create/update | data loss risk | High | product wizard | `AssalProductDraft` narrow | mapping audit, don't drop unknown fields | yes/partial | OPEN |
| GAP-017 | Request detail / status timeline absent in UI | no ordering clarity | High | requests | only list | build from `AssalRequestSummary` fields | no | OPEN |
| GAP-018 | Analytics only counters | misleading metrics | Medium | merchant/admin | no aggregates | show available counters only | yes | OPEN |
| GAP-019 | Permission reason not uniform | unclear disabled states | Medium | all | API result only | capability matrix + clear disabled message | no | OPEN |
| GAP-020 | No automated visual/evidence tooling | acceptance hard | Medium | governance | gaps in tooling | maintain evidence per task | no | OPEN |
| GAP-021 | Flutter/Dart SDK absent in environment | cannot run analyze/test/build | High | all Flutter | no SDK | static review; mark Flutter checks block until SDK | no | BLOCKED |
| GAP-022 | Home too dense / duplicate rails | poor hierarchy | High | home | old UI | new discovery-first layout | no | OPEN |
| GAP-023 | Old shell uses dark gradient chrome | visual noise vs brand | Medium | app shell | old design | new light shell | no | OPEN |
| GAP-024 | Entity cards duplicated (`ListTile` in multiple places) | canonical entity not consistent | Medium | all | old code | use canonical renderers | no | OPEN |
