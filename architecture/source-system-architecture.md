# Source System Architecture — Healthcare RTCDP Landscape

**Author:** Dr. Tatianna Gilliam  
**Scope:** Upstream data sources feeding Adobe Experience Platform Real-Time CDP  
**Context:** Multi-channel health plan / integrated delivery network (IDN) with CRM, clinical, digital, contact center, and payer data

---

## Overview

Healthcare customer intelligence requires unifying **five fragmented source systems**, each with different identity keys, refresh cadences, and HIPAA sensitivity levels. This document defines what each system contributes, how it ingests into AEP, and where data quality risk enters the pipeline.

The unification problem mirrors ERP master data management: in Sage 100 operations, a customer existed in sales, AR, and shipping with slightly different names and IDs. Here, a member exists as a CRM contact, an EMR patient, a portal user, a call center caller, and a claims subscriber. **RTCDP does not create truth — it enforces a governed view of truth once identity and consent are resolved.**

---

## Source System Summary

| Source | Vendor (Reference) | Primary Consumers | Default Ingestion | Refresh SLA |
|--------|---------------------|-------------------|-------------------|---------------|
| CRM | Salesforce Health Cloud | Marketing, care coordination | Batch + REST API | Daily + near-real-time API |
| EMR | Epic (Hyperspace / MyChart) | Clinical programs, care management | Batch (HL7 v2 / FHIR R4) | Nightly + intra-day for ADT |
| Patient Portal | MyChart / custom portal | Digital engagement, scheduling | Streaming (Web SDK) + API | Real-time events |
| Call Center | Genesys / Five9 / NICE | Service recovery, outreach | Streaming + batch CDR | Real-time + daily reconciliation |
| Claims | Payer core / clearinghouse | Utilization, risk stratification | Batch (EDI 837/835) | Weekly to daily |

---

## 1. CRM (Salesforce Health Cloud or Equivalent)

### Data Entities Available

| Entity | Key Attributes | Business Use |
|--------|---------------|--------------|
| **Contact / Member** | Name, DOB, gender, address, preferred language | Demographic foundation for profile |
| **Account / Household** | Family grouping, primary subscriber | Household-level engagement |
| **Care Team Assignment** | PCP, care manager, specialist roster | Care coordination audiences |
| **Communication Preferences** | Channel opt-in, frequency, topic preferences | Consent and preference enforcement |
| **Case / Service Request** | Case type, status, resolution | Service recovery triggers |
| **Campaign Member** | Campaign response history | Attribution and suppression |

### Identity Fields Present

| Field | Namespace Candidate | Notes |
|-------|---------------------|-------|
| Salesforce Contact ID | Custom: `CRMContactID` | System-specific; not portable |
| Member ID / Subscriber ID | Custom: `MemberID` | Primary payer/plan identifier |
| Email | Email | Often shared across household |
| Phone (mobile, home) | Phone | Formatting inconsistencies common |
| MRN (if synced from EMR) | Custom: `MRN` | May lag EMR; not authoritative |

### Data Quality Challenges

- **Stale demographics** — Address and phone updates often lag portal or call center.
- **Duplicate contacts** — Manual entry creates near-duplicate records (same member, different spellings).
- **Preference vs. consent conflation** — Marketing opt-in stored separately from HIPAA authorization; must not be treated as equivalent.
- **Care team assignment drift** — PCP changes in EMR may not sync to CRM same-day.

### Ingestion Pattern

| Pattern | Use Case | AEP Connector |
|---------|----------|---------------|
| **Batch (scheduled)** | Nightly full/incremental contact sync | Salesforce Source Connector |
| **API (event-driven)** | Case creation, preference updates | Streaming via middleware or S3 landing |
| **Streaming (limited)** | Platform Events for high-priority updates | Kafka / Event Hub → AEP streaming ingestion |

### HIPAA Classification

| Data Element | PHI? | Minimum Necessary for CDP? |
|--------------|------|---------------------------|
| Name, DOB, address | Yes | Yes — identity resolution |
| Member ID | Yes (when linked to health info) | Yes — primary stitch key |
| Care team names | Limited PHI | Yes — care coordination context |
| Case notes (free text) | Yes | **No** — exclude from CDP |
| Campaign response | Depends on linkage | Yes — engagement events only |

---

## 2. EMR (Epic or Equivalent)

### Data Entities Available

| Entity | Key Attributes | Business Use |
|--------|---------------|--------------|
| **Patient Demographics** | MRN, name, DOB, sex, address | Authoritative clinical identity |
| **Encounters** | Visit type, date, department, provider | Engagement and care gap context |
| **Diagnoses (Problem List)** | ICD-10 codes, onset date | Condition-based audiences (consent-gated) |
| **Medications (Active)** | RxNorm codes, fill status | Adherence programs |
| **Orders / Results** | Lab, imaging flags | Preventive care reminders |
| **Care Gaps** | HEDIS measure gaps, overdue screenings | Population health activation |
| **ADT Events** | Admit, discharge, transfer | High-priority outreach triggers |

### Identity Fields Present

| Field | Namespace Candidate | Notes |
|-------|---------------------|-------|
| MRN (Medical Record Number) | Custom: `MRN` | Authoritative within health system |
| FHIR Patient ID | Custom: `FHIRPatientID` | Interoperability standard |
| Enterprise Master Patient Index (EMPI) ID | Custom: `EMPIID` | Cross-facility resolution |
| Epic MyChart ID | Custom: `MyChartID` | Links to portal |
| SSN (if present) | **Excluded** | Never ingest to CDP |

### Data Quality Challenges

- **Multiple MRNs per patient** — Merger/acquisition, registration errors, alias records.
- **Coding latency** — Diagnoses coded post-encounter; care gap flags may lag 24–72 hours.
- **Historical vs. active conditions** — Problem list includes resolved conditions; segment logic must filter by status.
- **Facility-specific MRNs** — Multi-site systems may issue different MRNs until EMPI reconciliation runs.

### Ingestion Pattern

| Pattern | Use Case | AEP Connector |
|---------|----------|---------------|
| **Batch (nightly)** | Problem list, medications, care gaps | S3 / Azure Blob → batch ingestion |
| **Batch (HL7 ADT)** | Admit/discharge events | Middleware normalizes to XDM events |
| **FHIR Bulk Export** | Periodic full patient resource export | Batch with incremental timestamps |
| **Streaming (limited)** | ADT for time-sensitive outreach | HL7 → Kafka → AEP streaming |

**Note:** Clinical data ingestion requires explicit **minimum necessary** field selection. Full clinical documents (notes, imaging reports) are excluded.

### HIPAA Classification

| Data Element | PHI? | Minimum Necessary for CDP? |
|--------------|------|---------------------------|
| MRN, demographics | Yes | Yes — identity (authoritative) |
| ICD-10 diagnoses | Yes | Conditional — condition segments only |
| Medication names | Yes | Conditional — adherence programs only |
| Provider names | Yes | Limited — care team context |
| Clinical notes | Yes | **No** — never ingest |
| Encounter dates/types | Yes | Yes — engagement timing |

---

## 3. Patient Portal (MyChart / Custom Portal)

### Data Entities Available

| Entity | Key Attributes | Business Use |
|--------|---------------|--------------|
| **Authenticated Sessions** | Login, session duration, device | Engagement scoring |
| **Appointment Actions** | Scheduled, cancelled, completed, no-show | Conversion audiences |
| **Secure Messages** | Sent/received (metadata only, not content) | Engagement depth signal |
| **Content Consumption** | Article views, video completions, program enrollments | Education program targeting |
| **Bill Pay / Financial** | Payment actions (metadata) | Financial wellness (non-clinical) |
| **Preference Center** | Consent capture, channel preferences | **Authoritative consent source** |

### Identity Fields Present

| Field | Namespace Candidate | Notes |
|-------|---------------------|-------|
| ECID (Experience Cloud ID) | ECID | Anonymous → known transition |
| Authenticated User ID | Custom: `PortalUserID` | Links to MyChart ID |
| Email | Email | Verified at registration |
| MRN (post-authentication) | Custom: `MRN` | Stitched on login event |

### Data Quality Challenges

- **Anonymous traffic** — Pre-login behavior lacks MRN; requires ECID → authenticated stitch.
- **Shared devices** — Household members on same browser; ECID conflation risk.
- **Consent version tracking** — Policy updates require re-consent; stale flags invalidate segments.
- **Bot / crawler traffic** | Inflated page view metrics; requires bot filtering.

### Ingestion Pattern

| Pattern | Use Case | AEP Connector |
|---------|----------|---------------|
| **Streaming (Web SDK / Mobile SDK)** | Page views, clicks, form submissions | AEP Web SDK → Edge Network → RTCDP |
| **API (server-side)** | Appointment confirmations, consent updates | HTTP API source or middleware |
| **Batch (reconciliation)** | Session summaries, aggregated engagement scores | Nightly batch |

### HIPAA Classification

| Data Element | PHI? | Minimum Necessary for CDP? |
|--------------|------|---------------------------|
| ECID (anonymous) | No | Yes — pre-authentication tracking |
| Page URL (health topic) | Potentially | Yes — with DUL restrictions |
| Message metadata (not content) | Limited | Yes — engagement signal |
| Message body content | Yes | **No** — never ingest |
| Consent records | Not PHI alone | Yes — governance requirement |

---

## 4. Call Center

### Data Entities Available

| Entity | Key Attributes | Business Use |
|--------|---------------|--------------|
| **Interaction Log** | Call ID, timestamp, duration, direction | Engagement history |
| **ANI / DNIS** | Calling number, dialed number | Identity resolution (phone stitch) |
| **IVR Path** | Menu selections, self-service completion | Intent signals |
| **Agent Disposition** | Resolved, escalated, callback scheduled | Service recovery triggers |
| **Wrap-Up Codes** | Reason for call, topic category | Topic-based segmentation |
| **Quality Flags** | Complaint, grievance, HIPAA verification status | Suppression and escalation |

### Identity Fields Present

| Field | Namespace Candidate | Notes |
|-------|---------------------|-------|
| ANI (Automatic Number Identification) | Phone | May not match CRM format |
| Member ID (IVR capture / agent entry) | Custom: `MemberID` | Self-reported; validation required |
| MRN (agent lookup) | Custom: `MRN` | Authoritative when verified via EMR |
| Email (agent capture) | Email | Secondary verification |

### Data Quality Challenges

- **Phone number mismatch** — CRM stores `(555) 123-4567`; ANI arrives as `5551234567`.
- **Caller ≠ member** — Spouse or caregiver calling on behalf of member; identity attribution error.
- **Incomplete wrap-up** — Agents skip disposition codes under volume pressure.
- **Consent capture inconsistency** — Verbal consent not always recorded in structured fields.

### Ingestion Pattern

| Pattern | Use Case | AEP Connector |
|---------|----------|---------------|
| **Streaming** | Live call events for real-time routing context | Contact center connector / Kafka |
| **Batch (CDR)** | Daily call detail record reconciliation | S3 batch ingestion |
| **API** | Post-call disposition updates | REST middleware |

### HIPAA Classification

| Data Element | PHI? | Minimum Necessary for CDP? |
|--------------|------|---------------------------|
| Call recording | Yes | **No** — exclude audio |
| ANI / phone | Yes (when linked) | Yes — identity stitch |
| Disposition codes | Limited | Yes — engagement events |
| Call transcript | Yes | **No** — never ingest |
| Verbal consent flag | Not PHI alone | Yes — governance requirement |

---

## 5. Claims (Payer Core / Clearinghouse)

### Data Entities Available

| Entity | Key Attributes | Business Use |
|--------|---------------|--------------|
| **Member Eligibility** | Plan type, effective dates, PCP assignment | Coverage-aware audiences |
| **Medical Claims** | CPT/HCPCS, diagnosis codes, paid amount | Utilization patterns |
| **Pharmacy Claims** | NDC codes, days supply, refill count | Medication adherence |
| **Prior Authorization** | Service requested, approval/denial | Care navigation triggers |
| **EOB / Accumulators** | Deductible status, OOP max | Financial wellness (non-clinical) |

### Identity Fields Present

| Field | Namespace Candidate | Notes |
|-------|---------------------|-------|
| Member ID | Custom: `MemberID` | Primary payer identifier |
| Subscriber ID | Custom: `SubscriberID` | Family linkage |
| Group Number | Custom: `GroupNumber` | Employer-sponsored plan context |
| MRN (if linked by plan) | Custom: `MRN` | Cross-system stitch (when available) |

### Data Quality Challenges

- **Claim lag** — 30–90 day processing delay; not suitable for real-time clinical triggers alone.
- **Member ID reissuance** — Plan year changes may issue new IDs for same member.
- **Coordination of benefits** — Multiple payers; duplicate claim lines.
- **Code specificity** — ICD-10 on claims may differ from EMR problem list.

### Ingestion Pattern

| Pattern | Use Case | AEP Connector |
|---------|----------|---------------|
| **Batch (primary)** | Weekly/daily claim extracts | S3 / SFTP → batch ingestion |
| **Batch (eligibility)** | Daily eligibility file | Batch with effective date logic |
| **Streaming** | Not typical for claims | N/A for most payer integrations |

### HIPAA Classification

| Data Element | PHI? | Minimum Necessary for CDP? |
|--------------|------|---------------------------|
| Member ID | Yes (when linked) | Yes — identity stitch |
| Diagnosis/procedure codes | Yes | Conditional — utilization segments |
| Provider NPI on claim | Yes | Limited — network context |
| Claim dollar amounts | Yes | Conditional — financial wellness only |
| Free-text remark codes | Potentially | **No** — exclude unstructured |

---

## Cross-System Identity Matrix

| Identity Key | CRM | EMR | Portal | Call Center | Claims | Authoritative Source |
|--------------|-----|-----|--------|-------------|--------|---------------------|
| MRN | Synced | **Primary** | Post-auth | Agent lookup | Linked | EMR |
| Member ID | Yes | Limited | Yes | IVR/agent | **Primary** | Claims / CRM |
| Email | Yes | Limited | **Verified** | Agent capture | No | Portal (verified) |
| Phone | Yes | Limited | Optional | **ANI** | No | Call center (ANI) + CRM |
| ECID | No | No | **Primary (anon)** | No | No | Portal |

---

## Ingestion Architecture (Logical)

```
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────┐  ┌─────────┐
│   CRM   │  │   EMR   │  │ Portal  │  │ Call Center │  │ Claims  │
│ (Batch) │  │ (Batch) │  │(Stream) │  │ (Stream+Batch)│ │ (Batch) │
└────┬────┘  └────┬────┘  └────┬────┘  └──────┬──────┘  └────┬────┘
     │            │            │              │              │
     └────────────┴────────────┴──────────────┴──────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Integration Layer │
                    │  (Normalize, DUL,  │
                    │   consent flags)   │
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │ Adobe Experience   │
                    │ Platform (AEP)     │
                    │ Profile + Identity │
                    └───────────────────┘
```

---

## ERP Parallel — Why This Matters

In Sage 100 ERP operations, shipping an order to the wrong customer was a **trust failure**, not a technology failure. The root cause was always the same: duplicate customer records, inconsistent item IDs, and modules that did not share a single master key.

Healthcare RTCDP inherits the identical failure mode. Activating a care gap reminder to the wrong member is a HIPAA incident, not a marketing miss. **Source system architecture is where trust is won or lost** — before XDM, before segments, before activation.

---

## Related Documents

- [XDM Schema Design](xdm-schema-design.md)
- [Identity Stitching Flow](identity-stitching-flow.md)
- [Consent & HIPAA Model](../governance/consent-hipaa-model.md)
- [Failure Mode Analysis](../governance/failure-mode-analysis.md)
