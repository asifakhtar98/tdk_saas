---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-03-success', 'step-04-journeys', 'step-05-domain', 'step-06-innovation', 'step-07-project-type', 'step-08-scoping', 'step-09-functional', 'step-10-nonfunctional', 'step-11-polish']
inputDocuments:
  - brainstorming/brainstorming-session-2026-01-30.md
workflowType: 'prd'
documentCounts:
  briefs: 0
  research: 0
  brainstorming: 1
  projectDocs: 0
classification:
  projectType: 'SaaS B2B Web App'
  technology: 'Flutter Web (Desktop-only)'
  domain: 'Sports/Recreation Tech (Taekwondo Tournaments)'
  complexity: 'Medium'
  projectContext: 'Greenfield'
  realtimeRequired: false
  targetUsers: 'Dojangs, coaches, tournament organizers, federations'
  pricingModel: 'Freemium ($5/month Enterprise)'
---

# Product Requirements Document - TKD Brackets

**Author:** Asak  
**Date:** 2026-01-30

---

## Executive Summary

**TKD Brackets** is a Flutter Web-based SaaS tournament bracket creator designed specifically for Taekwondo. It enables dojangs, coaches, tournament organizers, and federations to build and customize brackets with proper TKD-specific seeding, manage divisions by weight/belt/age, submit match scores, and export professional results.

**Key Differentiators:**
- **TKD-Specific:** Smart Division Builder, dojang separation seeding, WT/ITF/ATA templates
- **Desktop-First:** Optimized for landscape desktop browsers (no mobile editing)
- **Simple Pricing:** Free tier with limits, $5/month Enterprise for unlimited

**Technology:** Flutter Web + Supabase (Auth, Database, Storage)

---

## Success Criteria

### User Success

**The "Aha!" Moment:**
- Tournament organizer creates their first complete bracket (8+ participants) in under **5 minutes** — vs. 30+ minutes with spreadsheets
- System auto-generates proper TKD divisions (weight/belt/age) with one click
- Dojang separation seeding "just works" — no more manually shuffling to avoid same-school matchups in Round 1

**Relief Moments:**
- No more redrawing brackets when athletes no-show — just remove and regenerate
- No more "which bracket format?" confusion — TKD-specific templates (WT, ITF, ATA) are built-in
- Clean, printable PDFs for each ring captain — no wrestling with formatting

**Completion Scenarios:**
- ✅ Tournament runs start to finish with zero bracket-related chaos
- ✅ Results are saved and accessible for future reference
- ✅ Organizer thinks *"I'm definitely using this next month"*

**Measurable User Metrics:**

| Metric                          | Target                                   |
| ------------------------------- | ---------------------------------------- |
| Time to create first bracket    | < 5 minutes                              |
| Bracket generation success rate | 100% (no manual fixes needed)            |
| User return rate                | 60%+ use again within 30 days            |
| Task completion rate            | 90%+ complete tournament without support |

### Business Success

**3-Month Milestones (Proof of Concept):**

| Metric                          | Target                                  |
| ------------------------------- | --------------------------------------- |
| Tournaments completed           | 50+                                     |
| Registered users                | 100+                                    |
| First paid Enterprise customers | 5-10                                    |
| Word-of-mouth referrals         | At least 20% of new users from referral |

**12-Month Milestones (Product-Market Fit):**

| Metric                           | Target |
| -------------------------------- | ------ |
| Monthly Active Tournaments       | 200+   |
| Registered dojangs/organizations | 500+   |
| Paying Enterprise customers      | 100+   |
| Monthly Recurring Revenue (MRR)  | $500+  |
| Net Promoter Score (NPS)         | 50+    |

**Success Indicator:**
> "TKD Brackets" becomes the go-to recommendation when someone asks "how do you run brackets?" in TKD Facebook groups and forums.

### Technical Success

| Metric                  | Target                        | Rationale                               |
| ----------------------- | ----------------------------- | --------------------------------------- |
| Page load time          | < 2 seconds                   | Desktop users expect snappy apps        |
| Bracket generation      | < 500ms                       | Instant feedback when creating brackets |
| PDF export              | < 3 seconds                   | No waiting around                       |
| Uptime                  | 99.5%+                        | Must be reliable on tournament day      |
| Zero data loss          | 100%                          | Tournament data is critical             |
| Desktop browser support | Chrome, Firefox, Safari, Edge | Cover 95%+ of desktop users             |

### Measurable Outcomes

**Core Success Equation:**
> Success = Organizers run complete tournaments without frustration AND come back for the next one

**Leading Indicators:**
- Bracket creation completion rate (started → finished)
- Division wizard usage rate (vs. manual entry)
- Export/share usage (indicates tournament actually ran)

**Lagging Indicators:**
- Customer retention (month-over-month active users)
- Upgrade conversion rate (Free → Enterprise)
- Referral rate

---

## Product Scope

### MVP - Minimum Viable Product

**Must have to be useful on Day 1:**

| Category              | Features                                                                                  |
| --------------------- | ----------------------------------------------------------------------------------------- |
| **Bracket Formats**   | Single elimination, Double elimination, Round robin                                       |
| **Participant Entry** | Manual entry, CSV import, paste from spreadsheet                                          |
| **TKD-Specific**      | Smart Division Builder (weight/belt/age), WT/ITF/ATA templates, Dojang separation seeding |
| **Seeding**           | Randomized seeding, Manual seed override                                                  |
| **Scoring**           | Keyboard-first score entry, Undo/redo                                                     |
| **Display**           | 2-3 themes (including dark mode), Zoom/pan for large brackets                             |
| **Export**            | PDF export (clean, no watermark), Shareable bracket links                                 |
| **Auth**              | Email OTP/Magic link sign-in (Supabase Auth)                                              |
| **Account**           | Save brackets, Private/public toggle                                                      |
| **Limits**            | Free: 3 active brackets, 16 participants, 2 tournaments/month                             |

### Growth Features (Post-MVP)

**Competitive edge and stickiness:**

| Category             | Features                                                           |
| -------------------- | ------------------------------------------------------------------ |
| **Extended Formats** | Pool play → elimination hybrid, Consolation/bronze matches         |
| **Batch Operations** | Multi-bracket dashboard, Batch score entry mode                    |
| **Display**          | Venue display mode (full-screen projector), Animated match updates |
| **Branding**         | Custom dojang logo, School color themes                            |
| **Permissions**      | Invite scorers with limited access                                 |
| **Analytics**        | Post-tournament analytics dashboard                                |
| **Integration**      | Webhook/Zapier integration                                         |

### Vision (Future)

**The dream version (12-24 months):**

| Category               | Features                                                        |
| ---------------------- | --------------------------------------------------------------- |
| **Ecosystem**          | Competitor profiles with performance history across tournaments |
| **Federation Tools**   | Multi-tournament management for federations                     |
| **Discovery**          | Public tournament discovery feed                                |
| **Mobile**             | View-only mobile app for spectators/parents                     |
| **Advanced Analytics** | Athlete performance trends, Training mode brackets              |
| **Integrations**       | Dojang integration API (Kicksite, Zen Planner)                  |
| **Community**          | Tournament rankings and leaderboards                            |

---

## User Journeys

### Journey 1: Master Kim — The Tournament Organizer (Primary User, Success Path)

**Persona:**
- **Name:** Master Kim, 4th Dan
- **Situation:** Runs "Kim's Taekwondo Academy" with 75 students in suburban Dallas. Hosts monthly in-house sparring tournaments to prepare students for regional competitions.
- **Current Pain:** Uses Excel spreadsheets printed on paper. Spends 2+ hours the night before every tournament manually creating brackets. When kids no-show, he has to hand-redraw everything.
- **Goal:** Run a smooth, professional-looking tournament in 3 hours with minimal stress.

---

**🎬 Opening Scene:**
It's Friday night, 8 PM. Master Kim just finished teaching his last class. Tomorrow is the monthly sparring tournament — 32 kids across 6 divisions. He opens his laptop, dreading the spreadsheet nightmare ahead.

Then he remembers: *"Let me try that TKD Brackets thing Coach Park recommended."*

**📈 Rising Action:**
- He signs up with email magic link in 10 seconds
- Clicks **"New Tournament"** → names it "January Sparring Championship"
- Opens **Smart Division Builder** — selects age groups, belt levels, weight classes
- Pastes his student roster from a spreadsheet — the system auto-sorts into 6 divisions
- The **Dojang Separation** toggle is ON by default — siblings and training partners won't face each other in Round 1
- He clicks **Generate Brackets** — boom. 6 clean single-elimination brackets in 3 seconds total

**🎯 Climax:**
Master Kim stares at the screen. *"Wait... that's it?"* He clicks through each division. Professional. Clean. Proper seeding. He exports PDFs for each ring captain — beautiful formatted brackets with the dojang logo.

**✅ Resolution:**
It's now 8:25 PM. What used to take 2 hours took 25 minutes. He texts his wife: *"Coming home early tonight."* 

Tomorrow, he'll run the smoothest tournament he's ever hosted. When parents ask what tool he used, he'll say: "TKD Brackets. It's free."

---

**🔧 Capabilities Revealed:**
- Email magic link sign-in
- Smart Division Builder (age/belt/weight)
- CSV/paste import from spreadsheet
- Dojang separation seeding
- One-click bracket generation
- PDF export with branding
- Tournament dashboard

---

### Journey 2: Master Kim — Match Day Chaos (Primary User, Edge Case)

**🎬 Opening Scene:**
It's Saturday 8:45 AM. Tournament starts in 15 minutes. Three kids just no-showed — one from each of the biggest divisions. Master Kim's stomach drops. *"Here we go again..."*

**📈 Rising Action:**
- He opens TKD Brackets on his laptop
- Navigates to the Cadets -45kg division
- Clicks on the no-show participant → **"Remove from Bracket"**
- The system asks: *"Regenerate bracket or promote opponent?"*
- He chooses **Regenerate** — the bracket rebuilds in under a second with correct bye placement
- He does the same for the other two no-shows
- Re-exports the affected PDFs and hands them to the ring captains

**🎯 Climax:**
Total time: 4 minutes. No hand-redrawing. No whiteout. No stress.

**✅ Resolution:**
The tournament starts on time. Master Kim thinks: *"Why didn't I find this sooner?"*

---

**🔧 Capabilities Revealed:**
- Remove participant from active bracket
- Bracket regeneration with bye optimization
- Quick PDF re-export
- Error recovery without losing other data

---

### Journey 3: Mrs. Rodriguez — The Parent Volunteer Scorer

**Persona:**
- **Name:** Sandra Rodriguez
- **Situation:** Her son Diego is competing today. Master Kim asked if she could help score Ring 2.
- **Current Pain:** She's not tech-savvy and worried about messing something up.
- **Goal:** Enter scores correctly without embarrassing herself.

---

**🎬 Opening Scene:**
Sandra sits at the scorer's table with a printed bracket and a laptop. Master Kim shows her TKD Brackets already open to Ring 2's division.

*"Just type the winner's score and press Enter. That's it."*

**📈 Rising Action:**
- The current match is highlighted on screen
- She watches the match: **Ethan vs. Maya**
- Ethan wins 12-8
- She clicks on the match → a simple score modal appears
- Types `12` for Ethan, `8` for Maya → hits **Submit**
- The bracket animates — Ethan "moves up" to the next round
- The next match auto-highlights

**🎯 Climax:**
Sandra realizes: *"Oh, this is actually easy."* She enters 8 scores in 20 minutes without any help.

**✅ Resolution:**
At the end of the day, Master Kim thanks her. She says: *"That was way simpler than I expected. Happy to help next time!"*

---

**🔧 Capabilities Revealed:**
- Scorer role with limited access (can only score assigned division)
- Simple score entry modal
- Keyboard-friendly input (Tab/Enter)
- Visual feedback on score submission (animation)
- Auto-highlight next match
- Undo/redo for mistakes

---

### Journey 4: David Chen — The Anxious Dad Spectator

**Persona:**
- **Name:** David Chen
- **Situation:** His daughter Lily is competing in her first tournament. He's sitting in the bleachers, nervously checking his phone.
- **Goal:** Know when Lily's next match is so he doesn't miss it.

---

**🎬 Opening Scene:**
David got a text from Master Kim before the tournament: *"Track Lily's matches here: [link]"*

He opens the link on his phone. A clean, mobile-friendly bracket view loads.

**📈 Rising Action:**
- He sees the Girls 9-10 Intermediate division bracket
- Lily is in the second match of Round 1
- The first match finishes — he refreshes the page (manual refresh, no realtime)
- The bracket updates: *"Lily vs. Emma — Ring 1 — Up Next"*
- He rushes over to Ring 1 just in time

**🎯 Climax:**
Lily wins! 🎉 David refreshes again — she's now shown in the semifinals. He screenshots the bracket and texts it to Grandma.

**✅ Resolution:**
David thinks: *"This is so much better than asking random people what's happening."* He shares the link in the family group chat.

---

**🔧 Capabilities Revealed:**
- Public shareable bracket links
- Mobile-friendly view-only mode
- Manual refresh to see updates
- Clean, readable bracket visualization
- Screenshot-friendly design

---

### Journey Requirements Summary

| Journey                     | Key Capabilities Revealed                                                                           |
| --------------------------- | --------------------------------------------------------------------------------------------------- |
| **Master Kim - Setup**      | Email magic link, Division Builder, CSV import, Dojang separation, PDF export, One-click generation |
| **Master Kim - Edge Case**  | Remove participant, Bracket regeneration, Quick re-export, Error recovery                           |
| **Mrs. Rodriguez - Scorer** | Scorer role/permissions, Simple score modal, Keyboard input, Undo/redo, Visual animations           |
| **David Chen - Spectator**  | Public links, Mobile view-only, Manual refresh, Clean visualization                                 |

**All journeys connect to these core capability areas:**
1. **Onboarding & Auth** — Quick signup, role-based access
2. **Division Management** — Smart builder, templates, seeding
3. **Bracket Operations** — Generate, modify, regenerate
4. **Scoring System** — Simple entry, keyboard-first, undo
5. **Export & Sharing** — PDF, links, mobile-friendly views
6. **Error Handling** — No-shows, mistakes, recovery

---

## Domain-Specific Requirements

### Federation Support

**Full Support for All Major TKD Federations:**

| Federation                             | Status | Scope                                                                                 |
| -------------------------------------- | ------ | ------------------------------------------------------------------------------------- |
| **WT (World Taekwondo)**               | ✅ Full | Olympic-style weight classes, all official age groups, PSS-compatible scoring display |
| **ITF (International TKD Federation)** | ✅ Full | Traditional divisions, point-based scoring, pattern categories                        |
| **ATA (American Taekwondo Assoc.)**    | ✅ Full | US circuit format, ring system, family-friendly categories                            |

**Implementation:**
- Pre-built official division templates per federation
- Fully customizable weight/age/belt categories
- Federation-specific scoring display options
- Easy template updates when federation rules change

---

### Division Structure Requirements

**Complete Multi-Axis Division Builder:**

| Axis               | Support | Notes                                                                                          |
| ------------------ | ------- | ---------------------------------------------------------------------------------------------- |
| **Age Groups**     | ✅ Full  | Configurable ranges with pre-built templates (Cubs, Tigers, Cadets, Juniors, Seniors, Masters) |
| **Belt Ranks**     | ✅ Full  | Color belts, Black belt degrees (1st-9th Dan), custom groupings                                |
| **Weight Classes** | ✅ Full  | Official federation weights + fully custom weights                                             |
| **Gender**         | ✅ Full  | Male, Female, Mixed, Coed options                                                              |
| **Event Type**     | ✅ Full  | Sparring, Poomsae/Forms, Breaking, Team events                                                 |

**Complete Division Templates:**

```
WT Official Templates:
├── Cadets (12-14): -33kg, -37kg, -41kg, -45kg, -49kg, -53kg, +53kg (M/F)
├── Juniors (15-17): -45kg, -48kg, -51kg, -55kg, -59kg, -63kg, +63kg (M/F)
├── Seniors (18+): -54kg, -58kg, -63kg, -68kg, -74kg, -80kg, +80kg (M/F)
└── Masters (30+, 40+, 50+): Same weight classes

ATA Official Templates:
├── Color Belt: Cubs, Tigers, Cadets, Jr/Sr with weapons, creative forms
├── Black Belt: 1st Degree, 2nd Degree, 3rd+
└── Special Events: XMA, Creative, Weapons

ITF Official Templates:
├── Light, Middle, Light-Heavy, Heavy per age group
├── Pattern divisions by rank
└── Special technique, power breaking
```

---

### Event Type Support

**All TKD Competition Events:**

| Event Type             | Support | Bracket Format                                                          |
| ---------------------- | ------- | ----------------------------------------------------------------------- |
| **Sparring (Kyorugi)** | ✅ Full  | Single Elimination, Double Elimination, Round Robin, Pool → Elimination |
| **Forms (Poomsae)**    | ✅ Full  | Score-based ranking system with judge panels                            |
| **Breaking**           | ✅ Full  | Scored events with category rankings                                    |
| **Team Sparring**      | ✅ Full  | 3v3/5v5 team structures with aggregate scoring                          |
| **Team Forms**         | ✅ Full  | Synchronized poomsae with team scoring                                  |
| **Creative/XMA**       | ✅ Full  | Score-based with custom judge criteria                                  |

**Forms/Poomsae Specific Features:**
- Multiple judge score entry (3-5 judges)
- Automatic score calculation (drop high/low optional)
- Ranking display by total score
- Tie-breaker rules per federation

---

### Seeding & Matchup Rules

**Complete Seeding System:**

| Rule                          | Status | Description                                         |
| ----------------------------- | ------ | --------------------------------------------------- |
| **Dojang Separation**         | ✅ Full | Same-school athletes separated in early rounds      |
| **Regional Separation**       | ✅ Full | Same-region athletes separated at larger events     |
| **Random Seeding**            | ✅ Full | Fair cryptographic randomization                    |
| **Ranked Seeding**            | ✅ Full | Import external ranking points for seeded placement |
| **Performance-Based Seeding** | ✅ Full | Use historical win rates from past tournaments      |
| **Manual Override**           | ✅ Full | Drag-and-drop adjust any seed position              |
| **Bye Optimization**          | ✅ Full | Intelligent bye placement for fair brackets         |
| **Combined Division Seeding** | ✅ Full | When divisions merge, proper seeding applied        |

---

### Tournament Operations

**All Match Day Scenarios:**

| Scenario                 | Handling                                                    |
| ------------------------ | ----------------------------------------------------------- |
| **No-Show**              | Remove participant → Regenerate bracket OR promote opponent |
| **Weight Change**        | Move athlete to different division, re-seed if needed       |
| **Medical DQ**           | Mark as medical DQ, opponent advances, proper notation      |
| **Conduct DQ**           | Mark as conduct DQ, opponent advances, different notation   |
| **Bracket Regeneration** | Full recalculation with proper bye placement                |
| **Score Correction**     | Complete undo/redo history, score audit trail               |
| **Division Merge**       | Combine small divisions with proper re-seeding              |
| **Division Split**       | Separate large divisions into A/B pools                     |
| **Ring Assignment**      | Assign divisions to competition rings                       |
| **Schedule Conflicts**   | Alert when same athlete has overlapping matches             |
| **PDF Re-Export**        | Instant re-print for ring captains                          |

---

### Scoring Models

**Federation-Aware Scoring:**

| Federation       | Scoring Features                                                                       |
| ---------------- | -------------------------------------------------------------------------------------- |
| **WT Sparring**  | Head kicks (3pt), Trunk kicks (2pt), Spinning (bonus), Gamjeon penalties, Golden round |
| **ITF Sparring** | Point values per technique, traditional scoring                                        |
| **ATA Sparring** | Point sparring with ring system                                                        |
| **All Forms**    | Multiple judge scores, calculation methods (average, drop high/low)                    |
| **Breaking**     | Scored by attempt/success, power levels                                                |

**Scoring Display Options:**
- Simple (winner + final score)
- Detailed (point breakdown by technique)
- Judge panel (individual judge scores visible)

---

### Privacy & Data Requirements

| Area                   | Approach                                                      |
| ---------------------- | ------------------------------------------------------------- |
| **Minor Athletes**     | Organizer enters data — no direct child accounts              |
| **COPPA Compliance**   | No direct data collection from children under 13              |
| **Athlete Profiles**   | Optional profiles with performance history across tournaments |
| **Data Retention**     | Configurable retention policies, tournament archive           |
| **Public vs Private**  | Granular visibility (public, link-only, private)              |
| **Data Export**        | Athlete can request their competition history                 |
| **Consent Management** | Digital waiver/consent during registration                    |

---

### Technical Domain Constraints

| Constraint                     | Requirement                                              |
| ------------------------------ | -------------------------------------------------------- |
| **Tournament Day Reliability** | 99.9% uptime, must work during live events               |
| **Offline Mode**               | Full offline capability with sync when connected         |
| **Fast Operations**            | All bracket operations < 500ms                           |
| **Print-Ready Output**         | Professional PDFs on standard printers                   |
| **Low-Tech Venues**            | Works on basic laptops, no special hardware              |
| **Multi-Ring Support**         | Manage 12+ competition rings simultaneously              |
| **Multi-User Concurrent**      | Multiple scorers updating different rings simultaneously |
| **Venue Display Mode**         | Full-screen projector mode with auto-refresh             |

---

### Integration Requirements

| Integration                   | Support                                           |
| ----------------------------- | ------------------------------------------------- |
| **Dojang Management Systems** | API integration with Kicksite, Zen Planner, Ember |
| **Athlete Registration**      | Import from external registration systems         |
| **Federation Rankings**       | Import/export ranking points for WT, ITF, ATA     |
| **Payment Processing**        | Stripe integration for tournament fees            |
| **Digital Waivers**           | Integration with waiver platforms                 |
| **Export Formats**            | PDF, PNG, CSV, JSON, XML                          |
| **Webhook/Zapier**            | Real-time event triggers for external systems     |

---

### Domain Risk Mitigations

| Risk                            | Mitigation                                                           |
| ------------------------------- | -------------------------------------------------------------------- |
| **Data loss during tournament** | Aggressive autosave, offline mode, sync indicator, automatic backups |
| **Wrong bracket format**        | Preview before generating, easy regeneration, undo capability        |
| **Scoring mistakes**            | Full undo/redo, score history, audit trail                           |
| **Internet outage at venue**    | Complete offline mode with later sync                                |
| **Complex division needs**      | Fully flexible custom divisions                                      |
| **Federation rule changes**     | Data-driven templates, admin update interface                        |
| **Multiple rings out of sync**  | Conflict resolution, last-write-wins with history                    |

---

## Innovation & Differentiation

### Competitive Positioning

**Strategy:** Vertical SaaS specialization in a horizontal market

TKD Brackets takes the generic bracket tool market (BracketHQ, Challonge, Smoothcomp) and deeply specializes for Taekwondo, embedding domain knowledge that generic tools cannot easily replicate.

### Key Differentiators

| Differentiator                | Description                                                             | Defensibility                                  |
| ----------------------------- | ----------------------------------------------------------------------- | ---------------------------------------------- |
| **Smart Division Builder**    | Auto-generates divisions from weight/age/belt with federation templates | High — requires TKD domain knowledge           |
| **Dojang Separation Seeding** | Prevents same-school matchups automatically                             | High — domain-specific algorithm               |
| **Federation Templates**      | Pre-built WT, ITF, ATA division structures                              | Medium — data-driven but copyable              |
| **TKD-Native UX**             | Designed for tournament organizers, not generic users                   | Medium — requires understanding user workflows |
| **Quantity-Based Freemium**   | All features free, upgrade for quantity only                            | Low — business model, easily copied            |

### Competitive Landscape

| Competitor     | Type                     | Weakness vs. TKD Brackets                          |
| -------------- | ------------------------ | -------------------------------------------------- |
| **BracketHQ**  | Generic bracket tool     | No TKD-specific features, no division builder      |
| **Challonge**  | Gaming-focused           | Not designed for sports, no weight/belt categories |
| **Smoothcomp** | Martial arts (BJJ focus) | Complex, expensive, overkill for small dojangs     |
| **TKD Score**  | TKD-specific scoring     | Scoring only, not bracket management               |
| **SportData**  | Federation-level         | Enterprise pricing, not accessible to small clubs  |

### Moat Strategy

**Short-term Moat (Year 1):**
- Domain depth (division builder, federation templates)
- Word-of-mouth in TKD community
- Low barrier to entry (free tier with full features)

**Long-term Moat (Year 2+):**
- Athlete performance data across tournaments
- Federation partnerships and integrations
- Community network effects (discovery feed, rankings)

### Validation Approach

| Hypothesis                                    | Validation Method                         |
| --------------------------------------------- | ----------------------------------------- |
| TKD organizers prefer specialized tools       | User interviews, usage metrics            |
| Smart Division Builder saves significant time | Time-to-create comparison vs. manual      |
| Dojang separation is a must-have              | Feature usage tracking, NPS surveys       |
| $5/month is right price point                 | Conversion rate monitoring, price testing |

### Risk Mitigation

| Risk                                | Mitigation                                          |
| ----------------------------------- | --------------------------------------------------- |
| Market too small                    | Expand to adjacent martial arts (BJJ, Karate, Judo) |
| Generic tools add TKD features      | Stay ahead with deeper domain features              |
| Low willingness to pay              | Validate with early users before heavy investment   |
| Federation partnerships hard to get | Start bottom-up with individual dojangs             |

---

## SaaS B2B Specific Requirements

### Multi-Tenancy Model

**Approach:** Account-based multi-tenancy with row-level security

| Concept            | Implementation                                                          |
| ------------------ | ----------------------------------------------------------------------- |
| **Tenant**         | Organization (Dojang, Club, Federation)                                 |
| **Data Isolation** | Supabase RLS — each organization's data fully isolated                  |
| **Hierarchy**      | Organization → Tournaments → Divisions → Brackets                       |
| **Cross-Tenant**   | Public brackets visible to all, athlete profiles can span orgs (future) |

---

### Permission Model (RBAC Matrix)

| Role       | Create Tournament | Manage Brackets | Score Matches | View Brackets   | Manage Org |
| ---------- | ----------------- | --------------- | ------------- | --------------- | ---------- |
| **Owner**  | ✅                 | ✅               | ✅             | ✅               | ✅          |
| **Admin**  | ✅                 | ✅               | ✅             | ✅               | ❌          |
| **Scorer** | ❌                 | ❌               | ✅ (assigned)  | ✅               | ❌          |
| **Viewer** | ❌                 | ❌               | ❌             | ✅               | ❌          |
| **Public** | ❌                 | ❌               | ❌             | ✅ (public only) | ❌          |

**Invitation Flow:**
- Owner invites users via email
- Link to join with pre-assigned role
- Scoped to specific tournaments or full organization

---

### Subscription Tiers

**Quantity-Based Freemium Model:**

| Feature                      | Free Tier              | Enterprise ($5/month) |
| ---------------------------- | ---------------------- | --------------------- |
| **All Features**             | ✅                      | ✅                     |
| **Active Brackets**          | 3                      | Unlimited             |
| **Participants per Bracket** | 32                     | Unlimited             |
| **Tournaments per Month**    | 2                      | Unlimited             |
| **Scorers**                  | 2                      | Unlimited             |
| **Branding**                 | TKD Brackets watermark | Custom logo           |
| **Priority Support**         | ❌                      | ✅                     |
| **Analytics**                | Basic                  | Full dashboard        |

**Billing Integration:** Stripe Checkout

---

### Integration Requirements

**Core Integrations:**

| Integration        | Priority | Purpose                                   |
| ------------------ | -------- | ----------------------------------------- |
| **Supabase Auth**  | Core     | Email OTP/magic link authentication       |
| **Stripe**         | High     | Subscription billing, payment processing  |
| **PDF Generation** | Core     | Export brackets for print                 |
| **Webhooks**       | Medium   | Notify external systems on bracket events |
| **Zapier**         | Growth   | Connect to 1000+ apps for automation      |

**Dojang System Integrations (Future):**

| System | Type | Purpose |
| ------ | ---- | ------- ||
| **Kicksite** | Dojang management | Import student roster |
| **Zen Planner** | Dojang management | Sync athlete data |
| **Ember** | Dojang management | Registration integration |
| **Federation APIs** | WT, ITF, ATA | Ranking points sync |

**Export/Import Formats:**
- CSV import (roster, participants)
- PDF export (brackets, results)
- JSON export (full tournament data)
- PNG export (bracket images)

---

### Compliance Requirements

| Regulation  | Applicability     | Handling                                          |
| ----------- | ----------------- | ------------------------------------------------- |
| **GDPR**    | EU users          | Data export, deletion rights, privacy policy      |
| **COPPA**   | US users under 13 | No direct child accounts — organizer enters data  |
| **PCI-DSS** | Payment handling  | Stripe handles all payment data — no card storage |
| **SOC 2**   | Enterprise trust  | Future consideration for federation deals         |

**Data Handling:**
- Tournament data stored in Supabase (Postgres)
- Images/PDFs stored in Supabase Storage
- No sensitive data stored client-side beyond session
- Data encrypted at rest and in transit

---

## Project Scoping & Development Strategy

### Scope Philosophy

**Approach:** Full Vision Build — Complete Product at Launch

TKD Brackets will ship as a fully-featured tournament management platform from Day 1. All capabilities are included in the initial release, delivering the complete vision without phased rollouts.

**Rationale:**
- Compete on depth, not speed — generic tools can't match full TKD specialization
- Word-of-mouth works better with a polished, complete product
- No "coming soon" features that frustrate early adopters
- Federation partnerships require professional-grade completeness

---

### Complete Feature Set

**All Capabilities Included at Launch:**

#### Bracket Management
- ✅ Single elimination, Double elimination, Round robin
- ✅ Pool play → elimination hybrid
- ✅ Consolation/bronze matches
- ✅ Bracket regeneration for no-shows/DQs
- ✅ One-click generation with bye optimization

#### Event Types
- ✅ Sparring (Kyorugi) — head-to-head brackets
- ✅ Forms (Poomsae) — score-based with judge panels
- ✅ Breaking — scored events with rankings
- ✅ Team Sparring — 3v3/5v5 structures
- ✅ Team Forms — synchronized with team scoring
- ✅ Creative/XMA — custom judge criteria

#### Division Management
- ✅ Smart Division Builder (age/belt/weight/gender)
- ✅ WT, ITF, ATA official templates
- ✅ Fully custom division creation
- ✅ Division merge and split operations
- ✅ Multi-ring assignment and scheduling

#### Seeding & Matching
- ✅ Dojang separation seeding
- ✅ Regional separation
- ✅ Random seeding with cryptographic fairness
- ✅ Ranked seeding (import federation rankings)
- ✅ Performance-based seeding (historical data)
- ✅ Manual seed override with drag-and-drop

#### Scoring System
- ✅ Federation-aware scoring (WT, ITF, ATA)
- ✅ Multiple judge score entry
- ✅ Automatic calculation methods
- ✅ Simple and detailed score display
- ✅ Keyboard-first input
- ✅ Complete undo/redo with audit trail

#### Tournament Operations
- ✅ No-show handling (remove/regenerate)
- ✅ Medical and conduct DQ tracking
- ✅ Weight change division moves
- ✅ Schedule conflict detection
- ✅ Multi-ring concurrent management
- ✅ Venue display mode (projector)

#### Export & Sharing
- ✅ PDF export (brackets, results)
- ✅ PNG export (bracket images)
- ✅ CSV/JSON export (data)
- ✅ Public shareable links
- ✅ Mobile-friendly view-only mode

#### Authentication & Accounts
- ✅ Supabase Auth with email OTP/magic link
- ✅ Organization accounts with hierarchy
- ✅ RBAC (Owner, Admin, Scorer, Viewer)
- ✅ Invitation flow with role assignment

#### Billing & Subscription
- ✅ Free tier with quantity limits
- ✅ Enterprise tier ($5/month) unlimited
- ✅ Stripe Checkout integration
- ✅ Custom branding for Enterprise

#### Offline & Reliability
- ✅ Full offline capability with sync
- ✅ Aggressive autosave
- ✅ Conflict resolution for multi-user edits
- ✅ 99.9% uptime target

#### Integrations
- ✅ Webhooks for external systems
- ✅ Zapier integration
- ✅ Kicksite, Zen Planner, Ember import
- ✅ Federation ranking sync (WT, ITF, ATA)

#### Analytics
- ✅ Tournament analytics dashboard
- ✅ Athlete performance history
- ✅ Post-event reports

---

### Resource Requirements

**Capability Priorities:**

| Capability Area                                   | Priority |
| ------------------------------------------------- | -------- |
| Core bracket engine & algorithms                  | Critical |
| Smart Division Builder                            | Critical |
| All event types (Sparring, Forms, Breaking, Team) | High     |
| Federation scoring models                         | High     |
| Multi-ring management & scheduling                | High     |
| Offline mode with sync                            | High     |
| RBAC & invitation system                          | High     |
| PDF/PNG export                                    | High     |
| Dojang integrations                               | Medium   |
| Analytics dashboard                               | Medium   |
| Billing (Stripe)                                  | Medium   |

**Recommended Team:**
- 1-2 Senior Flutter developers
- 1 Backend/Supabase specialist (part-time)
- 1 Designer (initial phase)
- Domain expert (TKD consultant)

---

### Risk Strategy

| Risk                       | Mitigation                                                     |
| -------------------------- | -------------------------------------------------------------- |
| **Long development cycle** | Modular architecture allows parallel development               |
| **Feature creep**          | Frozen scope — everything above, nothing more                  |
| **Market timing**          | Private beta with select dojangs during development            |
| **Technical complexity**   | Offline sync and multi-ring are highest risk — prototype early |
| **Resource constraints**   | Core bracket engine is foundational — build first and solid    |

---

### Success Milestones

| Milestone            | Target                                     |
| -------------------- | ------------------------------------------ |
| **Alpha (Internal)** | Core brackets working end-to-end           |
| **Beta (Closed)**    | 5-10 dojangs testing in real tournaments   |
| **Launch**           | Public release with all features           |
| **Traction**         | 50+ tournaments completed in first 90 days |
| **Revenue**          | First 10 paying Enterprise customers       |

---

## Functional Requirements

### 1. Tournament Management

- **FR1:** Organizer can create a new tournament with name, date, and description
- **FR2:** Organizer can configure tournament-level settings (federation type, venue, rings)
- **FR3:** Organizer can duplicate an existing tournament as a template
- **FR4:** Organizer can archive completed tournaments
- **FR5:** Organizer can delete a tournament and all associated data

---

### 2. Division Management

- **FR6:** Organizer can create divisions using the Smart Division Builder (age/belt/weight/gender axes)
- **FR7:** Organizer can apply pre-built federation templates (WT, ITF, ATA)
- **FR8:** Organizer can create fully custom divisions with arbitrary criteria
- **FR9:** Organizer can merge two small divisions into one
- **FR10:** Organizer can split a large division into pool A/B
- **FR11:** Organizer can assign divisions to competition rings
- **FR12:** System detects scheduling conflicts when same athlete is in overlapping divisions

---

### 3. Participant Management

- **FR13:** Organizer can add participants manually with name, dojang, age, belt, weight
- **FR14:** Organizer can import participants via CSV upload
- **FR15:** Organizer can paste participant data from spreadsheet
- **FR16:** System auto-assigns participants to appropriate divisions based on criteria
- **FR17:** Organizer can move a participant between divisions
- **FR18:** Organizer can remove a participant from a bracket (no-show handling)
- **FR19:** Organizer can mark a participant as DQ (medical or conduct)

---

### 4. Bracket Generation

- **FR20:** System can generate single elimination brackets
- **FR21:** System can generate double elimination brackets
- **FR22:** System can generate round robin brackets
- **FR23:** System can generate pool play → elimination hybrid brackets
- **FR24:** System can generate consolation/bronze match brackets
- **FR25:** System applies dojang separation seeding automatically
- **FR26:** System applies regional separation seeding when configured
- **FR27:** System applies random seeding with cryptographic fairness
- **FR28:** Organizer can import ranked seeding from federation data
- **FR29:** Organizer can manually override seed positions with drag-and-drop
- **FR30:** System optimizes bye placement for fairness
- **FR31:** Organizer can regenerate a bracket after participant changes

---

### 5. Scoring & Match Management

- **FR32:** Scorer can enter match results (winner + scores)
- **FR33:** Scorer can enter federation-specific scoring details (WT/ITF/ATA)
- **FR34:** Scorer can enter multiple judge scores for forms events
- **FR35:** System calculates forms rankings using configured method (average, drop high/low)
- **FR36:** System advances winner to next round automatically
- **FR37:** Scorer can undo/redo score entries
- **FR38:** System maintains complete score audit trail
- **FR39:** System highlights current/next match in each bracket

---

### 6. Multi-Ring Operations

- **FR40:** Organizer can view all rings/divisions on a dashboard
- **FR41:** Multiple scorers can update different rings simultaneously
- **FR42:** System resolves conflicts when multiple users edit same data
- **FR43:** Organizer can view venue display mode (full-screen for projector)
- **FR44:** Venue display auto-refreshes when scores update

---

### 7. Export & Sharing

- **FR45:** Organizer can export brackets as PDF (print-ready)
- **FR46:** Organizer can export brackets as PNG images
- **FR47:** Organizer can export tournament data as CSV/JSON
- **FR48:** Organizer can generate shareable public links to brackets
- **FR49:** Spectator can view public brackets on mobile-friendly view
- **FR50:** Spectator can refresh bracket view to see latest scores

---

### 8. Authentication & Accounts

- **FR51:** User can sign up with email OTP/magic link (Supabase Auth)
- **FR52:** User can sign in with email OTP/magic link
- **FR53:** User can create an organization account
- **FR54:** Owner can invite users to organization with assigned role
- **FR55:** Invited user can accept invitation and join organization
- **FR56:** System enforces RBAC permissions (Owner, Admin, Scorer, Viewer)
- **FR57:** Owner can change user roles within organization
- **FR58:** Owner can remove users from organization

---

### 9. Billing & Subscription

- **FR59:** User can view current subscription tier and usage
- **FR60:** User can upgrade from Free to Enterprise tier
- **FR61:** System enforces Free tier limits (3 brackets, 32 participants, 2 tournaments/month)
- **FR62:** Enterprise user has unlimited brackets, participants, tournaments
- **FR63:** Enterprise user can upload custom organization logo
- **FR64:** System integrates with Stripe for payment processing

---

### 10. Offline & Reliability

- **FR65:** System saves data every 5 seconds (autosave)
- **FR66:** System works offline with full functionality
- **FR67:** System syncs data when connection restored
- **FR68:** System shows sync status indicator
- **FR69:** System resolves multi-user edit conflicts using last-write-wins with visual notification to affected users

---

### 11. Integrations

- **FR70:** Organizer can import participant data from Kicksite
- **FR71:** Organizer can import participant data from Zen Planner
- **FR72:** Organizer can import participant data from Ember
- **FR73:** Organizer can sync ranking points with federation APIs (WT, ITF, ATA)
- **FR74:** System can send webhook notifications on bracket events
- **FR75:** System integrates with Zapier for automation

---

### 12. Analytics & Reporting

- **FR76:** Organizer can view tournament analytics dashboard
- **FR77:** System tracks athlete performance history across tournaments
- **FR78:** Organizer can generate post-event reports

---

## Non-Functional Requirements

### Performance

| Requirement | Target | Rationale |
| ----------- | ------ | --------- ||
| **Page Load** | < 2 seconds | Desktop users expect snappy apps |
| **Bracket Generation** | < 500ms | Instant feedback on creation |
| **Score Submission** | < 200ms | Real-time feel during matches |
| **PDF Export** | < 3 seconds | No waiting for prints |
| **Search/Filter** | < 100ms | Instant results |
| **Concurrent Users** | 50+ per tournament | Multi-ring, multi-scorer support |

---

### Reliability

| Requirement | Target | Rationale |
| ----------- | ------ | --------- ||
| **Uptime** | 99.9% | Tournament day must not fail |
| **Data Durability** | Zero data loss | Tournament data is critical |
| **Autosave Frequency** | Every 5 seconds | Aggressive protection against loss |
| **Offline Mode** | Full functionality | Internet unreliable at venues |
| **Recovery Time** | < 1 minute | Quick restore after any issue |

---

### Security

| Requirement | Target | Rationale |
| ----------- | ------ | --------- ||
| **Authentication** | Supabase Auth (email OTP/magic link) | Secure, passwordless login |
| **Data Encryption** | At rest and in transit (TLS 1.3) | Industry standard protection |
| **Session Management** | Automatic timeout after inactivity | Prevent unauthorized access |
| **RBAC Enforcement** | Server-side validation | Roles cannot be bypassed |
| **Payment Data** | Never stored locally (Stripe handles) | PCI-DSS compliance |
| **GDPR Compliance** | Data export, deletion rights | EU user protection |
| **COPPA Compliance** | No child accounts | Organizer-entered data only |

---

### Scalability

| Requirement | Target | Rationale |
| ----------- | ------ | --------- ||
| **Initial Capacity** | 100 concurrent tournaments | Launch scale |
| **Growth Target** | 10x scaling without re-architecture | 1-year growth headroom |
| **Database** | Supabase managed Postgres | Auto-scaling infrastructure |
| **Storage** | Supabase Storage for PDFs/images | Scalable blob storage |
| **Peak Handling** | Weekend tournament spikes | Most events on Sat/Sun |

---

### Accessibility

| Requirement | Target | Rationale |
| ----------- | ------ | --------- ||
| **Keyboard Navigation** | Full support | Desktop-first, keyboard-heavy scoring |
| **Screen Reader** | Basic ARIA labels | Accessibility compliance |
| **Color Contrast** | WCAG 2.1 AA minimum | Readability |
| **Focus Indicators** | Visible focus states | Keyboard users |
| **Text Resize** | Support up to 200% zoom | Low-vision users |

---

### Integration

| Requirement | Target | Rationale |
| ----------- | ------ | --------- ||
| **API Stability** | Webhook delivery 99%+ | External systems depend on us |
| **Rate Limiting** | Protect against abuse | API security |
| **Timeout Handling** | Graceful degradation | External APIs may be slow |
| **Data Validation** | Strict input validation | Prevent bad data from imports |

---

### Browser Support

| Browser             | Version           | Support Level  |
| ------------------- | ----------------- | -------------- |
| **Chrome**          | Latest 2 versions | Full           |
| **Firefox**         | Latest 2 versions | Full           |
| **Safari**          | Latest 2 versions | Full           |
| **Edge**            | Latest 2 versions | Full           |
| **Mobile Browsers** | Latest versions   | View-only mode |

---

### Localization (Future)

| Requirement          | Target         | Notes                            |
| -------------------- | -------------- | -------------------------------- |
| **Initial Language** | English only   | MVP                              |
| **Architecture**     | i18n-ready     | Prepared for future localization |
| **Date/Time**        | Timezone-aware | Multi-region tournaments         |

