# XDM Schema Design — Unified Healthcare Profile

**Author:** Dr. Tatianna Gilliam  
**Platform:** Adobe Experience Platform (AEP) / Real-Time CDP  
**Standard:** Experience Data Model (XDM) 2.0

---

## Purpose

This document defines the **XDM schema architecture** for a healthcare organization's unified customer profile in RTCDP. XDM standardization is the contract between fragmented source systems (CRM, EMR, portal, call center, claims) and downstream activation destinations.

**Why XDM matters in healthcare:** Without a canonical model, each source system defines "member" differently — CRM has a contact, EMR has a patient, claims has a subscriber. XDM forces a **single profile schema** with governed field groups, typed attributes, and identity namespaces. This is the same discipline applied to ERP item master governance: one record structure, enforced validation, auditable changes.

---

## Schema Architecture Overview

| Schema Class | XDM Base Class | Primary Use |
|--------------|---------------|-------------|
| **Healthcare Member Profile** | `XDM Individual Profile` | Unified member 360 |
| **Healthcare Engagement Event** | `XDM ExperienceEvent` | Behavioral and interaction events |
| **Healthcare Clinical Event** | `XDM ExperienceEvent` (restricted) | Clinical triggers (consent-gated) |

---

## 1. Profile Schema — Healthcare Member Profile

**Schema Title:** `HealthcareMemberProfilev1`  
**Base Mixin:** `XDM Individual Profile`  
**Profile Enabled:** Yes

### Core Identity Fields

| Field Path | Type | Source of Truth | Identity Namespace |
|------------|------|-----------------|-------------------|
| `_id` | String | AEP-generated | Profile ID |
| `identityMap.MRN` | Array | EMR | `MRN` (primary) |
| `identityMap.MemberID` | Array | Claims / CRM | `MemberID` |
| `identityMap.Email` | Array | Portal (verified) | Email |
| `identityMap.Phone` | Array | CRM / Call Center | Phone |
| `identityMap.ECID` | Array | Portal (Web SDK) | ECID |

### Demographic Attributes

| Field Path | Type | Field Group | Notes |
|------------|------|-------------|-------|
| `person.name.firstName` | String | Demographic Details | Standard XDM |
| `person.name.lastName` | String | Demographic Details | Standard XDM |
| `person.birthDate` | Date | Demographic Details | Used in identity verification |
| `person.gender` | Enum | Demographic Details | Optional; consent-dependent use |
| `homeAddress.*` | Object | Demographic Details | Standard XDM address |
| `personalEmail.address` | String | Demographic Details | May differ from identityMap |
| `mobilePhone.number` | String | Demographic Details | E.164 normalized |

### Consent Flags (Custom Field Group)

**Field Group:** `healthcareConsentPreferences`

| Field Path | Type | Description |
|------------|------|-------------|
| `consent.marketing.email.optIn` | Boolean | Marketing email consent |
| `consent.marketing.email.optInTimestamp` | DateTime | When consent captured |
| `consent.marketing.email.optInSource` | Enum | `portal`, `call_center`, `in_person`, `paper` |
| `consent.marketing.sms.optIn` | Boolean | SMS marketing consent |
| `consent.marketing.sms.optInTimestamp` | DateTime | TCPA-aligned timestamp |
| `consent.clinicalPrograms.optIn` | Boolean | Care gap / clinical outreach consent |
| `consent.clinicalPrograms.optInTimestamp` | DateTime | HIPAA authorization timestamp |
| `consent.clinicalPrograms.authorizationExpiry` | DateTime | Authorization end date |
| `consent.research.optIn` | Boolean | Research contact consent |
| `consent.policyVersion` | String | Consent policy version accepted |
| `consent.suppression.global` | Boolean | Master suppression flag |
| `consent.suppression.reason` | Enum | `grievance`, `legal_hold`, `member_request` |

### Care Attributes (Custom Field Group)

**Field Group:** `healthcareCareAttributes`

| Field Path | Type | Description |
|------------|------|-------------|
| `care.primaryCareProvider.npi` | String | PCP National Provider Identifier |
| `care.primaryCareProvider.name` | String | PCP display name |
| `care.careManager.assigned` | Boolean | Active care management enrollment |
| `care.careManager.id` | String | Care manager CRM ID |
| `care.planType` | Enum | `HMO`, `PPO`, `Medicare_Advantage`, `Medicaid`, `Self_Pay` |
| `care.eligibilityStatus` | Enum | `active`, `terminated`, `pending` |
| `care.eligibilityEffectiveDate` | Date | Coverage start |
| `care.riskScore` | Number | Population health risk tier (1–5) |
| `care.activeCareGaps` | Array[String] | HEDIS gap codes (e.g., `BCS`, `COL`, `A1C`) |
| `care.activeConditions` | Array[String] | ICD-10 codes (consent-gated segment use) |
| `care.lastEncounterDate` | Date | Most recent clinical encounter |
| `care.lastEncounterType` | Enum | `inpatient`, `outpatient`, `telehealth`, `ED` |

### Engagement Attributes (Custom Field Group)

**Field Group:** `healthcareEngagementAttributes`

| Field Path | Type | Description |
|------------|------|-------------|
| `engagement.portal.lastLoginDate` | DateTime | Last authenticated portal session |
| `engagement.portal.loginCount30d` | Integer | Rolling 30-day login count |
| `engagement.portal.preferredChannel` | Enum | `email`, `sms`, `portal`, `phone` |
| `engagement.callCenter.lastContactDate` | DateTime | Last inbound/outbound call |
| `engagement.callCenter.contactCount90d` | Integer | Rolling 90-day contact count |
| `engagement.lastCampaignResponse` | DateTime | Last marketing response |
| `engagement.engagementScore` | Number | Composite score (0–100) |
| `engagement.member360Completeness` | Number | Profile completeness percentage |

---

## 2. Event Schema — Healthcare Engagement Event

**Schema Title:** `HealthcareEngagementEventv1`  
**Base Class:** `XDM ExperienceEvent`  
**Time Series:** Yes

### Standard Event Fields

| Field Path | Type | Description |
|------------|------|-------------|
| `timestamp` | DateTime | Event occurrence time |
| `_experience.analytics.event1to100.event101.value` | Integer | Custom event type code |
| `eventType` | String | Human-readable event name |

### Event Types

| Event Type | `eventType` Value | Source | Key Payload Fields |
|------------|-------------------|--------|-------------------|
| Portal page view | `portal.pageView` | Web SDK | `web.webPageDetails.URL`, content category |
| Portal login | `portal.login` | Web SDK | Authentication method, device |
| Appointment scheduled | `portal.appointmentScheduled` | API | Appointment ID, department, date |
| Appointment cancelled | `portal.appointmentCancelled` | API | Appointment ID, cancellation reason |
| Call inbound | `call.inbound` | Call center | ANI, IVR path, duration |
| Call outbound | `call.outbound` | Call center | Disposition code, wrap-up |
| Campaign click | `campaign.click` | Email platform | Campaign ID, link URL |
| Campaign open | `campaign.open` | Email platform | Campaign ID |
| Consent updated | `consent.updated` | Portal / call center | Consent type, new value, source |

### Custom Event Payload (Field Group: `healthcareEventDetails`)

| Field Path | Type | Description |
|------------|------|-------------|
| `healthcare.appointmentId` | String | Scheduling system reference |
| `healthcare.appointmentDepartment` | String | Department/specialty |
| `healthcare.callDisposition` | Enum | `resolved`, `escalated`, `callback`, `abandoned` |
| `healthcare.callTopic` | String | Wrap-up topic category |
| `healthcare.campaignId` | String | Campaign identifier |
| `healthcare.consentType` | Enum | Which consent flag changed |
| `healthcare.consentNewValue` | Boolean | New consent state |
| `healthcare.contentCategory` | String | Portal content taxonomy |

---

## 3. Event Schema — Healthcare Clinical Event (Restricted)

**Schema Title:** `HealthcareClinicalEventv1`  
**Base Class:** `XDM ExperienceEvent`  
**Data Usage Label:** `I1-H` (Identity + HIPAA restricted)

### Event Types

| Event Type | Source | Minimum Necessary Payload |
|------------|--------|----------------------------|
| Care gap identified | EMR batch | Gap code, identification date |
| Encounter completed | EMR ADT | Encounter type, date (no clinical detail) |
| Medication refill due | Pharmacy | NDC code, days until due |
| Preventive screening overdue | EMR | Screening type code only |

**Excluded from all clinical events:** Clinical notes, free-text diagnoses, lab values, imaging results.

---

## 4. Profile ↔ Event Relationship

```
┌─────────────────────────────────────────────────────────────┐
│                 HealthcareMemberProfilev1                    │
│  identityMap: MRN, MemberID, Email, Phone, ECID             │
│  consent.*, care.*, engagement.*                            │
└──────────────────────────┬──────────────────────────────────┘
                           │ identityMap match
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
│ Engagement Event │ │ Engagement   │ │ Clinical Event   │
│ portal.pageView  │ │ Event        │ │ careGapIdentified│
│ portal.login     │ │ call.inbound │ │ (consent-gated)  │
└──────────────────┘ └──────────────┘ └──────────────────┘
```

**Relationship rules:**

1. Events reference profile via **shared identity namespaces** — not foreign keys.
2. Profile attributes are **computed from events** where appropriate (e.g., `engagement.portal.loginCount30d` updated by scheduled query or streaming aggregation).
3. Clinical events update profile care attributes (`care.activeCareGaps`) via batch enrichment — not real-time streaming from EMR.
4. Consent events (`consent.updated`) immediately update profile consent flags — **real-time enforcement**.

---

## 5. Custom Field Groups — Healthcare-Specific

| Field Group Name | Applies To | Purpose |
|-----------------|-----------|---------|
| `healthcareConsentPreferences` | Profile | Consent and suppression flags |
| `healthcareCareAttributes` | Profile | Clinical and plan context (minimum necessary) |
| `healthcareEngagementAttributes` | Profile | Derived engagement metrics |
| `healthcareEventDetails` | ExperienceEvent | Event-specific healthcare payload |
| `healthcareClinicalEventDetails` | Clinical Event | Restricted clinical trigger payload |

**Governance rule:** Custom field groups require Data Steward approval before schema promotion to Production. Same change-control discipline as ERP custom field additions to Sage 100.

---

## 6. Identity Namespace Strategy

| Namespace | Code | Type | Priority | Primary Source | Stitch Logic |
|-----------|------|------|----------|---------------|--------------|
| MRN | `MRN` | Cross-device | 1 (highest) | EMR | Authoritative clinical ID |
| Member ID | `MemberID` | Cross-device | 2 | Claims / CRM | Payer/plan identifier |
| Email | `Email` | Cross-device | 3 | Portal (verified) | Exact match, lowercase |
| Phone | `Phone` | Cross-device | 4 | CRM / Call Center | E.164 normalized |
| ECID | `ECID` | Device | 5 | Portal Web SDK | Anonymous; upgraded on auth |

### Stitching Rules

1. **ECID → MRN:** On portal login, authenticated MRN is appended to ECID profile; graphs merge per AEP Identity Service rules.
2. **Phone → Member ID:** Call center ANI matched to CRM phone; Member ID from IVR or agent lookup confirms stitch.
3. **Member ID → MRN:** Claims-to-EMR crosswalk table (maintained by EMPI team) provides MRN when available.
4. **Conflict resolution:** When two MRNs map to one Member ID, flag for EMPI review; do not auto-merge (see [Failure Mode Analysis](../governance/failure-mode-analysis.md)).

### Namespace Governance

- Namespaces are registered in AEP Identity Service before any ingestion.
- Priority order determines graph merge behavior — MRN wins over Member ID wins over Email.
- **Never use SSN as a namespace.**

---

## 7. Why XDM Standardization Matters

### Problem: Fragmented Healthcare Data

Without XDM, each integration team builds ad hoc JSON payloads. CRM sends `member_id`; EMR sends `MRN`; portal sends `userId`. Segments cannot reliably query across sources. Activation destinations receive inconsistent field names and untyped values.

### Solution: XDM as Contract

| Benefit | ERP Parallel (Sage 100) |
|---------|------------------------|
| Typed, validated fields | Item master UOM validation |
| Reusable field groups | Standard product categories |
| Identity namespace registry | Customer number vs. ship-to ID governance |
| Schema versioning | ERP module upgrade compatibility |
| Data usage labels | Warehouse zone access controls |
| Segment portability | Report definition reuse across modules |

### Business Outcome

- **Segment builders** query consistent field paths (`care.activeCareGaps`, not five different source field names).
- **Activation destinations** receive governed payloads with DUL enforcement.
- **Compliance teams** audit schema changes, not individual integration mappings.
- **New source systems** onboard by mapping to existing field groups — not rebuilding the profile model.

---

## Schema Versioning Policy

| Change Type | Version Impact | Approval Required |
|-------------|---------------|-------------------|
| New optional field in existing group | Minor (v1 → v1.1) | Data Steward |
| New field group | Minor | Data Steward + Privacy Officer |
| New required field | Major (v1 → v2) | Architecture Review Board |
| Identity namespace change | Major | Architecture Review Board + EMPI team |
| Consent field change | Major | Privacy Officer + Legal |

Existing activations continue on prior schema version until explicitly migrated — preventing breaking changes to downstream destinations.

---

## Related Documents

- [Source System Architecture](source-system-architecture.md)
- [Identity Stitching Flow](identity-stitching-flow.md)
- [Consent & HIPAA Model](../governance/consent-hipaa-model.md)
- [Audience Design](audience-design.md)
