# Interview Talk Track — Adobe RTCDP Healthcare Architecture

**Dr. Tatianna Gilliam, DBA** | AZ-305 | AI-102 | AZ-104  
Three versions for different interview stages, plus deep-dive objection handling.

---

## Version 1 — 60 Seconds (Recruiter Screen)

*"I designed an enterprise customer intelligence architecture for healthcare on Adobe Real-Time CDP — unifying CRM, EMR, patient portal, call center, and claims into a single governed member profile with HIPAA consent enforcement and identity stitching across MRN, member ID, and digital IDs.*

*It proves five things: XDM schema design, HIPAA governance, source system architecture, activation design, and KPI measurement — all framed around the same data integrity problem I solved in ERP operations for ten years. Happy to go deeper on architecture, compliance, or business outcomes."*

---

## Version 2 — 3 Minutes (Hiring Manager / Solutions Architect)

### Opening — Business Problem (30 seconds)

*"Healthcare organizations have member data in five systems that don't share a key. CRM has a contact. Epic has a patient with an MRN. The portal has a digital ID. The call center has a phone number. Claims has a member ID. Marketing wants to activate care gap outreach. Compliance says not without consent. IT says the data doesn't match.*

*This case study designs the architecture to solve that — not as an Adobe demo, but as an enterprise data unification problem with HIPAA controls."*

### Architecture Walkthrough (90 seconds)

*"Three layers:*

*1. **Source system architecture** — I documented what each system contributes, what identity fields exist, ingestion patterns, and HIPAA classification per data element. Minimum necessary is enforced at ingestion — clinical notes and call recordings never enter the CDP.*

*2. **XDM schema design** — Profile schema with custom field groups for consent, care attributes, and engagement. Event schemas for portal, call center, and clinical triggers. Identity namespace strategy with MRN as primary, member ID secondary, ECID for anonymous-to-known transition. Same discipline I applied to Sage 100 item master — one record structure, governed changes.*

*3. **Governance and activation** — Consent flags captured at portal, call center, and in-person encounters. Every segment includes consent gates as mandatory AND conditions. Data usage labels block PHI from reaching non-HIPAA destinations. Failure modes are documented — identity conflicts, consent flip-flops, EMR delays — with detection signals and runbooks."*

### Outcome Framing (30 seconds)

*"The KPI framework measures what matters: profile completeness, identity resolution rate, care gap closure lift, and compliance posture — not email volume. Phased rollout starts with non-clinical profile unification, adds clinical enrichment with authorization, then activates with consent-gated destinations.*

*I built this to prove I can architect a regulated CDP without being an Adobe employee — because the hard part is data governance and identity trust, not button configuration."*

### Close (30 seconds)

*"The ERP parallel is direct: I managed 98% inventory accuracy in Sage 100 because duplicate records and untrusted data stop operations. Healthcare activation has the same failure mode at higher stakes. This project proves I bring that discipline to customer data platforms."*

---

## Version 3 — Deep Dive (Technical Panel + Objection Handling)

### Architecture Deep Dive (5 minutes)

**Identity stitching flow:**
- ECID captures anonymous portal behavior; on authentication, MRN is appended and graphs merge.
- Call center ANI matched to CRM phone (E.164 normalized); agent-verified Member ID confirms stitch.
- Claims Member ID linked to MRN via EMPI crosswalk — never auto-merge conflicting MRNs.
- Namespace priority: MRN > Member ID > Email > Phone > ECID.

**Consent enforcement:**
- Consent state machine: unknown → opted in → opted out / expired → suppressed.
- Suppression hierarchy: global suppression blocks everything; clinical authorization has expiry.
- Segment example: care gap outreach requires `activeCareGaps CONTAINS gap code` AND `clinicalPrograms.optIn = true` AND `authorizationExpiry > NOW()` AND `MRN IS NOT EMPTY`.

**Failure modes:**
- Identity conflict → flag, suppress, EMPI review. Never auto-merge.
- Consent flip-flop → most restrictive wins; manual Privacy Officer review.
- EMR stale > 26 hours → pause clinical activations.
- Activation failure → retry 4x with backoff; clinical segments fall back to care manager dashboard.

**Schema evolution:**
- Optional fields by default; breaking changes require major version increment.
- Pre-promotion checklist: segments, destinations, DUL policies, consent gates, rollback version.

---

### Objection 1: "You're Not an Adobe Specialist"

**Prepared Response:**

*"Correct — I'm not an Adobe certified practitioner, and I won't pretend to be. Here's what I am: an architect who designs governed data platforms in regulated environments.*

*Adobe RTCDP is the activation layer in this case study. The hard problems — identity stitching across MRN and member ID, HIPAA minimum necessary field selection, consent enforcement in segment logic, failure mode design for duplicate records — are platform-agnostic. I've seen the same problems in Sage 100 ERP: duplicate customer records, modules that don't share a key, shipping to the wrong address because the record was untrusted.*

*If you put me on Adobe, I ramp on platform specifics in weeks. What doesn't ramp quickly is ten years of knowing what happens when you activate on dirty data in a regulated industry. That's what this project proves.*

*I also hold AZ-305, AI-102, and AZ-104 — I architect on Azure today and design cloud-agnostically. The CDP category is converging: Segment, mParticle, Tealium, Adobe — the governance layer is the differentiator, not the UI."*

---

### Objection 2: "How Does This Connect to Your ERP Background?"

**Prepared Response:**

*"Directly. The data unification problem in healthcare is identical to the data governance problem I solved in ERP.*

*In Sage 100 and Scanco WMS at SSCOR, I managed operations where inventory accuracy was 98%, fill rate was 95%, and shipping accuracy was 100%. Those numbers didn't happen because the ERP was special — they happened because we enforced master data discipline: one customer record, one item master, validated before transaction processing.*

*Translate that to healthcare CDP:*

| ERP (Sage 100) | Healthcare RTCDP |
|----------------|------------------|
| Duplicate customer number | Multiple MRNs for same patient |
| Item master vs. inventory mismatch | Profile attribute vs. event conflict |
| Can't ship without ATP validation | Can't activate without consent + identity |
| Scanco barcode ↔ ERP item linkage | ECID ↔ MRN ↔ Member ID identity graph |
| Audit trail for inventory adjustment | HIPAA audit trail for PHI access |
| Warehouse zone access controls | Data usage labels and DUL policies |

*When I designed XDM schema field groups, I applied the same change-control I used for ERP custom fields — steward approval, version policy, rollback plan. When I designed consent enforcement, I applied the same 'stop the line' principle from warehouse operations — if identity or consent is uncertain, don't activate.*

*My DBA is in organizational leadership. My ERP years are in operational data integrity. This case study connects both to modern customer data architecture."*

---

### Hard Questions — Quick Reference

| Question | Answer Anchor |
|----------|--------------|
| "Why Adobe over Segment/Salesforce CDP?" | Category comparison; chose Adobe for AEP + RTCDP + DUL in one platform; architecture transfers |
| "How do you handle PHI in paid media?" | Block by DUL policy; de-identified lookalike only with legal review; never raw PHI |
| "What's the BAA process?" | Execute before Production PHI; scope boundaries; subprocessor audit; CMK if required |
| "How do you measure ROI?" | Care gap closure lift, portal engagement, cost per activated member — not send volume |
| "Biggest risk?" | Identity stitch error → duplicate/wrong outreach → HIPAA incident; mitigated by EMPI governance |

---

## Usage Notes

- **60-second:** Recruiter phone screen, conference intro, LinkedIn conversation
- **3-minute:** Hiring manager, first-round solutions architect, panel opener
- **Deep dive:** Technical panel, GRC interview, objection handling for career pivot questions
- Lead with business problem, not platform features
- ERP parallel is the differentiator — use it when they question Adobe depth or career coherence
