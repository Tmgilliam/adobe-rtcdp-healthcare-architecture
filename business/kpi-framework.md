# KPI Framework — Healthcare RTCDP

**Author:** Dr. Tatianna Gilliam  
**Purpose:** Measurement framework for activation performance, engagement outcomes, data quality, operations, and executive reporting  
**Principle:** Measure trust and outcomes, not just volume

---

## Framework Overview

| Category | Primary Audience | Reporting Cadence |
|----------|-----------------|-------------------|
| Activation KPIs | Marketing Ops, Care Management | Daily / weekly |
| Engagement KPIs | Care Management, Population Health | Weekly / monthly |
| Data Quality KPIs | Data Engineering, Data Steward | Daily |
| Operational KPIs | Platform Ops, Data Engineering | Daily |
| Executive KPIs | CMO, CPO, VP Clinical Operations | Monthly / quarterly |

---

## 1. Activation KPIs

Metrics that measure whether the right audiences reach the right destinations reliably and compliantly.

| KPI | Definition | Target | Data Source | Owner |
|-----|------------|--------|-------------|-------|
| **Audience Match Rate** | Profiles in segment that successfully map to destination identity / % of segment exported | ≥ 92% | AEP Activation Dashboard + destination feedback | Marketing Ops |
| **Activation Latency** | Time from segment qualification to destination receipt (p95) | ≤ 4 hours (batch); ≤ 15 min (streaming) | AEP job logs + destination API timestamps | Data Engineering |
| **Channel Reach** | Unique members successfully activated per channel per week | Baseline + 10% QoQ | Destination delivery reports | Marketing Ops |
| **Activation Success Rate** | Successful activations / total activation attempts per destination | ≥ 95% | AEP activation logs | Data Engineering |
| **Consent-Gated Activation Rate** | Activations blocked by consent enforcement / total attempted | Track (no target — informational) | DUL policy logs | Privacy Officer |
| **Duplicate Activation Rate** | Members receiving same campaign via multiple profiles / total activated | ≤ 0.5% | Post-activation reconciliation job | Data Steward |

### Activation KPI Formulas

```
Audience Match Rate = (Profiles accepted by destination / Profiles in segment export) × 100

Activation Latency (p95) = 95th percentile of (destination_receipt_timestamp - segment_export_timestamp)

Activation Success Rate = (Successful activation jobs / Total activation job attempts) × 100
```

---

## 2. Engagement KPIs

Metrics that measure whether activation drives intended member behavior and care outcomes.

| KPI | Definition | Target | Data Source | Owner |
|-----|------------|--------|-------------|-------|
| **Care Gap Closure Rate** | Closed gaps within 90 days of outreach / gaps targeted | ≥ 15% lift vs. control | EMR care gap reports + segment membership | Population Health |
| **Portal Engagement Lift** | Login rate increase in activated cohort vs. holdout (30-day) | ≥ 8% relative lift | Portal analytics + AEP profile events | Digital Marketing |
| **Appointment Conversion Rate** | Appointments scheduled within 14 days of reminder / reminders sent | ≥ 12% | Scheduling system + AEP events | Care Management |
| **Campaign Response Rate** | Clicks + conversions / deliveries (by channel) | Channel-specific baseline | ESP + AEP event ingestion | Marketing Ops |
| **Call Center Deflection Rate** | Self-service completions / total inbound calls (portal-activated cohort) | ≥ 5% improvement | Call center CDR + portal events | Contact Center Ops |
| **Member Satisfaction (CSAT)** | Post-interaction survey score (activated vs. non-activated) | ≥ 4.0 / 5.0 | Survey platform | Member Experience |

### Engagement Measurement Design

- **Holdout groups:** 10% random holdout for clinical outreach segments (approved by Privacy Officer and IRB if applicable).
- **Attribution window:** 30 days for portal engagement; 90 days for care gap closure.
- **Control for confounders:** Eligibility status, risk score, and prior engagement level as stratification variables.

---

## 3. Data Quality KPIs

Metrics that measure profile trustworthiness — the ERP equivalent of inventory record accuracy.

| KPI | Definition | Target | Data Source | Owner |
|-----|------------|--------|-------------|-------|
| **Profile Completeness Score** | Weighted average of populated required fields across active profiles | ≥ 85% | AEP Data Hygiene Dashboard | Data Steward |
| **Identity Resolution Rate** | Profiles with ≥ 2 linked namespaces / total active profiles | ≥ 78% | AEP Identity Service metrics | Data Engineering |
| **Consent Coverage** | Profiles with all required consent flags captured / total active profiles | ≥ 90% | Profile schema query | Privacy Officer |
| **Identity Conflict Rate** | Unresolved EMPI conflicts / total merge attempts | ≤ 0.5% | EMPI exception queue + AEP merge logs | EMPI Team |
| **Schema Validation Pass Rate** | Records passing schema validation / total ingested | ≥ 99.5% | AEP ingestion monitoring | Data Engineering |
| **Duplicate Profile Rate** | Suspected duplicate profiles / total profiles | ≤ 2% | Reconciliation job vs. member census | Data Steward |
| **Data Freshness Compliance** | Source systems meeting SLA / total monitored sources | 100% | Ingestion timestamp monitoring | Data Engineering |

### Profile Completeness Weighting

| Field Category | Weight | Required Fields |
|----------------|--------|-----------------|
| Identity | 30% | MRN or Member ID, Email or Phone |
| Demographics | 20% | Name, DOB, address |
| Consent | 25% | At least one consent flag with timestamp |
| Care | 15% | Eligibility status, plan type |
| Engagement | 10% | Last login or last contact date |

---

## 4. Operational KPIs

Metrics that measure platform health and pipeline reliability.

| KPI | Definition | Target | Data Source | Owner |
|-----|------------|--------|-------------|-------|
| **Pipeline Latency (Ingestion)** | Time from source export to AEP profile update (p95, by source) | CRM ≤ 24h; Portal ≤ 15min; EMR ≤ 24h | Ingestion job logs | Data Engineering |
| **Ingestion Success Rate** | Successful batch/streaming jobs / total jobs per source | ≥ 99% | AEP Source Connector monitoring | Data Engineering |
| **Schema Validation Pass Rate** | Valid records / total records ingested (daily) | ≥ 99.5% | AEP monitoring | Data Engineering |
| **Segment Evaluation Time** | Time to compute all scheduled segments (p95) | ≤ 2 hours | AEP Segment Job logs | Data Engineering |
| **Activation Job Failure Rate** | Failed activation jobs / total jobs (daily) | ≤ 5% | AEP Activation logs | Marketing Ops |
| **Platform Uptime** | AEP service availability (contractual) | Per Adobe SLA | Adobe status + internal monitoring | Platform Ops |
| **Incident Mean Time to Resolve (MTTR)** | Average time to resolve P1/P2 CDP incidents | P1 ≤ 4h; P2 ≤ 24h | ITSM tickets | Platform Ops |

---

## 5. Executive KPIs

Metrics designed for C-suite and board-level reporting — outcome-oriented, not technical.

| KPI | Definition | Target | Reporting |
|-----|------------|--------|-----------|
| **Member 360 Completeness** | Composite score: identity resolution + profile completeness + consent coverage | ≥ 80% composite | Monthly executive dashboard |
| **Omnichannel Engagement Score** | Weighted composite of portal logins, call center contacts, campaign responses, appointment actions (normalized 0–100) | Baseline + 10% YoY | Quarterly |
| **Care Gap Closure Impact** | Incremental gap closures attributed to CDP outreach vs. baseline trend | Positive ROI vs. outreach cost | Quarterly |
| **Compliance Posture Score** | % of activations passing consent + DUL audit; zero unresolved identity conflicts > 30 days | 100% compliance; 0 unresolved | Monthly (Privacy Officer) |
| **Cost per Activated Member** | Total CDP platform + ops cost / unique members activated (monthly) | Decreasing QoQ | Quarterly |
| **Member Trust Indicator** | Opt-out rate + grievance rate + duplicate outreach complaints (inverse score) | Opt-out ≤ 2%/quarter; zero duplicate outreach | Monthly |

### Executive Dashboard Layout

```
┌─────────────────────────────────────────────────────────────┐
│  MEMBER 360 COMPLETENESS          OMNICHANNEL ENGAGEMENT    │
│  ████████████████░░░░  82%       ██████████████░░░░  71/100 │
├─────────────────────────────────────────────────────────────┤
│  CARE GAP CLOSURE LIFT           COMPLIANCE POSTURE         │
│  +18% vs. control                ████████████████████ 100%  │
├─────────────────────────────────────────────────────────────┤
│  ACTIVATION REACH (by channel)                              │
│  Email: 142K │ SMS: 38K │ Portal: 89K │ Care Mgmt: 12K     │
├─────────────────────────────────────────────────────────────┤
│  RISK FLAGS                                                 │
│  ⚠ EMR freshness: 22h (within SLA)                         │
│  ✓ Identity conflicts: 0.3% (within target)                │
│  ✓ Consent coverage: 91%                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## KPI Governance

| Activity | Frequency | Participants |
|----------|-----------|-------------|
| KPI definition review | Quarterly | Data Steward, Privacy Officer, Marketing Ops |
| Target adjustment | Semi-annual | Executive sponsor + KPI owners |
| Anomaly investigation | Real-time (automated alerts) | KPI owner + Data Engineering |
| Executive report generation | Monthly | Data Steward + PMO |

---

## ERP Parallel

In Sage 100 operations, leadership tracked **inventory accuracy (98%)**, **fill rate (95%)**, and **shipping accuracy (100%)** — not transaction volume. CDP KPIs follow the same discipline: **measure whether the member record is trustworthy and whether outreach drives outcomes**, not how many emails were sent.

---

## Related Documents

- [Business Problem & Stakeholder Map](business-problem-stakeholder-map.md)
- [Failure Mode Analysis](../governance/failure-mode-analysis.md)
- [Activation Architecture](../architecture/activation-architecture.md)
- [Design Decisions](../design-decisions.md)
