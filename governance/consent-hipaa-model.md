# Consent & HIPAA Governance Model — RTCDP Healthcare

**Author:** Dr. Tatianna Gilliam  
**Scope:** Privacy, consent, and regulatory controls for Adobe Experience Platform RTCDP in a HIPAA-covered healthcare environment  
**Audience:** Privacy Officer, GRC, Solutions Architect, Legal

---

## Executive Summary

Using a Customer Data Platform in healthcare is not a marketing decision — it is a **HIPAA compliance architecture decision**. This model defines how consent is captured, stored, enforced, and audited across RTCDP audiences and activations.

The governing principle: **no profile activates without valid identity resolution AND consent appropriate to the use case.** This mirrors ERP shipping controls: no order ships without validated customer record and credit authorization.

---

## 1. HIPAA Privacy Rule Implications for CDP Use Cases

### Covered Entity Context

A health plan or integrated delivery network (IDN) acting as a **covered entity** or **business associate** must evaluate every CDP use case against:

| HIPAA Requirement | CDP Implication |
|-------------------|-----------------|
| **Privacy Rule (45 CFR §164.502)** | PHI may only be used/disclosed for permitted purposes |
| **Minimum Necessary (§164.502(b))** | Only minimum PHI fields required for the purpose enter CDP |
| **Individual Rights (§164.524–528)** | Right of access, amendment, restriction, accounting of disclosures |
| **Administrative Safeguards (§164.308)** | Access controls, audit logs, workforce training |
| **Technical Safeguards (§164.312)** | Encryption, access logging, integrity controls |
| **Business Associate Rule (§164.502(e))** | BAA required with Adobe before PHI ingestion |

### Permitted CDP Use Cases (with Authorization)

| Use Case | HIPAA Basis | Consent Required |
|----------|-------------|-----------------|
| Care gap outreach (clinical) | Treatment / healthcare operations | **HIPAA authorization** or TPO basis (legal review) |
| Appointment reminders | Treatment | Typically TPO; confirm with legal |
| Portal engagement (non-clinical) | Not PHI if de-identified | Marketing consent if promotional |
| Wellness program enrollment | Healthcare operations | Program-specific authorization |
| Member satisfaction survey | Healthcare operations | Optional marketing consent for follow-up |
| Paid media lookalike modeling | **High risk** | Generally **prohibited** with PHI; use de-identified segments only |

### Prohibited / High-Risk Use Cases

- Activating segments with clinical diagnoses to non-HIPAA-compliant destinations (e.g., open web pixels).
- Sharing PHI with Adobe for purposes beyond contracted BAA scope.
- Using call recordings or clinical notes in CDP (never ingest).
- Cross-brand activation where BAA does not cover subsidiary entity.

---

## 2. Consent Capture Points

### Portal Registration / Preference Center

| Consent Type | Capture Method | Stored Field |
|--------------|---------------|--------------|
| Marketing email | Checkbox (unchecked default) | `consent.marketing.email.optIn` |
| Marketing SMS | Checkbox + TCPA disclosure | `consent.marketing.sms.optIn` |
| Clinical program outreach | Separate authorization form | `consent.clinicalPrograms.optIn` |
| Research contact | Optional opt-in | `consent.research.optIn` |

**Requirements:**
- Timestamp and policy version recorded on every capture.
- Pre-checked boxes prohibited for marketing consent (CAN-SPAM / state law alignment).
- Consent withdrawal available in preference center; propagates to profile within 15 minutes (streaming).

### Call Center

| Consent Type | Capture Method | Stored Field |
|--------------|---------------|--------------|
| Marketing email/SMS | Verbal consent script + agent confirmation | `consent.marketing.*` |
| Clinical outreach | Verbal HIPAA authorization script | `consent.clinicalPrograms.optIn` |

**Requirements:**
- Agent must select structured disposition code (not free text) confirming consent read.
- Call ID linked to consent event for audit trail.
- Verbal consent requires supervisor QA sampling (5% minimum).

### In-Person Encounters

| Consent Type | Capture Method | Stored Field |
|--------------|---------------|--------------|
| Clinical program enrollment | Paper or electronic authorization | `consent.clinicalPrograms.optIn` |
| Marketing preferences | Registration form | `consent.marketing.*` |

**Requirements:**
- Paper forms digitized within 48 hours.
- Scanned form reference ID stored in event payload.
- Original forms retained per records retention policy.

---

## 3. Consent Flags in XDM Profile Schema

See [XDM Schema Design](../architecture/xdm-schema-design.md) for full field definitions.

### Consent State Machine

```
                    ┌──────────────┐
                    │   Unknown    │ (no capture yet)
                    └──────┬───────┘
                           │ capture event
                           ▼
              ┌────────────────────────┐
              │  Opted In (timestamp,  │
              │  source, policy ver)   │
              └───────────┬────────────┘
                          │
            ┌─────────────┼─────────────┐
            ▼                           ▼
   ┌────────────────┐          ┌────────────────┐
   │  Opted Out     │          │  Expired       │
   │  (withdrawal)  │          │  (auth expiry) │
   └────────────────┘          └────────────────┘
            │                           │
            └───────────┬───────────────┘
                        ▼
              ┌────────────────┐
              │  Suppressed    │ (global flag)
              └────────────────┘
```

### Suppression Hierarchy

1. `consent.suppression.global = true` → **blocks all activation**
2. `consent.clinicalPrograms.optIn = false` → blocks clinical segments only
3. `consent.marketing.email.optIn = false` → blocks email marketing segments
4. Grievance/legal hold → manual suppression with reason code

---

## 4. Consent Enforcement in Segment Qualification

Every audience definition includes **consent gates** as mandatory AND conditions:

### Example: Care Gap — Breast Cancer Screening

```
Segment: CareGap_BCS_Outreach

Conditions (ALL must be true):
  care.activeCareGaps CONTAINS "BCS"
  care.eligibilityStatus = "active"
  consent.clinicalPrograms.optIn = true
  consent.clinicalPrograms.authorizationExpiry > NOW()
  consent.suppression.global = false
  identityMap.MRN IS NOT EMPTY
```

### Example: Portal Re-Engagement (Non-Clinical)

```
Segment: Portal_Dormant_30d

Conditions (ALL must be true):
  engagement.portal.lastLoginDate < NOW() - 30 days
  consent.marketing.email.optIn = true
  consent.suppression.global = false
  identityMap.Email IS NOT EMPTY
  // NO clinical attributes in this segment
```

### Enforcement Layers

| Layer | Mechanism | Fail Behavior |
|-------|-----------|---------------|
| **Segment definition** | Consent fields in qualification rules | Profile excluded from segment |
| **Data Usage Labels (DUL)** | Policy restricts labeled fields from destination | Field stripped or activation blocked |
| **Destination policy** | Destination configured for consent-aware activation | Batch rejected |
| **Pre-activation audit** | Nightly job validates segment consent coverage | Alert to Privacy Officer |

---

## 5. Data Usage Labels and Policies in RTCDP

### Label Taxonomy

| Label | Meaning | Example Fields |
|-------|---------|---------------|
| `I` | Identity data | MRN, Member ID, Email |
| `I-H` | Identity + HIPAA restricted | MRN + diagnosis codes |
| `C5` | No activation restriction (contractual) | Engagement scores |
| `H` | HIPAA PHI | Clinical attributes, care gaps |
| `M` | Marketing restriction | Requires marketing consent |
| `CL` | Clinical program restriction | Requires clinical authorization |

### Policy Examples

| Policy Name | Rule | Effect |
|-------------|------|--------|
| `HIPAA-Minimum-Necessary` | Fields labeled `H` excluded from marketing destinations | Strip clinical fields |
| `Marketing-Consent-Required` | Fields labeled `M` require `consent.marketing.*.optIn = true` | Block activation |
| `Clinical-Auth-Required` | Fields labeled `CL` require `consent.clinicalPrograms.optIn = true` | Block activation |
| `No-PHI-to-Paid-Media` | Any `H` or `I-H` label → paid media destinations | Block destination entirely |

---

## 6. Minimum Necessary Standard Application

### Field Inclusion Matrix

| Profile Field Category | Include in CDP? | Justification |
|------------------------|----------------|---------------|
| Demographics (name, DOB, address) | Yes | Identity resolution |
| MRN, Member ID | Yes | Identity stitching |
| Care gaps (codes only) | Yes | Care coordination outreach |
| Active conditions (ICD-10) | Conditional | Only if segment requires; consent-gated |
| Medication names | Conditional | Adherence programs only |
| Clinical notes | **No** | Exceeds minimum necessary |
| Lab values | **No** | Exceeds minimum necessary |
| Claim dollar amounts | Conditional | Financial wellness (non-clinical) only |
| Engagement metrics | Yes | Not PHI when properly de-contextualized |

### Review Process

1. **Data Steward** proposes field inclusion with business justification.
2. **Privacy Officer** validates minimum necessary determination.
3. **Legal** reviews for high-risk categories (clinical, financial).
4. **Architecture Review Board** approves schema promotion.

---

## 7. BAA Requirements for Adobe AEP

### Before PHI Ingestion

| Requirement | Status Gate |
|-------------|-------------|
| Execute Adobe HIPAA BAA | Required before Production PHI |
| Confirm AEP region supports HIPAA workload | US-hosted sandbox/production |
| Configure Customer-Managed Keys (CMK) if required | Enterprise agreement |
| Restrict sandbox access to authorized workforce | RBAC + SSO |
| Document subprocessors list | Legal review |

### BAA Scope Boundaries

- PHI processed only within contracted AEP services (Profile, Identity, Segmentation, Activation).
- Adobe Analytics / Target may require separate BAA or be excluded from PHI flows.
- Destinations must be individually assessed — not all activation partners are HIPAA-eligible.

### Ongoing Obligations

- Annual BAA review and subprocessor audit.
- Incident notification within contractual timeframe (typically 24–72 hours).
- Termination: data deletion certification on contract end.

---

## 8. Audit Trail Requirements

### Events to Log

| Event | Log Destination | Retention |
|-------|------------------|-----------|
| Profile created/merged | AEP Audit Log + SIEM | 6 years (HIPAA) |
| Consent captured/changed | Profile event + SIEM | 6 years |
| Segment qualified (profile entered/exited) | AEP Segment Job Log | 6 years |
| Activation sent to destination | Destination audit + SIEM | 6 years |
| Schema changed | AEP Schema Registry audit | 6 years |
| User accessed profile in UI | AEP access log | 6 years |
| DUL policy violation (blocked activation) | SIEM alert | 6 years |

### Accounting of Disclosures

HIPAA requires covered entities to account for certain PHI disclosures. CDP activations to third-party destinations (email service provider, care management vendor) must be:

1. Logged with destination name, date, segment name, and profile identifier.
2. Retrievable for individual member request within 60 days.
3. Excluded from accounting if disclosure is for treatment, payment, or healthcare operations (TPO) — legal must classify each activation type.

### ERP Parallel

In Sage 100 operations, every inventory adjustment required a user ID, timestamp, and reason code. **HIPAA audit trail is the same discipline at higher regulatory stakes.** No activation without traceability.

---

## Related Documents

- [XDM Schema Design](../architecture/xdm-schema-design.md)
- [Failure Mode Analysis](failure-mode-analysis.md)
- [Data Governance Framework](data-governance-framework.md)
- [Audience Design](../architecture/audience-design.md)
