# Activation Architecture — Healthcare RTCDP

**Author:** Dr. Tatianna Gilliam  
**Scope:** Destination design, latency requirements, payload governance, and fallback behavior

---

## Activation Layer Overview

Activation is the **last mile** — exporting qualified segment members to downstream destinations for outreach. In healthcare, activation is also the **highest compliance risk** — PHI leaves the governed AEP boundary.

```
Segment Qualified → DUL Policy Check → Payload Mapping → Destination Export → Delivery Confirmation
```

Every step is logged for HIPAA audit trail.

---

## Destination Catalog

| Destination | Use Case | HIPAA Eligible | Consent Required | Latency |
|-------------|----------|---------------|-----------------|---------|
| **Email ESP** (e.g., SFMC) | Care gap, portal re-engagement, appointment reminders | Yes (with BAA) | Marketing or clinical | Batch ≤ 4h |
| **SMS Gateway** | Appointment reminders, urgent care gap | Yes (with BAA) | SMS opt-in (TCPA) | Streaming ≤ 15min |
| **Care Management Platform** | High-risk member outreach, care manager assignment | Yes | Clinical authorization | Batch ≤ 4h |
| **Patient Portal (in-app)** | Notifications, content recommendations | Yes (internal) | Context-dependent | Streaming ≤ 15min |
| **Contact Center (Genesys)** | Proactive outbound, callback queue | Yes (internal) | Service or clinical | Streaming ≤ 15min |
| **Paid Media (Meta/Google)** | Lookalike modeling | **No PHI** | Marketing; de-identified only | Batch ≤ 24h |
| **Analytics (CJA)** | Reporting, attribution | Yes (with BAA) | N/A (internal) | Batch ≤ 24h |

---

## Payload Governance

### Field Mapping Rules

| Destination Type | Allowed Fields | Blocked Fields |
|-----------------|----------------|----------------|
| Email (clinical) | Name, gap code, appointment link, PCP name | Diagnosis detail, medication names, claim amounts |
| Email (marketing) | Name, portal link, general wellness content | All clinical fields |
| SMS | First name, appointment date/time, short link | All clinical detail |
| Care Management | MRN, gap codes, risk score, care manager ID | Engagement scores, marketing history |
| Paid Media | Hashed email/phone (SHA-256); no PHI | All PHI, all clinical fields |

### DUL Enforcement at Activation

- Destination configured with applicable DUL policies before first activation.
- Payload mapper strips fields blocked by policy — does not fail silently; logs stripped fields.
- If required field stripped → activation blocked, not partially sent.

---

## Latency Architecture

| Priority | Segment Type | Target Latency | Mechanism |
|----------|-------------|---------------|-----------|
| P1 — Critical | ADT-triggered outreach | ≤ 15 minutes | Streaming segment + streaming activation |
| P2 — Clinical | Daily care gap batch | ≤ 4 hours | Scheduled batch segment + batch activation |
| P3 — Engagement | Portal re-engagement | ≤ 24 hours | Daily batch |
| P4 — Marketing | Campaign waves | Scheduled window | Batch with retry |

---

## Retry and Fallback

See [Failure Mode Analysis](../governance/failure-mode-analysis.md) for full runbooks.

| Failure | Retry | Fallback |
|---------|-------|----------|
| Destination API down | 4x exponential backoff | Clinical → care manager dashboard |
| Payload rejected | No retry with altered payload | Fix mapping; re-export |
| Partial batch | Retry failed profiles only | Log partial success |
| Rate limit | Backoff + queue | Defer to next window |

---

## Activation Audit

Every activation logs:
- Segment name and ID
- Profile count exported
- Destination name
- Timestamp
- Success/failure status
- Fields included (field manifest)
- Consent state at time of activation

Retained 6 years per HIPAA requirements.

---

## ERP Parallel

Activation is the CDP equivalent of **shipping** — the moment the governed record becomes an external action. In Sage 100, you didn't ship without validated ATP and correct customer address. In RTCDP, you don't activate without identity resolution and consent validation.

---

## Related Documents

- [Audience Design](audience-design.md)
- [Consent & HIPAA Model](../governance/consent-hipaa-model.md)
- [KPI Framework](../business/kpi-framework.md)
