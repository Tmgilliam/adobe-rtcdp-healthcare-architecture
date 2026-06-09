# Executive Summary — Hiring Manager Version

**Dr. Tatianna Gilliam, DBA** | Cloud & AI Architect | AZ-305 | AI-102 | AZ-104

---

## Problem Statement

A multi-channel healthcare organization holds member data across CRM (Salesforce), EMR (Epic), patient portal, call center, and claims — with no unified profile, inconsistent identity keys, and consent captured inconsistently across touchpoints. Marketing cannot activate care gap outreach compliantly. Care management cannot see digital engagement. Compliance cannot audit activations.

**This case study architects the solution on Adobe Experience Platform RTCDP** — not as a platform tutorial, but as an enterprise data unification and governance design for a HIPAA-regulated environment.

---

## Architectural Approach

### Layer 1 — Source System Integration

Five source systems mapped with data entities, identity fields, ingestion patterns (batch/streaming/API), data quality risks, and per-field HIPAA classification. Minimum necessary enforced at ingestion — clinical notes, call recordings, and SSN excluded.

### Layer 2 — XDM Profile Unification

Canonical profile schema with custom field groups for consent, care attributes (HEDIS gaps, eligibility, risk tier), and engagement metrics. Event schemas for portal, call center, and clinical triggers. Identity namespace priority: MRN > MemberID > Email > Phone > ECID.

### Layer 3 — Governance & Consent

Consent captured at portal preference center, call center verbal scripts, and in-person authorization forms. Every segment includes mandatory consent gates. Data usage labels block PHI from non-HIPAA destinations. BAA required before production PHI ingestion. Six-year audit trail.

### Layer 4 — Activation & Measurement

Consent-gated activation to email, SMS, care management, portal, and contact center destinations. Paid media blocked from PHI. KPI framework measures care gap closure lift, profile completeness, identity resolution rate, and compliance posture — not email volume.

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| MRN as primary identity namespace | Clinically authoritative; EMPI governs conflicts |
| No auto-merge on identity conflict | Wrong merge = HIPAA incident |
| Consent gates in every segment | Fail-safe compliance |
| Minimum necessary at ingestion | Reduces breach blast radius |
| Phased rollout (non-clinical first) | Proves platform while governance matures |
| ERP-grade schema change control | Production stability over iteration speed |

Full ADRs in `docs/design-decisions.md`.

---

## Failure Mode Awareness

This architecture documents what breaks — not just what works:

- **Identity stitching failure:** Multiple MRNs → flag, suppress, EMPI review
- **Consent conflict:** Most restrictive wins → Privacy Officer queue
- **EMR data stale:** Pause clinical activations at 26h threshold
- **Activation failure:** Retry with backoff; clinical fallback to care manager
- **Schema evolution:** Version policy with rollback; change freeze during activations

---

## Phased Delivery

| Phase | Scope | Timeline (Indicative) |
|-------|-------|----------------------|
| 0 — Foundation | BAA, sandbox, schemas, namespaces | 6–8 weeks |
| 1 — Profile Unification | CRM + portal + call center | 8–10 weeks |
| 2 — Clinical Enrichment | EMR + claims (minimum necessary) | 10–12 weeks |
| 3 — Activation | Consent-gated destinations | 6–8 weeks |
| 4 — Optimization | KPI dashboards, runbooks | Ongoing |

---

## Why Dr. Gilliam — ERP → Healthcare CDP

| ERP Discipline (Sage 100 / Scanco WMS) | Healthcare CDP Equivalent |
|---------------------------------------|---------------------------|
| 98% inventory record accuracy | Profile completeness ≥ 85% |
| One customer master record | One unified member profile |
| Validated before shipping | Consent + identity validated before activation |
| Warehouse zone access controls | Data usage labels and DUL policies |
| Audit trail for adjustments | HIPAA audit trail for PHI access |

She did not learn data governance from a certification course. She managed it under operational SLA pressure in manufacturing ERP — where duplicate records stopped the pick line. Healthcare activation has the same failure mode at higher regulatory stakes.

---

## What to Review in Interview

1. `architecture/xdm-schema-design.md` — schema and namespace decisions
2. `governance/consent-hipaa-model.md` — compliance architecture
3. `governance/failure-mode-analysis.md` — operational maturity
4. `portfolio/interview-talk-track.md` — 3-minute walkthrough
5. `docs/design-decisions.md` — trade-off reasoning

---

## Certifications

AZ-305 (Azure Solutions Architect Expert) | AI-102 (Azure AI Engineer) | AZ-104 (Azure Administrator)

Cloud-agnostic architect — Azure credentialed, Adobe RTCDP as case study platform, designs transfer to Segment, Salesforce CDP, or mParticle.
