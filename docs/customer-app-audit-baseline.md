# Customer App Forensic Audit — Baseline

## Scope

This baseline covers the customer mobile application only. Admin, landing, and backend/RLS packages remain out of scope until the customer package reaches a formal GO gate.

## Repository and execution environment

The repository is a Flutter/Dart greenfield project with Demo-First and Repository Abstraction boundaries. The customer app is under `apps/mobile_flutter`, with shared Dart contracts in `packages/contracts_dart`, data implementations in `packages/data_dart`, and design tokens in `packages/design_system/dart`.

Flutter is installed on the connected Windows computer (`Flutter 3.44.8`, Dart `3.12.2`). No Android device or emulator was attached at the first trace (`adb devices -l` returned an empty device list). The local Arabic working directory was initially empty from the remote shell, so a clean clone was placed on the connected computer and a second ASCII-path clone was used for Flutter diagnostics.

## Baseline findings

| Area | Baseline result | Evidence | Gate status |
|---|---|---|---|
| Repository presence | GitHub repository cloned successfully | `anasdesign7824-tech/suq_aleasal`, branch `main` | PASS |
| Customer app exists | Minimal Flutter scaffold exists | `apps/mobile_flutter` | PARTIAL |
| Guest discovery | Home is reachable without authentication | `AssalApp` opens `AssalHomeShell` directly | PARTIAL |
| Customer navigation | Only Home/Profile shell and Product Detail are wired | `assal_app.dart`, `home_screen.dart` | FAIL |
| Auth/session | No auth/session contract or screens | repository/domain inspection | FAIL |
| Categories | No customer categories screen/route | repository/domain inspection | FAIL |
| Search and filters | Search is a single name substring query; no filter model/UI | `AssalProductQuery` | FAIL |
| Product detail | Minimal text detail; no gallery, store, metadata, social, request flow | `product_detail_screen.dart` | FAIL |
| Store profile | No customer store profile screen | repository/domain/UI inspection | FAIL |
| Social actions | No follow/favorite/like/comment/write contracts | `AssalRepository` | FAIL |
| Requests | Read-only request listing exists in contract; no customer request journey | `AssalRepository`, mobile UI | FAIL |
| Messaging/handoff | No customer conversation/handoff contract or UI | repository/domain inspection | FAIL |
| Profile/settings/notifications | Profile placeholders only; notifications are read-only contract data | `assal_app.dart`, `AssalRepository` | FAIL |
| Demo persistence | Demo repository is read-only and has no mutation state | `demo_repository.dart` | FAIL |
| Design tokens | Token file exists, but several Dart files omit required Flutter imports | `assal_tokens.dart`, `assal_widgets.dart`, feature files | FAIL |
| Static analysis | `flutter analyze --no-pub` reports 265 issues | Flutter 3.44.8 on ASCII-path clone | FAIL |
| Build/runtime | Not yet proven; no emulator/device available at trace time | `adb devices -l` empty | BLOCKED |

## Immediate blockers

1. The current customer app is a narrow read-only demo scaffold, not a complete customer experience.
2. The repository contract lacks authentication/session, search filters, store detail, social mutations, comments, messaging, handoff, profile, settings, and customer request submission semantics.
3. The current Flutter source has compile/analyzer failures, including missing Flutter imports and undefined design-token symbols.
4. The connected computer has Flutter and Android SDK tools, but no attached emulator/device was visible during the first runtime probe.
5. The Arabic path causes a Flutter tooling `FormatException` in diagnostics; an ASCII-path working clone is required for reliable local Flutter commands.

## Reconstruction direction

The rebuild must preserve Demo-First and Repository Abstraction. The customer app will be implemented as a complete offline-capable demo journey, with explicit loading/empty/error states and a production-ready repository interface. Demo mutations will be held in an application session store so Follow, Favorite, Like, Review, Comment, Request, Messaging, Handoff, Notifications, and merchant conversion can be exercised without Supabase. Production adapters remain behind the repository boundary and will not be accessed directly by widgets.

## Acceptance rule

This baseline is not a customer-app acceptance report. The final report must mark every audit row from the user directive as PASS/FAIL and must remain NO-GO until build, emulator runtime, navigation, guest/auth behavior, demo flows, tests, RTL, visual identity, and repository boundaries are all verified.
