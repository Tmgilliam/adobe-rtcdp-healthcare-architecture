# Adobe RTCDP — Healthcare Architecture Case Study

**Owner:** Dr. Tatianna Gilliam, DBA | AZ-305 | AI-102 | AZ-104  
**Project:** Enterprise Customer Intelligence & Activation Architecture  
**Platform:** Adobe Experience Platform Real-Time CDP (RTCDP)  
**Vertical:** Healthcare — HIPAA + consent governance + fragmented data unification across CRM, EMR, portal, call center, claims

> **Public repo:** [github.com/Tmgilliam/adobe-rtcdp-healthcare-architecture](https://github.com/Tmgilliam/adobe-rtcdp-healthcare-architecture)  
> **MTP working copy** | Architecture case study demonstrating cross-platform customer data platform design for regulated healthcare environments.  
> Connects ERP-era data integrity discipline (Sage 100, Scanco WMS) to modern XDM governance and identity unification.

---

## Executive Summary

This case study designs a **Real-Time Customer Data Platform (RTCDP)** architecture for a multi-channel healthcare organization that must unify member/patient intelligence across CRM, EMR, patient portal, call center, and claims — while enforcing **HIPAA Privacy Rule** controls, **consent-based activation**, and the **minimum necessary** standard.

The problem is not Adobe-specific. It is the same data unification problem Dr. Gilliam solved in ERP operations: fragmented sources, conflicting identifiers, dirty records, and zero tolerance for activating the wrong entity. RTCDP provides the activation layer; **XDM standardization, identity stitching, and consent enforcement** provide the trust layer.

---

## What This Project Proves (5 Role Dimensions)

| Role Dimension | Evidence in This Repo | Key Artifacts |
|----------------|----------------------|---------------|
| **Software Engineer / Data Scientist** | XDM schema design, event model, identity graph logic | `architecture/xdm-schema-design.md`, `architecture/identity-stitching-flow.md` |
| **Project Manager** | Stakeholder map, phased rollout, delivery artifacts | `business/business-problem-stakeholder-map.md`, `docs/design-decisions.md` |
| **GRC Analyst** | Consent architecture, HIPAA controls, failure modes | `governance/consent-hipaa-model.md`, `governance/failure-mode-analysis.md` |
| **Consultant** | Business framing, KPI framework, executive narrative | `business/kpi-framework.md`, `portfolio/executive-summary-*.md` |
| **Architect** | Source landscape, profile unification, activation design | `architecture/source-system-architecture.md`, `architecture/activation-architecture.md` |

---

## Repository Structure

```
adobe-rtcdp-healthcare-architecture/
├── README.md                          ← You are here
├── architecture/
│   ├── source-system-architecture.md  ← CRM, EMR, portal, call center, claims
│   ├── xdm-schema-design.md           ← Profile + event schemas, field groups, namespaces
│   ├── identity-stitching-flow.md     ← MRN, ECID, member ID resolution
│   ├── audience-design.md             ← Segment logic with consent gates
│   ├── activation-architecture.md     ← Destinations, latency, fallback
│   └── diagrams/
│       └── placeholder.md             ← Mermaid/diagram index
├── governance/
│   ├── consent-hipaa-model.md         ← Privacy Rule, BAA, audit trail
│   ├── failure-mode-analysis.md       ← Identity, consent, freshness, activation failures
│   └── data-governance-framework.md   ← Labels, policies, stewardship
├── business/
│   ├── business-problem-stakeholder-map.md
│   └── kpi-framework.md               ← Activation, engagement, data quality KPIs
├── docs/
│   └── design-decisions.md            ← Architecture Decision Records
└── portfolio/
    ├── executive-summary-recruiter.md
    ├── executive-summary-hiring-manager.md
    ├── interview-talk-track.md        ← 60s / 3min / deep dive
    └── resume-bullets.md              ← 10 role-targeted bullets
```

---

## Source System Landscape

| System | Primary Role | Identity Keys | Ingestion Pattern |
|--------|-------------|---------------|-------------------|
| **CRM** (Salesforce) | Demographics, preferences, care team | Email, phone, member ID | Batch + API |
| **EMR** (Epic) | Clinical encounters, care gaps | MRN, FHIR Patient ID | Batch (HL7/FHIR) |
| **Patient Portal** | Digital engagement, scheduling | ECID, authenticated user ID | Streaming + API |
| **Call Center** | Interaction logs, disposition | Phone, member ID, ANI | Streaming |
| **Claims** | Utilization, coverage | Member ID, subscriber ID | Batch |

See [architecture/source-system-architecture.md](architecture/source-system-architecture.md) for entity-level detail and HIPAA classification.

---

## Architecture Principles

1. **Trust before activation** — No audience qualifies without resolved identity and valid consent for the intended use case.
2. **XDM as system of record for customer intelligence** — Not a copy of EMR; a governed, consent-filtered view for engagement and care coordination marketing.
3. **Minimum necessary by design** — Data usage labels and field-level policies restrict PHI exposure in downstream destinations.
4. **ERP-grade data integrity** — The same discipline applied to Sage 100 master data (one customer record, one truth) maps directly to profile unification and namespace governance.
5. **Failure-aware design** — Identity conflicts, consent drift, and pipeline delays are modeled explicitly, not discovered in production.

---

## Phased Rollout (High Level)

| Phase | Scope | Outcome |
|-------|-------|---------|
| **Phase 0 — Foundation** | BAA, sandbox, XDM schemas, identity namespaces | Governed sandbox with schema validation |
| **Phase 1 — Profile Unification** | CRM + portal + call center ingestion | Operational member 360 (non-clinical) |
| **Phase 2 — Clinical Enrichment** | EMR + claims (minimum necessary fields) | Care gap and utilization audiences |
| **Phase 3 — Activation** | Email, SMS, paid media (consent-gated) | Measured engagement lift |
| **Phase 4 — Optimization** | KPI dashboards, failure mode runbooks | Continuous governance loop |

---

## ERP → Healthcare CDP Parallel

| ERP Challenge (Sage 100 / WMS) | Healthcare CDP Equivalent |
|-------------------------------|---------------------------|
| Duplicate customer records across modules | Multiple MRNs, conflicting member IDs |
| Item master vs. inventory record mismatch | Profile attribute vs. event timestamp conflict |
| Cannot ship without validated ATP | Cannot activate without consent + identity resolution |
| Audit trail for inventory adjustments | HIPAA audit trail for PHI access and activation |
| Scanco barcode ↔ ERP item linkage | ECID ↔ MRN ↔ member ID identity graph |

---

## Certifications & Credentials

**Dr. Tatianna Gilliam, DBA**  
Microsoft Certified: AZ-305 (Azure Solutions Architect Expert) | AI-102 (Azure AI Engineer) | AZ-104 (Azure Administrator)

---

## How to Use This Repo

- **Recruiter screen:** Start with [portfolio/executive-summary-recruiter.md](portfolio/executive-summary-recruiter.md) and [portfolio/interview-talk-track.md](portfolio/interview-talk-track.md) (60-second version).
- **Hiring manager:** [portfolio/executive-summary-hiring-manager.md](portfolio/executive-summary-hiring-manager.md) + architecture folder.
- **Technical panel:** [architecture/xdm-schema-design.md](architecture/xdm-schema-design.md) + [governance/failure-mode-analysis.md](governance/failure-mode-analysis.md).
- **GRC / compliance interview:** [governance/consent-hipaa-model.md](governance/consent-hipaa-model.md) + [governance/data-governance-framework.md](governance/data-governance-framework.md).

---

## Disclaimer

This is an **architecture case study** for portfolio and interview purposes. It does not represent a deployed production implementation or an endorsement by Adobe or any healthcare organization. HIPAA controls, BAA requirements, and consent models should be validated with legal, privacy, and compliance stakeholders before any production deployment.
