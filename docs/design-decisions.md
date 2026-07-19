# Design Decisions — Healthcare RTCDP Architecture

**Author:** Dr. Tatianna Gilliam  
**Format:** Architecture Decision Records (ADRs)

---

## ADR-001: XDM as Canonical Profile Model

**Status:** Accepted  
**Context:** Five source systems define "member" differently with inconsistent field names and types.  
**Decision:** Adopt Adobe XDM with custom healthcare field groups as the single profile contract.  
**Rationale:** Enables segment portability, schema validation, and DUL enforcement. Mirrors ERP item master standardization in Sage 100.  
**Consequences:** Upfront schema design investment; all integrations must map to XDM before ingestion.

---

## ADR-002: MRN as Primary Identity Namespace

**Status:** Accepted  
**Context:** Multiple identity keys exist across sources; incorrect priority causes wrong-profile merges.  
**Decision:** MRN (EMR-sourced) is priority 1 namespace; MemberID is priority 2.  
**Rationale:** MRN is clinically authoritative within the health system. MemberID covers payer/plan context.  
**Consequences:** EMR ingestion is Phase 2 dependency; EMPI reconciliation required before clinical activation.

---

## ADR-003: Consent Gates in Every Segment

**Status:** Accepted  
**Context:** HIPAA and TCPA require consent appropriate to use case; ad hoc segment logic creates compliance gaps.  
**Decision:** Mandatory consent AND conditions in every segment definition; no exceptions.  
**Rationale:** Fail-safe compliance — segment cannot qualify without valid consent.  
**Consequences:** Smaller segment populations; higher trust; Privacy Officer audit simplified.

---

## ADR-004: Minimum Necessary at Ingestion

**Status:** Accepted  
**Context:** EMR contains full clinical record; CDP requires subset for engagement use cases.  
**Decision:** Exclude clinical notes, lab values, imaging, call recordings, and SSN at ingestion boundary.  
**Rationale:** HIPAA minimum necessary standard; reduces breach blast radius.  
**Consequences:** Some use cases require EMR direct lookup outside CDP; accepted trade-off.

---

## ADR-005: No Auto-Merge on Identity Conflict

**Status:** Accepted  
**Context:** Duplicate MRNs occur from mergers, registration errors, and EMPI lag.  
**Decision:** Flag conflicts for EMPI review; never auto-merge conflicting MRNs.  
**Rationale:** Wrong merge = wrong-member activation = HIPAA incident.  
**Consequences:** EMPI exception queue requires staffing; temporary duplicate profiles exist until resolved.

---

## ADR-006: Batch-First EMR, Streaming-First Portal

**Status:** Accepted  
**Context:** EMR systems (Epic) primarily support batch/HL7 interfaces; portal supports real-time Web SDK.  
**Decision:** EMR ingestion via nightly batch with 24h SLA; portal via AEP Web SDK streaming.  
**Rationale:** Matches source system capabilities; avoids fragile real-time EMR dependencies.  
**Consequences:** Clinical segments have 24h freshness lag; mitigated by freshness monitoring and activation pause.

---

## ADR-007: Block PHI from Paid Media Destinations

**Status:** Accepted  
**Context:** Paid media platforms (Meta, Google) are not HIPAA-eligible destinations.  
**Decision:** DUL policy blocks all PHI and identity-labeled fields from paid media activations.  
**Rationale:** Legal and Privacy Officer requirement; non-negotiable.  
**Consequences:** Lookalike modeling limited to de-identified/hashed segments with legal review.

---

## ADR-008: Phased Rollout — Non-Clinical First

**Status:** Accepted  
**Context:** Full clinical integration requires BAA, EMPI alignment, and Privacy Officer sign-off.  
**Decision:** Phase 1 unifies CRM + portal + call center (non-clinical); Phase 2 adds EMR + claims.  
**Rationale:** Delivers member 360 value while governance matures; reduces compliance risk during ramp.  
**Consequences:** Care gap segments unavailable until Phase 2; marketing and engagement use cases prove platform first.

---

## ADR-009: ERP-Grade Change Control for Schema

**Status:** Accepted  
**Context:** Schema changes can break segments, activations, and consent enforcement without notice.  
**Decision:** Schema version policy with steward approval, sandbox testing, rollback plan, and change freeze during activation windows.  
**Rationale:** Same discipline applied to Sage 100 custom field changes — proven in ERP operations.  
**Consequences:** Slower schema iteration; higher production stability.

---

## Related Documents

- [XDM Schema Design](architecture/xdm-schema-design.md)
- [Consent & HIPAA Model](governance/consent-hipaa-model.md)
- [Failure Mode Analysis](governance/failure-mode-analysis.md)
