---
stepsCompleted: ['step-01-validate-prerequisites', 'step-02-design-epics']
inputDocuments:
  - planning-artifacts/prd.md
  - planning-artifacts/architecture.md
  - planning-artifacts/ux-design-specification.md
workflowType: 'epics-and-stories'
project_name: 'TKD Brackets'
user_name: 'Asak'
date: '2026-01-31'
developmentStrategy: 'Logic-First, UI-Last'
testingScope: 'Unit Tests Only'
packagesVerified: true
---

# TKD Brackets - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for TKD Brackets, decomposing the requirements from the PRD, UX Design, and Architecture into implementable stories.

**Development Strategy:** Logic-First, UI-Last — all UI code writing will be the final task during Flutter web app development.

---

## Requirements Inventory

### Functional Requirements

**1. Tournament Management (FR1-FR5)**
- FR1: Organizer can create a new tournament with name, date, and description
- FR2: Organizer can configure tournament-level settings (federation type, venue, rings)
- FR3: Organizer can duplicate an existing tournament as a template
- FR4: Organizer can archive completed tournaments
- FR5: Organizer can delete a tournament and all associated data

**2. Division Management (FR6-FR12)**
- FR6: Organizer can create divisions using the Smart Division Builder (age/belt/weight/gender axes)
- FR7: Organizer can apply pre-built federation templates (WT, ITF, ATA)
- FR8: Organizer can create fully custom divisions with arbitrary criteria
- FR9: Organizer can merge two small divisions into one
- FR10: Organizer can split a large division into pool A/B
- FR11: Organizer can assign divisions to competition rings
- FR12: System detects scheduling conflicts when same athlete is in overlapping divisions

**3. Participant Management (FR13-FR19)**
- FR13: Organizer can add participants manually with name, dojang, age, belt, weight
- FR14: Organizer can import participants via CSV upload
- FR15: Organizer can paste participant data from spreadsheet
- FR16: System auto-assigns participants to appropriate divisions based on criteria
- FR17: Organizer can move a participant between divisions
- FR18: Organizer can remove a participant from a bracket (no-show handling)
- FR19: Organizer can mark a participant as DQ (medical or conduct)

**4. Bracket Generation (FR20-FR31)**
- FR20: System can generate single elimination brackets
- FR21: System can generate double elimination brackets
- FR22: System can generate round robin brackets
- FR23: System can generate pool play → elimination hybrid brackets
- FR24: System can generate consolation/bronze match brackets
- FR25: System applies dojang separation seeding automatically
- FR26: System applies regional separation seeding when configured
- FR27: System applies random seeding with cryptographic fairness
- FR28: Organizer can import ranked seeding from federation data
- FR29: Organizer can manually override seed positions with drag-and-drop
- FR30: System optimizes bye placement for fairness
- FR31: Organizer can regenerate a bracket after participant changes

**5. Scoring & Match Management (FR32-FR39)**
- FR32: Scorer can enter match results (winner + scores)
- FR33: Scorer can enter federation-specific scoring details (WT/ITF/ATA)
- FR34: Scorer can enter multiple judge scores for forms events
- FR35: System calculates forms rankings using configured method (average, drop high/low)
- FR36: System advances winner to next round automatically
- FR37: Scorer can undo/redo score entries
- FR38: System maintains complete score audit trail
- FR39: System highlights current/next match in each bracket

**6. Multi-Ring Operations (FR40-FR44)**
- FR40: Organizer can view all rings/divisions on a dashboard
- FR41: Multiple scorers can update different rings simultaneously
- FR42: System resolves conflicts when multiple users edit same data
- FR43: Organizer can view venue display mode (full-screen for projector)
- FR44: Venue display auto-refreshes when scores update

**7. Export & Sharing (FR45-FR50)**
- FR45: Organizer can export brackets as PDF (print-ready)
- FR46: Organizer can export brackets as PNG images
- FR47: Organizer can export tournament data as CSV/JSON
- FR48: Organizer can generate shareable public links to brackets
- FR49: Spectator can view public brackets on mobile-friendly view
- FR50: Spectator can refresh bracket view to see latest scores

**8. Authentication & Accounts (FR51-FR58)**
- FR51: User can sign up with email OTP/magic link (Supabase Auth)
- FR52: User can sign in with email OTP/magic link
- FR53: User can create an organization account
- FR54: Owner can invite users to organization with assigned role
- FR55: Invited user can accept invitation and join organization
- FR56: System enforces RBAC permissions (Owner, Admin, Scorer, Viewer)
- FR57: Owner can change user roles within organization
- FR58: Owner can remove users from organization

**9. Billing & Subscription (FR59-FR64)**
- FR59: User can view current subscription tier and usage
- FR60: User can upgrade from Free to Enterprise tier
- FR61: System enforces Free tier limits (3 brackets, 32 participants/bracket, 2 tournaments/month, 2 scorers)
- FR62: Enterprise user has unlimited brackets, participants, tournaments
- FR63: Enterprise user can upload custom organization logo
- FR64: System integrates with Stripe for payment processing

**10. Offline & Reliability (FR65-FR69)**
- FR65: System saves data every 5 seconds (autosave)
- FR66: System works offline with full functionality
- FR67: System syncs data when connection restored
- FR68: System shows sync status indicator
- FR69: System resolves multi-user edit conflicts using last-write-wins with visual notification

**11. Integrations (FR70-FR75)**
- FR70: Organizer can import participant data from Kicksite
- FR71: Organizer can import participant data from Zen Planner
- FR72: Organizer can import participant data from Ember
- FR73: Organizer can sync ranking points with federation APIs (WT, ITF, ATA)
- FR74: System can send webhook notifications on bracket events
- FR75: System integrates with Zapier for automation

**12. Analytics & Reporting (FR76-FR78)**
- FR76: Organizer can view tournament analytics dashboard
- FR77: System tracks athlete performance history across tournaments
- FR78: Organizer can generate post-event reports

---

### Non-Functional Requirements

**Performance**
- NFR1: Page load time < 2 seconds
- NFR2: Bracket generation < 500ms
- NFR3: Score submission response < 200ms
- NFR4: PDF export < 3 seconds
- NFR5: Search/filter results < 100ms
- NFR6: Support 50+ concurrent users per tournament

**Reliability**
- NFR7: 99.9% uptime target
- NFR8: Zero data loss tolerance
- NFR9: Autosave frequency every 5 seconds
- NFR10: Full offline mode functionality
- NFR11: Recovery time < 1 minute after any issue

**Security**
- NFR12: Supabase Auth with email OTP/magic link
- NFR13: Data encryption at rest and in transit (TLS 1.3)
- NFR14: Automatic session timeout after inactivity
- NFR15: Server-side RBAC enforcement (roles cannot be bypassed)
- NFR16: No payment data stored locally (Stripe handles all payment data)
- NFR17: GDPR compliance (data export, deletion rights)
- NFR18: COPPA compliance (no child accounts, organizer-entered data only)

**Scalability**
- NFR19: Initial capacity: 100 concurrent tournaments
- NFR20: Growth target: 10x scaling without re-architecture
- NFR21: Supabase managed Postgres for auto-scaling
- NFR22: Weekend tournament peak handling

**Accessibility**
- NFR23: Full keyboard navigation support
- NFR24: Basic ARIA labels for screen readers
- NFR25: WCAG 2.1 AA color contrast minimum
- NFR26: Visible focus indicators
- NFR27: Support up to 200% text zoom

**Browser Support**
- NFR28: Chrome (latest 2 versions) - Full support
- NFR29: Firefox (latest 2 versions) - Full support
- NFR30: Safari (latest 2 versions) - Full support
- NFR31: Edge (latest 2 versions) - Full support
- NFR32: Mobile browsers - View-only mode

**Integration**
- NFR33: Webhook delivery 99%+ reliability
- NFR34: Rate limiting for API protection
- NFR35: Graceful timeout handling for external APIs
- NFR36: Strict input validation for imports

---

### Additional Requirements

**From Architecture Document:**

1. **Starter Template**: Custom scaffold using `flutter create` with Clean Architecture structure — impacts Epic 1 Story 1
2. **Technology Stack**: 
   - DI: `injectable` + `get_it`
   - Navigation: `go_router` + `go_router_builder`
   - State: `flutter_bloc`
   - Local DB: `drift`
   - Error Handling: `fpdart` with Either<Failure, T> pattern
3. **Multi-Tenancy Model**: Shared database with tenant ID column + RLS with JWT custom claims
4. **Sync Strategy**: Last-Write-Wins with notification for offline sync
5. **Demo Mode**: Local-only Drift database (1 tournament, 1 division, 8 participants limit)
6. **Demo Migration**: UUID remapping + conflict resolution when user signs up
7. **Supabase Realtime**: Minimal usage — scoring/matches only (not tournaments/divisions)
8. **Error Tracking**: Sentry (`sentry_flutter`) free tier integration
9. **PDF Generation**: `pdf` + `printing` packages for export
10. **Database Schema**: 15 tables defined with complete RLS policies
11. **Seeding Algorithm**: Constraint-satisfaction approach with backtracking for dojang separation
12. **Bracket Visualization**: Widget-based rendering with `InteractiveViewer` for zoom/pan
13. **Federation Templates**: Hybrid approach (static in code + custom in database)
14. **Environment Flavors**: main_development, main_staging, main_production

**From UX Specification:**

1. **Pre-Signup Demo Mode**: Interactive demo with sample TKD data before account creation
2. **Keyboard-First Scoring**: Tab/Enter flow, shortcuts for power users
3. **Venue Display Mode**: Full-screen projector mode with auto-refresh
4. **Mobile View-Only**: Separate mobile experience for spectators (no editing)
5. **Progressive Disclosure**: Simple first view, power features revealed gradually
6. **Autosave Indicators**: "Saved just now" visible feedback
7. **Undo Pattern**: Ctrl+Z always works, snackbar with undo option
8. **Toast Notifications**: Optimistic updates with feedback
9. **Design System**: Material Design 3 with custom color palette (Navy/Gold)
10. **Typography**: Inter font family for desktop readability
11. **Animation System**: Smooth bracket generation, winner advancement animations
12. **Command Palette**: Quick actions for power users (simplified, 5-10 common actions)
13. **Smart Division Builder UX**: "Magic" feel — auto-categorization without configuration
14. **PDF Quality**: Professional, print-ready output representing dojang professionalism

**Development Strategy (User-Specified):**

- **Logic-First, UI-Last**: All domain logic, use cases, repositories, and data layers implemented before presentation/UI code
- **Epics should be sequenced**: Foundation → Core Logic → Data Layer → Sync → UI

---

### FR Coverage Map

| FR   | Epic         | Description                        |
| ---- | ------------ | ---------------------------------- |
| FR1  | Epic 3       | Create tournament                  |
| FR2  | Epic 3       | Configure tournament settings      |
| FR3  | Epic 3       | Duplicate tournament as template   |
| FR4  | Epic 3       | Archive tournament                 |
| FR5  | Epic 3       | Delete tournament                  |
| FR6  | Epic 3       | Smart Division Builder             |
| FR7  | Epic 3       | Federation templates (WT/ITF/ATA)  |
| FR8  | Epic 3       | Custom divisions                   |
| FR9  | Epic 3       | Merge divisions                    |
| FR10 | Epic 3       | Split divisions                    |
| FR11 | Epic 3       | Assign divisions to rings          |
| FR12 | Epic 3       | Scheduling conflict detection      |
| FR13 | Epic 4       | Add participants manually          |
| FR14 | Epic 4       | CSV import                         |
| FR15 | Epic 4       | Paste from spreadsheet             |
| FR16 | Epic 4       | Auto-assign to divisions           |
| FR17 | Epic 4       | Move participant between divisions |
| FR18 | Epic 4       | Remove participant (no-show)       |
| FR19 | Epic 4       | DQ participant                     |
| FR20 | Epic 5       | Single elimination brackets        |
| FR21 | Epic 5       | Double elimination brackets        |
| FR22 | Epic 5       | Round robin brackets               |
| FR23 | Epic 5       | Pool play → elimination hybrid     |
| FR24 | Epic 5       | Consolation/bronze matches         |
| FR25 | Epic 5       | Dojang separation seeding          |
| FR26 | Epic 5       | Regional separation seeding        |
| FR27 | Epic 5       | Random seeding (cryptographic)     |
| FR28 | Epic 5       | Ranked seeding import              |
| FR29 | Epic 5       | Manual seed override (drag-drop)   |
| FR30 | Epic 5       | Bye optimization                   |
| FR31 | Epic 5       | Regenerate bracket                 |
| FR32 | Epic 6       | Enter match results                |
| FR33 | Epic 6       | Federation-specific scoring        |
| FR34 | Epic 6       | Multiple judge scores              |
| FR35 | Epic 6       | Forms ranking calculation          |
| FR36 | Epic 6       | Auto-advance winner                |
| FR37 | Epic 6       | Undo/redo score entries            |
| FR38 | Epic 6       | Score audit trail                  |
| FR39 | Epic 6       | Highlight current/next match       |
| FR40 | Epic 6       | Multi-ring dashboard               |
| FR41 | Epic 6       | Concurrent scorer updates          |
| FR42 | Epic 6       | Conflict resolution                |
| FR43 | Epic 6       | Venue display mode                 |
| FR44 | Epic 6       | Venue auto-refresh                 |
| FR45 | Epic 7       | Export PDF                         |
| FR46 | Epic 7       | Export PNG                         |
| FR47 | Epic 7       | Export CSV/JSON                    |
| FR48 | Epic 7       | Public shareable links             |
| FR49 | Epic 7       | Spectator mobile view              |
| FR50 | Epic 7       | Spectator refresh                  |
| FR51 | Epic 2       | Email magic link signup            |
| FR52 | Epic 2       | Email magic link signin            |
| FR53 | Epic 2       | Create organization                |
| FR54 | Epic 2       | Invite users with roles            |
| FR55 | Epic 2       | Accept invitation                  |
| FR56 | Epic 2       | RBAC enforcement                   |
| FR57 | Epic 2       | Change user roles                  |
| FR58 | Epic 2       | Remove users                       |
| FR59 | Epic 8       | View subscription tier             |
| FR60 | Epic 8       | Upgrade subscription               |
| FR61 | Epic 8       | Free tier limits                   |
| FR62 | Epic 8       | Enterprise unlimited               |
| FR63 | Epic 8       | Custom logo upload                 |
| FR64 | Epic 8       | Stripe integration                 |
| FR65 | Epic 1/Cross | Autosave (5 seconds)               |
| FR66 | Epic 1/Cross | Offline mode                       |
| FR67 | Epic 1/Cross | Sync on reconnect                  |
| FR68 | Epic 1/Cross | Sync status indicator              |
| FR69 | Epic 1/Cross | Conflict resolution (LWW)          |
| FR70 | Epic 8       | Kicksite integration               |
| FR71 | Epic 8       | Zen Planner integration            |
| FR72 | Epic 8       | Ember integration                  |
| FR73 | Epic 8       | Federation API sync                |
| FR74 | Epic 8       | Webhook notifications              |
| FR75 | Epic 8       | Zapier integration                 |
| FR76 | Epic 8       | Analytics dashboard                |
| FR77 | Epic 8       | Athlete performance history        |
| FR78 | Epic 8       | Post-event reports                 |

---

## Epic List

### Epic 1: Foundation & Demo Mode
**Goal:** Users can explore the app without creating an account. Demo mode lets them try the product with zero friction.

**User Outcome:** Potential customers can immediately interact with the product, create a sample tournament, and experience the core value proposition before signing up.

**FRs Covered:** FR65-FR69 (cross-cutting: autosave, offline, sync)

**Scope:**
- Project scaffold (Clean Architecture: data/domain/presentation layers)
- Dependency injection setup (get_it + injectable)
- Routing setup (go_router + go_router_builder)
- Drift local database setup with all tables
- Demo mode data seeding (1 tournament, 1 division, 8 sample participants)
- Error handling infrastructure (fpdart Either<Failure, T> pattern)
- Supabase client initialization
- Sentry error tracking integration
- Autosave service (5-second interval)
- Sync service foundation (Last-Write-Wins strategy)
- Connectivity monitoring

**NFRs Addressed:** NFR8 (zero data loss), NFR9 (autosave), NFR10 (offline mode)

**Dependencies:** None — this is the foundation

---

### Epic 2: Authentication & Organization
**Goal:** Users can sign up, create an organization, and invite team members with appropriate roles.

**User Outcome:** Tournament organizers can create their organization account, set up their team with proper permissions (Owner, Admin, Scorer, Viewer), and manage membership.

**FRs Covered:** FR51-FR58 (8 FRs)
| FR   | Capability                    |
| ---- | ----------------------------- |
| FR51 | Sign up with email magic link |
| FR52 | Sign in with email magic link |
| FR53 | Create organization           |
| FR54 | Invite users with roles       |
| FR55 | Accept invitation             |
| FR56 | RBAC enforcement              |
| FR57 | Change user roles             |
| FR58 | Remove users                  |

**Scope:**
- Supabase Auth integration (magic link flow)
- User entity and repository
- Organization entity and repository
- Invitation entity and repository
- RBAC permission service
- Auth state management (AuthBloc)
- Demo-to-production data migration service
- Session management
- Logout flow

**NFRs Addressed:** NFR12 (Supabase Auth), NFR14 (session timeout), NFR15 (server-side RBAC)

**Dependencies:** Epic 1 (Foundation)

---

### Epic 3: Tournament & Division Management
**Goal:** Users can create tournaments, configure divisions using Smart Division Builder, and apply federation templates.

**User Outcome:** Organizers can set up a complete tournament structure with all divisions properly configured for their federation (WT, ITF, ATA), including ring assignments and conflict detection.

**FRs Covered:** FR1-FR12 (12 FRs)
| FR   | Capability                        |
| ---- | --------------------------------- |
| FR1  | Create tournament                 |
| FR2  | Configure tournament settings     |
| FR3  | Duplicate tournament as template  |
| FR4  | Archive tournament                |
| FR5  | Delete tournament                 |
| FR6  | Smart Division Builder            |
| FR7  | Federation templates (WT/ITF/ATA) |
| FR8  | Custom divisions                  |
| FR9  | Merge divisions                   |
| FR10 | Split divisions                   |
| FR11 | Assign divisions to rings         |
| FR12 | Scheduling conflict detection     |

**Scope:**
- Tournament entity and repository
- Division entity and repository
- Federation template registry (static WT/ITF/ATA templates)
- Smart Division Builder algorithm
- Division merge/split logic
- Ring assignment service
- Conflict detection algorithm
- Tournament settings configuration

**NFRs Addressed:** NFR5 (search/filter < 100ms)

**Dependencies:** Epic 2 (Auth & Organization)

---

### Epic 4: Participant Management
**Goal:** Users can add participants manually, import from CSV, and auto-assign them to appropriate divisions.

**User Outcome:** Organizers can quickly populate their tournament with athletes from multiple sources (manual entry, CSV, paste) and have the system intelligently assign them to the correct divisions based on age, belt, weight, and gender.

**FRs Covered:** FR13-FR19 (7 FRs)
| FR   | Capability                         |
| ---- | ---------------------------------- |
| FR13 | Add participants manually          |
| FR14 | CSV import                         |
| FR15 | Paste from spreadsheet             |
| FR16 | Auto-assign to divisions           |
| FR17 | Move participant between divisions |
| FR18 | Remove participant (no-show)       |
| FR19 | DQ participant                     |

**Scope:**
- Participant entity and repository
- CSV parsing service
- Clipboard paste handling
- Auto-assignment algorithm (match participant to division criteria)
- Participant status management (active, no-show, DQ)
- Participant validation (required fields, data types)

**NFRs Addressed:** NFR36 (strict input validation for imports)

**Dependencies:** Epic 3 (Tournament & Division Management)

---

### Epic 5: Bracket Generation & Seeding
**Goal:** Users can generate brackets with intelligent seeding that separates athletes from the same school.

**User Outcome:** Organizers can generate fair, optimized brackets for any format (single/double elimination, round robin, pool play) with the system automatically applying dojang separation to prevent same-school matchups in early rounds.

**FRs Covered:** FR20-FR31 (12 FRs)
| FR   | Capability                       |
| ---- | -------------------------------- |
| FR20 | Single elimination brackets      |
| FR21 | Double elimination brackets      |
| FR22 | Round robin brackets             |
| FR23 | Pool play → elimination hybrid   |
| FR24 | Consolation/bronze matches       |
| FR25 | Dojang separation seeding        |
| FR26 | Regional separation seeding      |
| FR27 | Random seeding (cryptographic)   |
| FR28 | Ranked seeding import            |
| FR29 | Manual seed override (drag-drop) |
| FR30 | Bye optimization                 |
| FR31 | Regenerate bracket               |

**Scope:**
- Bracket entity and repository
- Match entity and repository
- Seeding engine (constraint-satisfaction with backtracking)
- Dojang separation constraint
- Regional separation constraint
- Bye optimization constraint
- Bracket generation algorithms (single/double/round robin/pool)
- Bracket layout engine (position calculation)
- Manual seed override service

**NFRs Addressed:** NFR2 (bracket generation < 500ms)

**Dependencies:** Epic 4 (Participant Management)

---

### Epic 6: Live Scoring & Match Management
**Goal:** Scorers can enter match results in real-time, see winner advance automatically, and undo mistakes.

**User Outcome:** During live tournaments, multiple scorers can simultaneously update different rings with match results. Scores are immediately reflected in the bracket, winners advance automatically, and any mistakes can be quickly undone with full audit trail.

**FRs Covered:** FR32-FR44 (13 FRs)
| FR   | Capability                   |
| ---- | ---------------------------- |
| FR32 | Enter match results          |
| FR33 | Federation-specific scoring  |
| FR34 | Multiple judge scores        |
| FR35 | Forms ranking calculation    |
| FR36 | Auto-advance winner          |
| FR37 | Undo/redo score entries      |
| FR38 | Score audit trail            |
| FR39 | Highlight current/next match |
| FR40 | Multi-ring dashboard         |
| FR41 | Concurrent scorer updates    |
| FR42 | Conflict resolution          |
| FR43 | Venue display mode           |
| FR44 | Venue auto-refresh           |

**Scope:**
- Match score record entity and repository
- Judge score entity and repository
- Scoring service (federation-specific rules)
- Forms ranking calculator (average, drop high/low)
- Winner advancement service
- Undo/redo service with command pattern
- Audit trail service
- Supabase Realtime subscription (matches/scores only)
- Conflict resolution (Last-Write-Wins with notification)
- Venue display mode (full-screen, auto-refresh)
- Keyboard shortcuts for scoring

**NFRs Addressed:** NFR3 (score submission < 200ms), NFR6 (50+ concurrent users)

**Dependencies:** Epic 5 (Bracket Generation)

---

### Epic 7: Export, Sharing & Public View
**Goal:** Users can export brackets as PDFs, share public links, and spectators can view live bracket updates.

**User Outcome:** Organizers can generate professional, print-ready PDFs for ring captains, share public links for parents/spectators to follow along on mobile, and export tournament data for records.

**FRs Covered:** FR45-FR50 (6 FRs)
| FR   | Capability             |
| ---- | ---------------------- |
| FR45 | Export PDF             |
| FR46 | Export PNG             |
| FR47 | Export CSV/JSON        |
| FR48 | Public shareable links |
| FR49 | Spectator mobile view  |
| FR50 | Spectator refresh      |

**Scope:**
- PDF generation service (pdf + printing packages)
- PNG export service
- CSV/JSON export service
- Public link generation (unique token)
- Public bracket viewer (mobile-optimized, view-only)
- Public view auto-refresh

**NFRs Addressed:** NFR4 (PDF export < 3 seconds), NFR32 (mobile browsers view-only)

**Dependencies:** Epic 5/6 (Brackets with scores)

---

### Epic 8: Billing, Integrations & Analytics
**Goal:** Users can upgrade to Enterprise tier, sync with external tools, and view tournament analytics.

**User Outcome:** Organizers can upgrade from Free to Enterprise tier for unlimited usage, connect with their existing dojang management systems (Kicksite, Zen Planner), set up webhooks for automation, and analyze tournament performance.

**FRs Covered:** FR59-FR64, FR70-FR78 (20 FRs)
| FR   | Capability                  |
| ---- | --------------------------- |
| FR59 | View subscription tier      |
| FR60 | Upgrade subscription        |
| FR61 | Free tier limits            |
| FR62 | Enterprise unlimited        |
| FR63 | Custom logo upload          |
| FR64 | Stripe integration          |
| FR70 | Kicksite integration        |
| FR71 | Zen Planner integration     |
| FR72 | Ember integration           |
| FR73 | Federation API sync         |
| FR74 | Webhook notifications       |
| FR75 | Zapier integration          |
| FR76 | Analytics dashboard         |
| FR77 | Athlete performance history |
| FR78 | Post-event reports          |

**Scope:**
- Subscription entity and repository
- Stripe integration (checkout, webhooks)
- Free tier limit enforcement
- Logo upload (Supabase Storage)
- External integration service (Kicksite, Zen Planner, Ember)
- Webhook service
- Analytics aggregation service
- Athlete profile entity and repository
- Report generation service

**NFRs Addressed:** NFR16 (no payment data stored locally), NFR33 (webhook 99% reliability)

**Dependencies:** Epic 2 (Organization for billing)

---

## Epic Summary

| Epic | Title                             | FRs       | Stories (Est.) | Priority |
| ---- | --------------------------------- | --------- | -------------- | -------- |
| 1    | Foundation & Demo Mode            | 5 (cross) | 12-15          | **P0**   |
| 2    | Authentication & Organization     | 8         | 10-12          | **P0**   |
| 3    | Tournament & Division Management  | 12        | 15-18          | **P0**   |
| 4    | Participant Management            | 7         | 10-12          | **P0**   |
| 5    | Bracket Generation & Seeding      | 12        | 15-18          | **P0**   |
| 6    | Live Scoring & Match Management   | 13        | 15-18          | **P0**   |
| 7    | Export, Sharing & Public View     | 6         | 8-10           | **P1**   |
| 8    | Billing, Integrations & Analytics | 20        | 20-25          | **P1**   |
|      | **TOTAL**                         | **78**    | **~100-120**   |          |

---

## Epic Dependency Graph

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  Epic 1: Foundation & Demo Mode                             │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                              │
│                     │                                       │
│                     ▼                                       │
│  Epic 2: Authentication & Organization                      │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                       │
│                     │                                       │
│                     ▼                                       │
│  Epic 3: Tournament & Division Management                   │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                    │
│                     │                                       │
│                     ▼                                       │
│  Epic 4: Participant Management                             │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                             │
│                     │                                       │
│                     ▼                                       │
│  Epic 5: Bracket Generation & Seeding                       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                          │
│                     │                                       │
│        ┌───────────┴───────────┐                           │
│        ▼                       ▼                           │
│  Epic 6: Live Scoring    Epic 7: Export                    │
│  ━━━━━━━━━━━━━━━━━      ━━━━━━━━━━━━                        │
│                                                             │
│  Epic 8: Billing & Integrations (parallel after Epic 2)    │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Note:** Epic 8 can be developed in parallel with Epics 3-7 since it only depends on Epic 2.

---

# Epic Stories

## Epic 1: Foundation & Demo Mode — Stories

### Story 1.1: Project Scaffold & Clean Architecture Setup

**As a** developer,
**I want** a properly structured Flutter project with Clean Architecture layers,
**So that** all future features have a consistent, maintainable structure to build upon.

**Acceptance Criteria:**

**Given** the project needs to be created
**When** I run `flutter create` and configure the project structure
**Then** the following directory structure exists:
```
lib/
├── core/
│   ├── algorithms/
│   ├── constants/
│   ├── error/
│   ├── extensions/
│   ├── routing/
│   └── utils/
├── features/
│   └── (empty, ready for feature folders)
├── app/
│   └── app.dart
└── main_development.dart
```
**And** pubspec.yaml contains all verified dependencies from the package research
**And** analysis_options.yaml includes very_good_analysis rules
**And** the project builds without errors using `flutter build web`

---

### Story 1.2: Dependency Injection Configuration

**As a** developer,
**I want** get_it and injectable configured for dependency injection,
**So that** all services and repositories can be automatically registered and resolved.

**Acceptance Criteria:**

**Given** the project scaffold exists from Story 1.1
**When** I configure injectable with get_it
**Then** `lib/core/di/injection.dart` contains the injection container setup
**And** `lib/core/di/injection.config.dart` is generated by build_runner
**And** `@injectable`, `@lazySingleton`, and `@module` annotations work correctly
**And** environment annotations (`@dev`, `@prod`) are configured
**And** running `dart run build_runner build` succeeds without errors
**And** unit tests verify that registered dependencies can be resolved

---

### Story 1.3: Router Configuration

**As a** developer,
**I want** go_router configured with type-safe routes,
**So that** navigation is declarative, type-safe, and supports deep linking.

**Acceptance Criteria:**

**Given** dependency injection is configured from Story 1.2
**When** I configure go_router with go_router_builder
**Then** `lib/core/routing/app_router.dart` defines the router configuration
**And** `lib/core/routing/routes.dart` contains type-safe route definitions
**And** `.g.dart` files are generated for route builders
**And** the router supports redirect guards for auth protection
**And** shell routes are configured for the main app scaffold
**And** unit tests verify route generation and parameter parsing

---

### Story 1.4: Error Handling Infrastructure

**As a** developer,
**I want** a standardized error handling infrastructure using fpdart,
**So that** all errors are handled consistently with Either<Failure, T> pattern.

**Acceptance Criteria:**

**Given** the project scaffold exists
**When** I implement the error handling infrastructure
**Then** `lib/core/error/failure.dart` contains the Failure base class hierarchy:
  - `ServerFailure` for API errors
  - `CacheFailure` for local DB errors
  - `NetworkFailure` for connectivity issues
  - `ValidationFailure` for input validation errors
  - `AuthFailure` for authentication errors
**And** each Failure has `userFriendlyMessage` and `technicalDetails` properties
**And** `lib/core/error/exceptions.dart` contains corresponding exception types
**And** `lib/core/error/error_reporting_service.dart` provides centralized error reporting
**And** unit tests verify Failure creation and message formatting

---

### Story 1.5: Drift Database Setup & Core Tables

**As a** developer,
**I want** Drift configured with core database tables,
**So that** local data persistence is available for offline-first functionality.

**Acceptance Criteria:**

**Given** the project infrastructure is in place
**When** I configure Drift with core tables
**Then** `lib/core/database/app_database.dart` defines the AppDatabase
**And** common table patterns are implemented:
  - `BaseSyncTable` mixin with `sync_version`, `is_deleted`, `deleted_at_timestamp`, `is_demo_data`
  - `BaseAuditTable` mixin with `created_at_timestamp`, `updated_at_timestamp`
**And** initial tables are created (organizations, users) with proper migrations
**And** `drift_flutter` web support is configured
**And** running `dart run build_runner build` generates `.g.dart` files
**And** unit tests verify table creation and basic CRUD operations

---

### Story 1.6: Supabase Client Initialization

**As a** developer,
**I want** Supabase client properly initialized with environment configuration,
**So that** authentication, database, and realtime features are available.

**Acceptance Criteria:**

**Given** the project has Drift and DI configured
**When** I configure Supabase client
**Then** `lib/core/supabase/supabase_config.dart` contains initialization logic
**And** environment-specific configuration is loaded from build-time variables
**And** `main_development.dart`, `main_staging.dart`, `main_production.dart` entry points exist
**And** Supabase client is registered as a singleton in the DI container
**And** unit tests verify Supabase client initialization (mocked)

---

### Story 1.7: Sentry Error Tracking Integration

**As a** developer,
**I want** Sentry integrated for crash reporting and error tracking,
**So that** production errors are automatically captured and reported.

**Acceptance Criteria:**

**Given** Supabase and error handling are configured
**When** I integrate Sentry
**Then** `lib/core/monitoring/sentry_service.dart` initializes Sentry SDK
**And** `Sentry.captureException` is called from `ErrorReportingService`
**And** `SentryNavigatorObserver` is added to the router for navigation breadcrumbs
**And** environment-specific DSN is loaded from configuration
**And** Sentry is disabled in development builds
**And** unit tests verify error capture calls (mocked)

---

### Story 1.8: Connectivity Monitoring Service

**As a** developer,
**I want** a connectivity monitoring service that detects online/offline status,
**So that** the app can switch between online and offline modes seamlessly.

**Acceptance Criteria:**

**Given** core infrastructure is in place
**When** I implement connectivity monitoring
**Then** `lib/core/network/connectivity_service.dart` provides:
  - `Stream<ConnectivityStatus>` for real-time updates
  - `Future<bool> hasInternetConnection()` for point-in-time checks
**And** `ConnectivityStatus` enum includes `online`, `offline`, `slow`
**And** the service uses `connectivity_plus` and `internet_connection_checker_plus`
**And** unit tests verify status change detection (mocked)

---

### Story 1.9: Autosave Service

**As a** developer,
**I want** an autosave service that persists dirty data every 5 seconds,
**So that** users never lose work even if they forget to save (FR65).

**Acceptance Criteria:**

**Given** Drift database and connectivity service are available
**When** I implement the autosave service
**Then** `lib/core/sync/autosave_service.dart` provides:
  - Periodic saving every 5 seconds
  - Dirty tracking for modified entities
  - Save on app pause/background
**And** only modified data is saved (not full database dump)
**And** autosave respects connectivity status (local save always, cloud when online)
**And** unit tests verify save timing and dirty tracking

---

### Story 1.10: Sync Service Foundation

**As a** developer,
**I want** a sync service using Last-Write-Wins strategy,
**So that** local changes sync to Supabase when online (FR66-FR69).

**Acceptance Criteria:**

**Given** autosave and connectivity services exist
**When** I implement the sync service foundation
**Then** `lib/core/sync/sync_service.dart` provides:
  - `SyncQueue` for pending changes
  - `push()` to upload local changes
  - `pull()` to download remote changes
  - Last-Write-Wins conflict resolution using `sync_version`
**And** `sync_queue` table is created in Drift for pending operations
**And** sync status is exposed via `Stream<SyncStatus>`
**And** `SyncStatus` includes `synced`, `syncing`, `pending_changes`, `error`
**And** unit tests verify queue operations and conflict resolution

---

### Story 1.11: Demo Mode Data Seeding

**As a** potential customer,
**I want** sample TKD tournament data seeded when I first use the app,
**So that** I can explore features without entering my own data.

**Acceptance Criteria:**

**Given** Drift database is configured
**When** the app detects first launch (no existing data)
**Then** demo data is seeded:
  - 1 sample organization ("Demo Dojang")
  - 1 sample tournament ("Spring Championship 2026")
  - 1 sample division ("Cadets -45kg Male")
  - 8 sample participants with varied dojangs
**And** all demo data has `is_demo_data = true`
**And** demo data uses predetermined UUIDs for test reproducibility
**And** unit tests verify seeding creates expected records

---

### Story 1.12: Foundation UI Shell

**As a** user,
**I want** a basic app shell with navigation structure,
**So that** I can navigate between main sections of the app.

**Acceptance Criteria:**

**Given** router and demo data are configured
**When** the app launches
**Then** a responsive shell layout is displayed with:
  - Navigation rail (desktop) / bottom nav (tablet) structure defined
  - Placeholder pages for main sections (Dashboard, Tournaments, Settings)
  - Sync status indicator in the app bar area
**And** the shell respects the Material Design 3 theme configuration
**And** navigation between placeholder pages works correctly
**And** the UI renders without errors in Chrome

---

**Epic 1 Complete: 12 stories created**

---

## Epic 2: Authentication & Organization — Stories

### Story 2.1: Auth Feature Structure & Domain Layer

**As a** developer,
**I want** the authentication feature properly structured with Clean Architecture layers,
**So that** all auth-related code has a consistent, organized structure.

**Acceptance Criteria:**

**Given** the foundation from Epic 1 is complete
**When** I create the auth feature structure
**Then** the following directory structure exists:
```
lib/features/auth/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```
**And** base use case abstract class is defined
**And** the feature is properly registered in the DI container

---

### Story 2.2: User Entity & Repository

**As a** developer,
**I want** the User entity and repository implemented,
**So that** user data can be persisted and retrieved locally and remotely.

**Acceptance Criteria:**

**Given** the auth feature structure exists
**When** I implement the User entity and repository
**Then** `UserEntity` contains: `id`, `email`, `displayName`, `avatarUrl`, `role`, `organizationId`, `createdAt`, `lastLoginAt`
**And** `users` table is created in Drift with proper columns
**And** `UserRepository` interface is defined in domain layer
**And** `UserRepositoryImpl` implements local (Drift) and remote (Supabase) operations
**And** unit tests verify CRUD operations

---

### Story 2.3: Email Magic Link Sign Up

**As a** new user,
**I want** to sign up using email magic link (OTP),
**So that** I can create an account without remembering a password (FR51).

**Acceptance Criteria:**

**Given** the user is not authenticated
**When** they enter their email and request magic link
**Then** `SignUpWithEmailUseCase` sends magic link via Supabase Auth
**And** `SupabaseAuthDataSource` handles the `signInWithOtp()` call
**And** error cases are handled (invalid email, rate limit, network error)
**And** `Either<Failure, Unit>` is returned for success/failure
**And** unit tests verify magic link request flow (mocked Supabase)

---

### Story 2.4: Email Magic Link Sign In

**As a** returning user,
**I want** to sign in using email magic link,
**So that** I can access my account securely (FR52).

**Acceptance Criteria:**

**Given** the user has an existing account
**When** they enter their email and click the magic link
**Then** `SignInWithEmailUseCase` verifies the OTP via Supabase Auth
**And** user session is established and persisted
**And** user profile is fetched from Supabase and cached locally
**And** error cases handled (expired link, invalid token, network error)
**And** unit tests verify sign-in flow (mocked Supabase)

---

### Story 2.5: Auth State Management (AuthBloc)

**As a** developer,
**I want** authentication state managed via BLoC,
**So that** the UI can react to auth state changes consistently.

**Acceptance Criteria:**

**Given** auth use cases are implemented
**When** I implement AuthBloc
**Then** `AuthBloc` handles events: `AuthCheckRequested`, `AuthSignUpRequested`, `AuthSignInRequested`, `AuthLogoutRequested`
**And** `AuthState` includes: `initial`, `loading`, `authenticated(user)`, `unauthenticated`, `error(failure)`
**And** auth state persists across app restarts (session recovery)
**And** logout clears local session but preserves demo data
**And** unit tests verify state transitions

---

### Story 2.6: Organization Entity & Repository

**As a** developer,
**I want** the Organization entity and repository implemented,
**So that** organization data can be managed for multi-tenancy.

**Acceptance Criteria:**

**Given** User entity exists
**When** I implement Organization entity and repository
**Then** `OrganizationEntity` contains: `id`, `name`, `slug`, `logoUrl`, `subscriptionTier`, `ownerId`, `createdAt`
**And** `organizations` table is created in Drift
**And** `OrganizationRepository` handles local and remote operations
**And** organization is linked to users via `organization_id`
**And** unit tests verify organization CRUD operations

---

### Story 2.7: Create Organization Use Case

**As a** newly registered user,
**I want** to create my organization after signing up,
**So that** I can start managing tournaments for my dojang (FR53).

**Acceptance Criteria:**

**Given** user is authenticated but has no organization
**When** they create an organization with name
**Then** `CreateOrganizationUseCase` creates organization in Supabase
**And** user is automatically assigned as Owner role
**And** organization is synced to local Drift database
**And** slug is auto-generated from name (lowercase, hyphenated)
**And** error cases handled (duplicate name, validation errors)
**And** unit tests verify organization creation flow

---

### Story 2.8: Invitation Entity & Send Invite

**As an** organization owner,
**I want** to invite team members with specific roles,
**So that** I can build my tournament staff (FR54, FR55).

**Acceptance Criteria:**

**Given** user is Owner of an organization
**When** they invite a user by email with a role
**Then** `InvitationEntity` is created with: `id`, `email`, `role`, `organizationId`, `invitedBy`, `status`, `expiresAt`
**And** `invitations` table is created in Drift
**And** `SendInvitationUseCase` creates invitation and sends email via Supabase Edge Function
**And** invited user can accept invitation via magic link
**And** `AcceptInvitationUseCase` adds user to organization with specified role
**And** unit tests verify invitation flow

---

### Story 2.9: RBAC Permission Service

**As a** developer,
**I want** a permission service that enforces role-based access control,
**So that** users can only perform actions allowed by their role (FR56, FR57).

**Acceptance Criteria:**

**Given** users have roles (Owner, Admin, Scorer, Viewer)
**When** I implement RBACPermissionService
**Then** permission matrix is defined:
  - Owner: all permissions
  - Admin: manage tournaments, divisions, participants, scoring
  - Scorer: enter scores only
  - Viewer: read-only access
**And** `canPerform(action, resource)` method checks permissions
**And** `UpdateUserRoleUseCase` allows Owner to change roles (FR57)
**And** `RemoveUserUseCase` allows Owner to remove team members (FR58)
**And** unit tests verify permission checks for all roles

---

### Story 2.10: Demo-to-Production Migration

**As a** user who explored demo mode,
**I want** my demo data migrated when I create an account,
**So that** I don't lose the tournament I was building.

**Acceptance Criteria:**

**Given** user has demo data locally (is_demo_data = true)
**When** they sign up and create an organization
**Then** `DemoMigrationService` runs migration:
  - UUIDs are remapped to new production UUIDs
  - `organization_id` is updated to new organization
  - `is_demo_data` is set to false
  - Data is synced to Supabase
**And** if user has no demo data, migration is skipped
**And** conflicts with existing server data are handled gracefully
**And** unit tests verify UUID remapping and data transformation

---

**Epic 2 Complete: 10 stories created**

---

## Epic 3: Tournament & Division Management — Stories

### Story 3.1: Tournament Feature Structure

**As a** developer,
**I want** the tournament feature properly structured with Clean Architecture layers,
**So that** all tournament-related code follows consistent patterns.

**Acceptance Criteria:**

**Given** the foundation and auth features exist
**When** I create the tournament feature structure
**Then** the following directory structure exists:
```
lib/features/tournament/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```
**And** the feature is registered in the DI container

---

### Story 3.2: Tournament Entity & Repository

**As a** developer,
**I want** the Tournament entity and repository implemented,
**So that** tournament data can be managed locally and synced to Supabase.

**Acceptance Criteria:**

**Given** the tournament feature structure exists
**When** I implement the Tournament entity and repository
**Then** `TournamentEntity` contains all fields from the Supabase schema
**And** `tournaments` table is created in Drift (mirroring Supabase schema)
**And** `TournamentRepository` handles local (Drift) and remote (Supabase) operations
**And** CRUD operations return `Either<Failure, T>`
**And** unit tests verify repository operations

---

### Story 3.3: Create Tournament Use Case

**As an** organizer,
**I want** to create a new tournament with name, date, and description,
**So that** I can start setting up my event (FR1).

**Acceptance Criteria:**

**Given** user is authenticated and has an organization
**When** they create a tournament
**Then** `CreateTournamentUseCase` validates input (name required, date >= today)
**And** tournament is saved to local Drift database immediately
**And** tournament is queued for sync to Supabase
**And** new tournament ID is returned
**And** unit tests verify validation and persistence

---

### Story 3.4: Tournament Settings Configuration

**As an** organizer,
**I want** to configure tournament settings like federation type, venue, and rings,
**So that** divisions and scoring are automatically configured correctly (FR2).

**Acceptance Criteria:**

**Given** a tournament exists
**When** I update tournament settings
**Then** `UpdateTournamentSettingsUseCase` updates: `federation_type`, `venue_name`, `venue_address`, `ring_count`
**And** changing federation_type updates available division templates
**And** settings are validated (ring_count 1-20, federation_type enum)
**And** changes are synced to Supabase
**And** unit tests verify settings updates

---

### Story 3.5: Duplicate Tournament as Template

**As an** organizer,
**I want** to duplicate an existing tournament as a template,
**So that** I can quickly set up similar events (FR3).

**Acceptance Criteria:**

**Given** a tournament exists with divisions configured
**When** I duplicate it
**Then** `DuplicateTournamentUseCase` creates a new tournament with:
  - New UUID
  - Name suffixed with "(Copy)"
  - All divisions copied with new UUIDs
  - No participants copied
  - Status reset to "draft"
**And** the new tournament is saved locally and synced
**And** unit tests verify duplication logic

---

### Story 3.6: Archive & Delete Tournament

**As an** organizer,
**I want** to archive completed tournaments or delete unwanted ones,
**So that** I can keep my tournament list organized (FR4, FR5).

**Acceptance Criteria:**

**Given** a tournament exists
**When** I archive it
**Then** `ArchiveTournamentUseCase` sets status to "archived" and sync_version increments

**Given** a tournament exists
**When** I delete it
**Then** `DeleteTournamentUseCase` marks `is_deleted = true` and sets `deleted_at`
**And** all related data (divisions, participants, brackets) is cascade soft-deleted
**And** unit tests verify archive and delete behaviors

---

### Story 3.7: Division Entity & Repository

**As a** developer,
**I want** the Division entity and repository implemented,
**So that** division data can be managed with proper criteria fields.

**Acceptance Criteria:**

**Given** the tournament feature exists
**When** I implement Division entity and repository
**Then** `DivisionEntity` contains all Smart Division Builder fields:
  - `age_min`, `age_max`, `belt_min`, `belt_max`, `weight_min`, `weight_max`, `gender`
  - `event_type`, `bracket_type`, `scoring_method`, `judge_count`
**And** `divisions` table is created in Drift
**And** `DivisionRepository` handles CRUD with parent tournament context
**And** unit tests verify repository operations

---

### Story 3.8: Smart Division Builder Algorithm

**As an** organizer,
**I want** the system to auto-generate divisions based on age/belt/weight/gender axes,
**So that** I can quickly set up proper competition categories (FR6).

**Acceptance Criteria:**

**Given** a tournament exists
**When** I use the Smart Division Builder
**Then** `SmartDivisionBuilderService` generates divisions from a configuration:
  - Age groups: 6-8, 9-10, 11-12, 13-14, 15-17, 18-32, 33+
  - Belt groups: white-yellow, green-blue, red-black
  - Weight classes: based on federation norms
  - Gender: male, female, or mixed
**And** divisions are named automatically (e.g., "Cadets -45kg Male")
**And** empty divisions (no combinations) are optionally created or skipped
**And** unit tests verify division generation for all axes

---

### Story 3.9: Federation Template Registry

**As an** organizer,
**I want** to apply pre-built WT, ITF, or ATA federation templates,
**So that** divisions match official competition standards (FR7).

**Acceptance Criteria:**

**Given** I'm creating divisions for a tournament
**When** I select a federation template
**Then** `FederationTemplateRegistry` provides static templates for:
  - **WT (World Taekwondo)**: Olympic-style divisions
  - **ITF (International TKD Federation)**: Pattern/sparring divisions
  - **ATA (American TKD Association)**: Forms/combat sparring divisions
**And** templates are loaded from both:
  - Hardcoded static definitions (always available)
  - Custom templates from `federation_templates` table
**And** unit tests verify template loading and application

---

### Story 3.10: Custom Division Creation

**As an** organizer,
**I want** to create fully custom divisions with arbitrary criteria,
**So that** I can handle non-standard competition formats (FR8).

**Acceptance Criteria:**

**Given** a tournament exists
**When** I create a custom division manually
**Then** `CreateDivisionUseCase` accepts:
  - Free-form name
  - Optional age/belt/weight/gender criteria
  - Event type and bracket type selection
  - Scoring configuration
**And** custom divisions are marked differently from template-generated ones
**And** unit tests verify custom division creation

---

### Story 3.11: Division Merge & Split

**As an** organizer,
**I want** to merge small divisions or split large ones,
**So that** I can ensure fair competition sizing (FR9, FR10).

**Acceptance Criteria:**

**Given** two divisions exist in the same tournament
**When** I merge them
**Then** `MergeDivisionsUseCase` creates a new combined division:
  - Participants from both are moved to new division
  - Original divisions are soft-deleted
  - New division has broadened criteria (e.g., weight range expanded)

**Given** a large division exists
**When** I split it into Pool A/B
**Then** `SplitDivisionUseCase` creates two divisions:
  - Participants are distributed (random or alphabetical)
  - Original division is soft-deleted
  - New divisions have "Pool A" / "Pool B" suffix
**And** unit tests verify merge and split logic

---

### Story 3.12: Ring Assignment Service

**As an** organizer,
**I want** to assign divisions to competition rings,
**So that** the event runs on multiple concurrent mats (FR11).

**Acceptance Criteria:**

**Given** a tournament has ring_count configured
**When** I assign a division to a ring
**Then** `AssignToRingUseCase` sets `ring_number` on the division
**And** multiple divisions can share the same ring (sequential)
**And** `display_order` determines sequence within a ring
**And** unit tests verify ring assignment

---

### Story 3.13: Scheduling Conflict Detection

**As an** organizer,
**I want** the system to detect when the same athlete is in overlapping divisions,
**So that** I can prevent scheduling conflicts (FR12).

**Acceptance Criteria:**

**Given** a participant is in multiple divisions
**When** those divisions are assigned to the same ring or overlapping times
**Then** `ConflictDetectionService` identifies the conflict
**And** warnings are returned listing: participant name, conflicting divisions, ring numbers
**And** conflicts do not block saving (warning only)
**And** unit tests verify conflict detection scenarios

---

### Story 3.14: Tournament Management UI

**As an** organizer,
**I want** a UI to manage tournaments, divisions, and settings,
**So that** I can visually set up my event.

**Acceptance Criteria:**

**Given** the tournament domain logic is complete
**When** I build the presentation layer
**Then** the following pages exist:
  - Tournament List page (dashboard)
  - Tournament Detail page (settings + divisions)
  - Division Builder page (Smart Builder wizard)
**And** `TournamentBloc` manages tournament list state
**And** `TournamentDetailBloc` manages single tournament state
**And** Material Design 3 theming is applied
**And** UI renders correctly in Chrome

---

**Epic 3 Complete: 14 stories created**

---

## Epic 4: Participant Management — Stories

### Story 4.1: Participant Feature Structure

**As a** developer,
**I want** the participant feature properly structured with Clean Architecture layers,
**So that** all participant-related code follows consistent patterns.

**Acceptance Criteria:**

**Given** the tournament feature exists
**When** I create the participant feature structure
**Then** the following directory structure exists:
```
lib/features/participant/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```
**And** the feature is registered in the DI container

---

### Story 4.2: Participant Entity & Repository

**As a** developer,
**I want** the Participant entity and repository implemented,
**So that** athlete data can be managed with TKD-specific attributes.

**Acceptance Criteria:**

**Given** the participant feature structure exists
**When** I implement the Participant entity and repository
**Then** `ParticipantEntity` contains: `firstName`, `lastName`, `dateOfBirth`, `age`, `gender`, `dojangName`, `dojangRegion`, `beltRank`, `weight`, `status`
**And** `participants` table is created in Drift
**And** `ParticipantRepository` handles CRUD with parent tournament context
**And** unit tests verify repository operations

---

### Story 4.3: Manual Participant Entry

**As an** organizer,
**I want** to manually add individual participants,
**So that** I can register athletes for my tournament (FR13).

**Acceptance Criteria:**

**Given** a tournament exists
**When** I add a participant manually
**Then** `CreateParticipantUseCase` validates:
  - First name, last name required
  - Dojang name required
  - Belt rank required
  - Weight optional but validated if provided (positive decimal)
**And** participant is saved to local Drift and queued for sync
**And** unit tests verify validation rules

---

### Story 4.4: CSV Import Parser

**As an** organizer,
**I want** to import participants from a CSV file,
**So that** I can bulk-register athletes from a spreadsheet (FR14).

**Acceptance Criteria:**

**Given** I have a CSV file with participant data
**When** I upload and parse it
**Then** `CSVParserService` handles:
  - Standard column headers (FirstName, LastName, DOB, Gender, Dojang, Belt, Weight)
  - Flexible column mapping (case-insensitive, aliases)
  - Date format detection (MM/DD/YYYY, YYYY-MM-DD, DD-MM-YYYY)
  - Belt rank normalization (e.g., "1st Dan" → "black_1dan")
**And** parsing errors are collected per-row, not failing entire import
**And** unit tests verify parsing with various CSV formats

---

### Story 4.5: Duplicate Detection Algorithm

**As an** organizer,
**I want** the system to detect potential duplicate participants,
**So that** I don't accidentally register the same athlete twice (FR15).

**Acceptance Criteria:**

**Given** participants exist in the tournament
**When** a new participant is added (manual or import)
**Then** `DuplicateDetectionService` checks for matches based on:
  - Exact match: same first name + last name + dojang
  - Fuzzy match: similar names (Levenshtein distance ≤ 2)
  - DOB match: same date of birth if provided
**And** potential duplicates are flagged with confidence score
**And** organizer can choose to: merge, skip, or create anyway
**And** unit tests verify detection algorithms

---

### Story 4.6: Bulk Import with Validation

**As an** organizer,
**I want** to import a CSV and see validation results before committing,
**So that** I can fix errors before registration (FR14, FR15).

**Acceptance Criteria:**

**Given** a parsed CSV file
**When** I preview the import
**Then** `BulkImportUseCase` displays:
  - Valid rows ready for import (green)
  - Rows with warnings (duplicates found) (yellow)
  - Rows with errors (missing required fields) (red)
**And** I can select which rows to import
**And** confirmed rows are batch-inserted to database
**And** unit tests verify bulk import flow

---

### Story 4.7: Participant Status Management

**As an** organizer,
**I want** to mark participants as no-show or disqualified,
**So that** brackets adjust correctly (FR16, FR17).

**Acceptance Criteria:**

**Given** a participant is registered
**When** I mark them as no-show
**Then** `MarkNoShowUseCase` sets `status = 'no_show'`
**And** their matches are forfeited (winner = opponent)
**And** bracket progression is recalculated

**Given** a participant has committed a rule violation
**When** I disqualify them
**Then** `DisqualifyUseCase` sets `status = 'disqualified'` and `dq_reason`
**And** their current match is forfeited
**And** unit tests verify status changes and bracket impact

---

### Story 4.8: Assign Participants to Divisions

**As an** organizer,
**I want** to manually assign participants to specific divisions,
**So that** I have full control over placement (FR18).

**Acceptance Criteria:**

**Given** participants and divisions exist
**When** I assign a participant to a division
**Then** `AssignToDivisionUseCase` creates a `division_participant` record
**And** a participant can be in multiple divisions (forms + sparring)
**And** the same participant cannot be added to the same division twice
**And** unit tests verify assignment logic

---

### Story 4.9: Auto-Assignment Algorithm

**As an** organizer,
**I want** the system to auto-assign participants to matching divisions,
**So that** I save time on large tournaments (FR19).

**Acceptance Criteria:**

**Given** participants have age, belt, weight, gender
**When** I run auto-assignment
**Then** `AutoAssignService` matches participants to divisions where:
  - Participant age within division's `age_min`-`age_max`
  - Participant belt within division's `belt_min`-`belt_max`
  - Participant weight within division's `weight_min`-`weight_max`
  - Participant gender matches division's `gender` (or division is mixed)
**And** unmatched participants are flagged for manual review
**And** unit tests verify matching across all criteria

---

### Story 4.10: Division Participant View

**As an** organizer,
**I want** to view all participants assigned to a division,
**So that** I can verify the roster before generating brackets (FR20).

**Acceptance Criteria:**

**Given** a division has participants assigned
**When** I view the division
**Then** `GetDivisionParticipantsUseCase` returns:
  - List of participants with name, dojang, seeding position
  - Count of participants
  - Division status (draft, ready, in_progress, completed)
**And** participants can be reordered for manual seeding
**And** unit tests verify retrieval and ordering

---

### Story 4.11: Participant Edit & Transfer

**As an** organizer,
**I want** to edit participant details or transfer them between divisions,
**So that** I can correct mistakes or rebalance divisions (FR21, FR22).

**Acceptance Criteria:**

**Given** a participant exists in a division
**When** I edit their details
**Then** `UpdateParticipantUseCase` updates fields and increments sync_version

**When** I transfer them to another division
**Then** `TransferParticipantUseCase` removes from old division and adds to new
**And** transfer is not allowed if bracket is in_progress
**And** unit tests verify edit and transfer

---

### Story 4.12: Participant Management UI

**As an** organizer,
**I want** a UI to manage participants with CSV import and assignment,
**So that** I can visually manage my tournament roster.

**Acceptance Criteria:**

**Given** the participant domain logic is complete
**When** I build the presentation layer
**Then** the following pages exist:
  - Participant List page (sortable, searchable)
  - CSV Import wizard (upload, map columns, preview, confirm)
  - Division Assignment view (drag-and-drop or checkbox selection)
**And** `ParticipantBloc` manages participant list state
**And** search filters by name, dojang, belt
**And** UI renders correctly with Material Design 3

---

**Epic 4 Complete: 12 stories created**

---

## Epic 5: Bracket Generation & Seeding — Stories

### Story 5.1: Bracket Feature Structure

**As a** developer,
**I want** the bracket feature properly structured with Clean Architecture layers,
**So that** all bracket-related code follows consistent patterns.

**Acceptance Criteria:**

**Given** the participant feature exists
**When** I create the bracket feature structure
**Then** the following directory structure exists:
```
lib/features/bracket/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```
**And** the feature is registered in the DI container

---

### Story 5.2: Bracket Entity & Repository

**As a** developer,
**I want** the Bracket entity and repository implemented,
**So that** bracket structure and seeding data can be persisted.

**Acceptance Criteria:**

**Given** the bracket feature structure exists
**When** I implement the Bracket entity and repository
**Then** `BracketEntity` contains: `divisionId`, `bracketType` (main/consolation), `seedingMethod`, `seedData` (JSONB), `layoutData` (JSONB), `status`
**And** `brackets` table is created in Drift
**And** `BracketRepository` handles CRUD with parent division context
**And** unit tests verify repository operations

---

### Story 5.3: Match Entity & Repository

**As a** developer,
**I want** the Match entity and repository implemented,
**So that** match tree structure and progression can be tracked.

**Acceptance Criteria:**

**Given** the bracket feature exists
**When** I implement the Match entity and repository
**Then** `MatchEntity` contains: `bracketId`, `roundNumber`, `matchNumber`, `positionInRound`, `participant1Id`, `participant2Id`, `winnerId`, `nextMatchId`, `nextMatchSlot`, `status`, `isBye`
**And** `matches` table is created in Drift
**And** self-referential FK for `nextMatchId` works correctly
**And** `MatchRepository` handles tree traversal queries
**And** unit tests verify match tree operations

---

### Story 5.4: Single Elimination Bracket Generator

**As an** organizer,
**I want** the system to generate a single elimination bracket,
**So that** I have the standard knockout format (FR23).

**Acceptance Criteria:**

**Given** a division has N participants
**When** I generate a single elimination bracket
**Then** `SingleEliminationGenerator` creates:
  - Bracket with `bracket_type = 'main'`
  - Correct number of rounds: ceil(log2(N))
  - Match tree where each winner advances to next round
  - Finals and 3rd-place match if configured
**And** generation completes in < 2 seconds for 64 participants (NFR4)
**And** unit tests verify bracket structure for 2, 4, 8, 16, 32, 64 participants

---

### Story 5.5: Double Elimination Bracket Generator

**As an** organizer,
**I want** the system to generate a double elimination bracket,
**So that** athletes get a second chance after one loss (FR24).

**Acceptance Criteria:**

**Given** a division has N participants
**When** I generate a double elimination bracket
**Then** `DoubleEliminationGenerator` creates:
  - Winners bracket (`bracket_type = 'main'`)
  - Losers bracket (`bracket_type = 'consolation'`)
  - Grand finals with potential reset match
  - Losers from winners bracket feed into losers bracket at correct positions
**And** generation completes in < 2 seconds for 64 participants
**And** unit tests verify both bracket structures and cross-bracket progression

---

### Story 5.6: Round Robin Bracket Generator

**As an** organizer,
**I want** the system to generate a round robin schedule,
**So that** every participant competes against every other (FR25).

**Acceptance Criteria:**

**Given** a division has N participants
**When** I generate a round robin bracket
**Then** `RoundRobinGenerator` creates:
  - Bracket with `bracket_type = 'pool_a'` (or pool_b for second pool)
  - N-1 rounds (or N rounds if N is odd with bye rotation)
  - Each participant faces every other participant exactly once
  - Match scheduling avoids consecutive matches for same participant
**And** standings are calculated by: wins, then point differential, then head-to-head
**And** unit tests verify schedule completeness for 4, 5, 6, 7, 8 participants

---

### Story 5.7: Dojang Separation Seeding Algorithm

**As an** organizer,
**I want** athletes from the same dojang to be seeded apart,
**So that** teammates don't face each other early in the bracket (FR26).

**Acceptance Criteria:**

**Given** participants are assigned to a division
**When** I apply dojang separation seeding
**Then** `DojangSeparationSeeder` uses constraint-satisfaction algorithm:
  - Constraint: Same-dojang athletes cannot meet until specified round (configurable: semis, quarters)
  - Algorithm: Backtracking with position swapping
  - Fallback: If impossible, minimize early same-dojang matches
**And** seeding positions are stored in `division_participants.seed_position`
**And** unit tests verify separation for various dojang distributions

---

### Story 5.8: Regional Separation Seeding

**As an** organizer,
**I want** athletes from the same region to be seeded apart,
**So that** regional clubs don't face each other early (FR27).

**Acceptance Criteria:**

**Given** participants have `dojang_region` set
**When** I apply regional separation seeding
**Then** `RegionalSeparationSeeder` applies similar constraint-satisfaction:
  - Same region avoided until specified round
  - Combines with dojang separation (dojang takes priority)
**And** works when some participants have no region set
**And** unit tests verify combined dojang + regional separation

---

### Story 5.9: Manual Seed Override

**As an** organizer,
**I want** to manually override automatic seeding,
**So that** I can place specific athletes in specific positions (FR28).

**Acceptance Criteria:**

**Given** a bracket has been generated
**When** I manually adjust seed positions
**Then** `ManualSeedOverrideUseCase` allows:
  - Swap two participants' positions
  - Pin a specific participant to a specific seed
  - Re-run auto-seeding around pinned participants
**And** changes update `seed_data` JSONB in bracket
**And** bracket must be regenerated to apply new seeding
**And** unit tests verify manual overrides

---

### Story 5.10: Bye Assignment Algorithm

**As an** organizer,
**I want** byes to be fairly distributed when participant count is not a power of 2,
**So that** top-seeded athletes get byes appropriately (FR29).

**Acceptance Criteria:**

**Given** a bracket is generated with N participants (N < next power of 2)
**When** byes are assigned
**Then** `ByeAssignmentService`:
  - Calculates required byes: (next_power_of_2) - N
  - Assigns byes to top seeds (position 1, 2, etc.)
  - Creates match records with `is_bye = true` and `status = 'bye'`
  - Advances bye recipients to next round automatically
**And** unit tests verify bye distribution for various participant counts

---

### Story 5.11: Bracket Regeneration

**As an** organizer,
**I want** to regenerate a bracket if participants change,
**So that** late additions or withdrawals are accommodated (FR30).

**Acceptance Criteria:**

**Given** a bracket exists in 'draft' or 'generated' status
**When** I regenerate the bracket
**Then** `RegenerateBracketUseCase`:
  - Soft-deletes existing bracket and all matches
  - Runs generation algorithm fresh with current participants
  - Creates new bracket and match records
**And** regeneration is blocked if bracket is 'in_progress' or 'completed'
**And** unit tests verify regeneration preserves participant assignments

---

### Story 5.12: Bracket Lock & Unlock

**As an** organizer,
**I want** to lock a bracket to prevent accidental changes,
**So that** live competition isn't disrupted (FR31, FR32).

**Acceptance Criteria:**

**Given** a bracket is generated
**When** I lock the bracket
**Then** `LockBracketUseCase` sets `status = 'in_progress'`
**And** participant additions/removals are blocked
**And** seeding changes are blocked
**And** scoring and match progression are still allowed

**When** I unlock the bracket
**Then** `UnlockBracketUseCase` sets `status = 'generated'`
**And** changes are allowed again (with warning)
**And** unit tests verify lock/unlock behavior

---

### Story 5.13: Bracket Visualization Renderer

**As an** organizer,
**I want** to see a visual representation of the bracket,
**So that** I can verify structure and track progress.

**Acceptance Criteria:**

**Given** the bracket domain logic is complete
**When** I build the bracket visualization
**Then** `BracketVisualizationWidget` renders:
  - Standard bracket tree layout for single/double elimination
  - Table layout for round robin
  - Match cards showing participants, status, score
  - Visual distinction for completed, in-progress, pending matches
**And** `BracketBloc` manages bracket state
**And** widget positions are computed from `layout_data` JSONB
**And** UI is zoomable/pannable for large brackets
**And** renders correctly in Chrome

---

**Epic 5 Complete: 13 stories created**

