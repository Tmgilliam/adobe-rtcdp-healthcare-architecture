# Failure Mode Analysis — Healthcare RTCDP

**Author:** Dr. Tatianna Gilliam  
**Purpose:** Document what breaks, downstream impact, detection signals, and resolution procedures  
**Principle:** Failures are designed for, not discovered in production

---

## Overview

Healthcare CDP failures have higher stakes than retail CDP failures. An identity stitch error is not a duplicate coupon — it is a potential **HIPAA violation** and member trust failure. This document models five critical failure modes with detection, mitigation, and runbook actions.

---

## 1. Identity Stitching Failure

### Scenario: Multiple MRNs for Same Patient

**Cause:**
- Patient registered at two facilities before EMPI merge.
- Data entry error created duplicate EMR record.
- Merger/acquisition imported legacy MRNs without crosswalk.

**What Happens to Profile:**

| State | AEP Behavior | Business Impact |
|-------|-------------|-----------------|
| Two profiles, same Member ID, different MRNs | Identity Service may or may not merge depending on namespace priority | Member receives duplicate outreach |
| Two profiles, same Email, different MRNs | Email namespace may merge incorrectly | Clinical content sent to wrong profile |
| Profile with MRN but no Member ID | Partial profile; claims data orphaned | Incomplete care gap qualification |

**Detection Signals:**

| Signal | Threshold | Alert Owner |
|--------|-----------|-------------|
| Identity graph merge conflict rate | > 0.5% of daily merges | Data Engineering |
| Duplicate outreach complaint (call center) | Any verified case | Privacy Officer |
| Profile count exceeds member census by > 2% | Weekly reconciliation | Data Steward |
| EMPI exception queue depth | > 100 unresolved records | EMPI Team |

**Resolution Logic:**

1. **Do not auto-merge** conflicting MRNs — flag for EMPI review.
2. EMPI team resolves golden record; corrected MRN published to identity crosswalk.
3. AEP profile merge triggered manually or via Identity Service API after EMPI confirmation.
4. Post-merge: verify segment membership and suppress pending activations until validated.
5. Document in audit log with EMPI ticket reference.

**Prevention:**

- EMPI reconciliation runs before clinical data enters RTCDP (Phase 2 gate).
- Member ID → MRN crosswalk table maintained as governed master data (ERP parallel: customer number crosswalk).

---

## 2. Consent Conflict

### Scenario: Conflicting Consent Signals from Different Touchpoints

**Cause:**
- Member opts out via portal; call center agent records opt-in on same day.
- Paper authorization at clinic conflicts with digital preference center state.
- Consent policy version update invalidates prior captures without re-consent.

**What Happens to Profile:**

| Conflict Type | Profile State | Segment Impact |
|---------------|--------------|----------------|
| Portal opt-out + call center opt-in (same day) | Last-write-wins by timestamp | May incorrectly qualify |
| Clinical opt-in + global suppression | Suppression wins (hierarchy) | Correctly blocked |
| Expired authorization + active opt-in flag | Expired auth invalidates clinical segments | Correctly blocked if enforced |

**Detection Signals:**

| Signal | Threshold | Alert Owner |
|--------|-----------|-------------|
| Consent flip-flop (same flag changes twice in 24h) | Any occurrence | Privacy Officer |
| Segment qualified with expired clinical authorization | Zero tolerance | Automated block + alert |
| Consent source mismatch (opt-in source = call_center, prior opt-out source = portal) | Review queue | Privacy Officer |

**Resolution Logic:**

```
IF consent.suppression.global = true
  → BLOCK all activation (no override)

ELSE IF consent conflict detected (flip-flop)
  → Set consent status = "pending_review"
  → Remove from all active segments
  → Route to Privacy Officer queue
  → Resolve manually with member contact
  → Record resolution in audit log

ELSE IF clinicalPrograms.optIn = true AND authorizationExpiry < NOW()
  → Set clinicalPrograms.optIn = false
  → Remove from clinical segments
  → Trigger re-consent workflow (portal email)

ELSE
  → Apply most restrictive consent state
  → Prefer verified portal capture over verbal call center capture
```

**Prevention:**

- Consent hierarchy documented and enforced in segment logic (see [Consent Model](consent-hipaa-model.md)).
- Call center agents cannot override portal opt-out without supervisor approval code.
- Policy version changes trigger batch re-consent campaign before clinical segments re-qualify.

---

## 3. Data Freshness Failure

### Scenario: EMR Data Delayed

**Cause:**
- EMR batch job failed overnight; care gap file not delivered.
- HL7 ADT interface down; encounter events queued.
- EMR maintenance window extended beyond SLA.

**Impact on Audience Qualification:**

| Segment Type | Impact | Severity |
|--------------|--------|----------|
| Care gap outreach | Stale gaps — may miss newly identified gaps or target closed gaps | **High** |
| Appointment reminder | Portal data current; EMR delay less critical | Low |
| Clinical condition segment | Stale diagnoses — may include resolved conditions | **High** |
| Engagement-only segment | Unaffected (portal/call center streaming) | None |

**Detection Signals:**

| Signal | Threshold | Alert Owner |
|--------|-----------|-------------|
| EMR batch ingestion last-success timestamp | > 26 hours stale | Data Engineering |
| Care gap file record count deviation | > 15% from 7-day average | Data Steward |
| Profile `care.lastEncounterDate` freshness | > 30 days for active members | Data Quality job |
| Schema validation pass rate drop | < 99% | Data Engineering |

**Mitigation:**

| Action | Trigger | Effect |
|--------|---------|--------|
| Pause clinical segment activations | EMR batch > 26h stale | Prevents outreach on stale data |
| Fall back to last-known-good profile snapshot | Batch failure | Segments use prior day data with freshness flag |
| Alert care management team | Care gap file missing | Manual outreach for critical gaps |
| Resume activations | Successful batch + validation pass | Normal operations |

**SLA Targets:**

| Source | Freshness SLA | Escalation |
|--------|--------------|------------|
| EMR batch (care gaps) | 24 hours | Data Engineering → VP Data |
| EMR ADT (streaming) | 4 hours | Interface team |
| CRM batch | 24 hours | CRM admin |
| Portal (streaming) | Real-time (< 15 min) | AEP ops |
| Claims batch | 7 days | Expected; not used for real-time clinical |

---

## 4. Activation Failure

### Scenario: Downstream Channel Unavailable

**Cause:**
- Email service provider (ESP) API outage.
- Destination connector misconfigured after schema change.
- Destination rate limit exceeded.
- HIPAA-eligible destination certificate expired.

**What Happens:**

| Failure Point | AEP Behavior | Member Impact |
|---------------|-------------|---------------|
| Destination unreachable | Activation job fails; profiles queued | No outreach (silent failure) |
| Partial batch success | Some profiles activated, others failed | Inconsistent member experience |
| Payload rejected (schema mismatch) | Entire batch rejected | No outreach |

**Retry Logic:**

```
Activation Job Failure:
  1. Log failure with destination, segment, profile count, error code
  2. Retry with exponential backoff: 5min → 15min → 1hr → 4hr
  3. Max retries: 4
  4. After max retries:
     a. If clinical segment → alert Care Management for manual outreach
     b. If marketing segment → defer to next scheduled activation window
     c. Never retry with altered payload (no field stripping to force delivery)
  5. Failed profiles remain in segment; re-attempted on next scheduled run
```

**Fallback Behavior:**

| Segment Priority | Fallback |
|------------------|----------|
| Critical clinical (care gap) | Alert care manager dashboard; phone outreach queue |
| Appointment reminder | Portal notification (if portal available) |
| Marketing engagement | Defer 24 hours; no fallback to alternate channel without consent check |
| Survey | Defer to next wave; no retry |

**Detection Signals:**

| Signal | Threshold | Alert Owner |
|--------|-----------|-------------|
| Activation success rate | < 95% per destination | Marketing Ops |
| Destination API error rate | > 5% in 1 hour | Data Engineering |
| Activation latency | > 4 hours from segment export | Marketing Ops |
| Zero successful activations in scheduled window | Any occurrence | PagerDuty → on-call |

---

## 5. Schema Evolution Failure

### Scenario: New Field Group Breaks Existing Activations

**Cause:**
- Required field added to profile schema without destination mapping update.
- Field renamed in custom field group; segment rules reference old path.
- Data type changed (string → enum); validation rejects existing records.
- New DUL label applied retroactively; destination no longer receives previously allowed fields.

**Impact:**

| Component | Failure Mode |
|-----------|-------------|
| Segment definitions | Query references deprecated field path → empty results |
| Activation mappings | Destination expects field that no longer exists → batch rejection |
| Profile completeness score | Drops due to new required fields → KPI false negative |
| Consent enforcement | New consent field not in segment rules → ungated activation risk |

**Detection Signals:**

| Signal | Threshold | Alert Owner |
|--------|-----------|-------------|
| Schema validation pass rate | < 99% | Data Engineering |
| Segment population count deviation | > 20% day-over-day without business cause | Data Steward |
| Activation payload validation failure | Any occurrence post-schema change | Data Engineering |
| Segment rule deprecation warnings | Any unmapped field | Data Steward |

**Resolution Procedure:**

1. **Schema change freeze** during active activation windows.
2. All schema changes follow versioning policy (see [XDM Schema Design](../architecture/xdm-schema-design.md)).
3. Pre-promotion checklist:
   - [ ] Segment rules updated and tested in sandbox
   - [ ] Destination mappings updated and test activation successful
   - [ ] DUL policies reviewed for new/changed fields
   - [ ] Consent gates verified for affected segments
   - [ ] Rollback schema version identified
4. **Backward compatibility:** New fields are optional by default; breaking changes require major version increment and explicit migration plan.
5. **Rollback:** Revert to prior schema version; re-run segment evaluation; validate activation test batch before resuming.

---

## Failure Mode Summary Matrix

| Failure Mode | Severity | Detection Time Target | Auto-Mitigation | Manual Escalation |
|--------------|----------|----------------------|-----------------|-------------------|
| Identity stitch conflict | Critical | 24 hours | Flag + suppress | EMPI team |
| Consent conflict | Critical | Real-time | Most-restrictive-wins | Privacy Officer |
| EMR data stale | High | 26 hours | Pause clinical activations | Data Engineering |
| Activation down | Medium | 1 hour | Retry + fallback | Marketing Ops |
| Schema evolution break | High | Pre-production | Version rollback | Architecture Board |

---

## ERP Parallel

In Sage 100 WMS operations, a barcode scan mismatch stopped the pick line — by design. The system did not guess. Healthcare RTCDP applies the same principle: **when identity or consent is uncertain, stop activation and escalate.** Speed without trust is a liability.

---

## Related Documents

- [Identity Stitching Flow](../architecture/identity-stitching-flow.md)
- [Consent & HIPAA Model](consent-hipaa-model.md)
- [Activation Architecture](../architecture/activation-architecture.md)
- [KPI Framework](../business/kpi-framework.md)
