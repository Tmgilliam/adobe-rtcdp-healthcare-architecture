# Business Problem & Stakeholder Map — Healthcare RTCDP

**Author:** Dr. Tatianna Gilliam  
**Scope:** Problem framing, stakeholder alignment, and delivery RACI

---

## Business Problem

A regional health plan / integrated delivery network operates across **five disconnected systems** — CRM, EMR, patient portal, call center, and claims. Each system holds a partial view of the member:

- **Marketing** cannot target care gap outreach because clinical data lives in Epic, not Salesforce.
- **Care management** cannot see digital engagement signals when prioritizing outreach.
- **Compliance** cannot approve activation because consent is captured inconsistently across touchpoints.
- **Members** receive duplicate or conflicting communications from channels that do not share identity.

**Root cause:** There is no governed, unified member profile with identity resolution and consent enforcement. This is not a marketing technology problem — it is a **data unification and trust problem**, identical to fragmented customer records in ERP systems.

---

## Business Impact

| Pain Point | Cost / Risk |
|------------|------------|
| Missed care gap closures | HEDIS measure underperformance; quality bonus at risk |
| Duplicate outreach | Member trust erosion; grievance volume |
| Wrong-member activation | HIPAA violation risk; regulatory penalty |
| Manual list pulls | 40+ hours/month across marketing and care management |
| No attribution | Cannot measure ROI on outreach programs |

---

## Stakeholder Map

| Stakeholder | Role | Primary Interest | Concern | Engagement Strategy |
|-------------|------|-----------------|---------|-------------------|
| **CMO / VP Marketing** | Executive Sponsor | Activation reach, engagement lift | Platform cost, time to value | KPI framework, phased rollout |
| **Chief Privacy Officer** | Governance Authority | HIPAA compliance, consent model | PHI in CDP, BAA scope | Consent architecture, audit trail |
| **VP Clinical Operations** | Business Owner | Care gap closure, population health | Clinical data accuracy | EMR ingestion SLA, holdout measurement |
| **CIO / VP IT** | Technology Authority | Integration feasibility, ops burden | EMR interface stability | Source system architecture, failure modes |
| **Director, Data Engineering** | Implementation Lead | Pipeline reliability, schema quality | Identity conflict volume | XDM design, monitoring KPIs |
| **EMPI Team** | Identity Authority | Golden record accuracy | CDP creating duplicate profiles | Stitching rules, conflict runbooks |
| **Contact Center Director** | Channel Owner | Reduced duplicate calls, service recovery | Agent workflow change | Call center ingestion, disposition mapping |
| **Legal Counsel** | Compliance Advisor | Permitted use cases, BAA | Paid media PHI risk | Use case classification matrix |
| **Member Experience** | Voice of Customer | Consistent, relevant communications | Over-communication | Suppression hierarchy, preference center |

---

## RACI Matrix — Key Deliverables

| Deliverable | CMO | CPO | VP Clinical | CIO | Data Eng | Privacy | Legal |
|-------------|-----|-----|-------------|-----|----------|---------|-------|
| XDM Schema Design | I | C | C | A | R | C | I |
| Consent Model | C | A | C | I | R | R | C |
| Source System Mapping | I | I | C | A | R | C | I |
| Segment Definitions | A | C | C | I | R | C | I |
| Activation Destinations | A | C | I | C | R | C | C |
| BAA Execution | I | C | I | C | I | R | A |
| KPI Framework | A | C | A | I | R | C | I |
| Go-Live Approval | A | A | A | A | R | A | C |

*R = Responsible, A = Accountable, C = Consulted, I = Informed*

---

## Phased Delivery Alignment

| Phase | Stakeholder Value | Primary Sponsor |
|-------|------------------|-----------------|
| Phase 0 — Foundation | Privacy: BAA + sandbox governance | CPO + CIO |
| Phase 1 — Profile Unification | Marketing: non-clinical member 360 | CMO |
| Phase 2 — Clinical Enrichment | Clinical Ops: care gap segments | VP Clinical Ops |
| Phase 3 — Activation | All: measured outreach | CMO + VP Clinical Ops |
| Phase 4 — Optimization | Executive: KPI dashboard, ROI proof | CMO |

---

## ERP Parallel

In Sage 100 operations, the stakeholder map for WMS implementation looked the same: **operations wanted speed, finance wanted accuracy, IT wanted stability, and compliance wanted audit trails.** The CDP stakeholder map inherits the same tension — resolved by phased delivery with governance gates, not by skipping compliance to ship faster.

---

## Related Documents

- [KPI Framework](kpi-framework.md)
- [Design Decisions](../docs/design-decisions.md)
- [Executive Summary — Hiring Manager](../portfolio/executive-summary-hiring-manager.md)
