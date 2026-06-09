# Audience Design — Healthcare RTCDP

**Author:** Dr. Tatianna Gilliam  
**Scope:** Segment architecture with consent gates and use case taxonomy

---

## Design Principles

1. **Every segment includes consent gates** — no exceptions.
2. **Clinical segments require clinical authorization** — not just marketing opt-in.
3. **Minimum necessary attributes only** — segments query only fields required for the use case.
4. **Holdout groups for measurable lift** — 10% random holdout where approved.

---

## Segment Taxonomy

| Category | Example Segment | Consent Required | Clinical Data |
|----------|----------------|-----------------|---------------|
| **Care Gap — Screening** | `CareGap_BCS_Outreach` | Clinical authorization | Yes (gap code) |
| **Care Gap — Chronic** | `CareGap_A1C_Adherence` | Clinical authorization | Yes (condition code) |
| **Appointment** | `Appt_Reminder_7d` | Treatment (TPO) | No |
| **Portal Re-Engagement** | `Portal_Dormant_30d` | Marketing email opt-in | No |
| **Service Recovery** | `Call_Escalation_FollowUp` | Service (not marketing) | No |
| **Wellness** | `Wellness_Program_Enroll` | Program authorization | Limited |
| **Suppression** | `Global_Suppression` | N/A — blocks all | No |

---

## Example Segment Definitions

### Care Gap — Breast Cancer Screening

```
Segment: CareGap_BCS_Outreach
Type: Batch (daily, post-EMR ingestion)

Qualification (ALL):
  care.activeCareGaps CONTAINS "BCS"
  care.eligibilityStatus = "active"
  person.gender = "female"
  person.birthDate.age >= 40
  consent.clinicalPrograms.optIn = true
  consent.clinicalPrograms.authorizationExpiry > NOW()
  consent.suppression.global = false
  identityMap.MRN IS NOT EMPTY

Exclusions:
  care.activeCareGaps NOT CONTAINS "BCS_Closed_90d"
  consent.suppression.reason = "grievance"
```

### Portal Re-Engagement (Non-Clinical)

```
Segment: Portal_Dormant_30d
Type: Batch (daily)

Qualification (ALL):
  engagement.portal.lastLoginDate < NOW() - 30 days
  care.eligibilityStatus = "active"
  consent.marketing.email.optIn = true
  consent.suppression.global = false
  identityMap.Email IS NOT EMPTY

Exclusions:
  engagement.portal.loginCount30d > 0
  // No clinical fields queried
```

---

## Consent Gate Template

Every segment MUST include:

```
consent.suppression.global = false
identityMap.[primary namespace] IS NOT EMPTY
[category-specific consent flag] = true
[authorization expiry check if clinical]
```

---

## Related Documents

- [Consent & HIPAA Model](../governance/consent-hipaa-model.md)
- [Activation Architecture](activation-architecture.md)
- [KPI Framework](../business/kpi-framework.md)
