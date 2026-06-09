# Data Governance Framework — Healthcare RTCDP

**Author:** Dr. Tatianna Gilliam  
**Scope:** Stewardship, policies, labels, and change control for AEP data assets

---

## Governance Model

| Role | Responsibility | Decision Authority |
|------|-----------------|-------------------|
| **Executive Sponsor** (CMO / VP Clinical Ops) | Business outcomes, budget, priority | Phase gate approval |
| **Privacy Officer** | HIPAA compliance, consent model, minimum necessary | Consent field changes, PHI inclusion |
| **Data Steward** | Schema quality, field definitions, segment taxonomy | Field group changes, segment naming |
| **Data Engineering Lead** | Ingestion pipelines, identity service, monitoring | Connector configuration, SLA targets |
| **Legal Counsel** | BAA, permitted use cases, disclosure accounting | High-risk activation approval |
| **EMPI Team** | Golden record, MRN resolution | Identity conflict resolution |
| **Architecture Review Board** | Schema major versions, namespace changes | Breaking changes |

---

## Data Asset Classification

| Classification | Examples | Handling |
|---------------|----------|----------|
| **Public** | General wellness content URLs | No restrictions |
| **Internal** | Engagement scores, segment names | Workforce access only |
| **PHI — Minimum Necessary** | MRN, gap codes, eligibility | DUL enforced; BAA required |
| **PHI — Restricted** | Diagnoses, medications | Consent-gated segments only |
| **Prohibited** | Clinical notes, call recordings, SSN | Never ingest |

---

## Data Usage Label (DUL) Policy Registry

| Policy ID | Rule | Applies To |
|-----------|------|-----------|
| DUL-001 | Block all `H` labeled fields from paid media destinations | Activation |
| DUL-002 | Require marketing consent for `M` labeled fields | Activation |
| DUL-003 | Require clinical authorization for `CL` labeled fields | Activation |
| DUL-004 | Strip identity fields from analytics exports to non-BAA tools | Export |
| DUL-005 | Enforce minimum necessary on EMR field groups | Ingestion |

---

## Change Control Process

### Schema Changes

1. Data Steward submits change request with business justification.
2. Privacy Officer reviews PHI impact and minimum necessary.
3. Data Engineering validates ingestion and segment impact.
4. Architecture Review Board approves major versions.
5. Sandbox testing → production promotion with rollback plan.

### Segment Changes

1. Data Steward defines segment with consent gates verified.
2. Privacy Officer reviews for permitted use case alignment.
3. Test in sandbox with population count validation.
4. Production promotion during non-activation window.

---

## Data Quality Standards

| Standard | Target | Enforcement |
|----------|--------|-------------|
| Schema validation pass rate | ≥ 99.5% | Ingestion rejection |
| Profile completeness | ≥ 85% | Stewardship dashboard |
| Identity resolution | ≥ 78% | EMPI escalation |
| Consent coverage | ≥ 90% | Re-consent campaigns |
| Duplicate profile rate | ≤ 2% | EMPI reconciliation |

---

## ERP Parallel

This framework mirrors **ERP change control for master data** — the same process Dr. Gilliam enforced for Sage 100 custom field additions: steward proposes, operations validates, leadership approves, rollback identified before promotion.

---

## Related Documents

- [Consent & HIPAA Model](consent-hipaa-model.md)
- [XDM Schema Design](../architecture/xdm-schema-design.md)
- [KPI Framework](../business/kpi-framework.md)
