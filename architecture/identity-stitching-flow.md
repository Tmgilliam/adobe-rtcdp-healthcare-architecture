# Identity Stitching Flow — Healthcare RTCDP

**Author:** Dr. Tatianna Gilliam  
**Scope:** End-to-end identity resolution across CRM, EMR, portal, call center, and claims

---

## Overview

Identity stitching is the process of linking fragmented identifiers into a **single unified profile** in AEP Identity Service. In healthcare, this is the highest-risk architectural component — an incorrect merge is a HIPAA incident.

---

## Namespace Priority

| Priority | Namespace | Authoritative Source |
|----------|-----------|---------------------|
| 1 | MRN | EMR (Epic) |
| 2 | MemberID | Claims / CRM |
| 3 | Email | Portal (verified) |
| 4 | Phone | CRM / Call Center (E.164) |
| 5 | ECID | Portal Web SDK |

Higher-priority namespaces dominate merge decisions when conflicts arise.

---

## Stitching Scenarios

### Scenario A: Anonymous Portal → Authenticated Member

```
1. Visitor browses portal → ECID created (anonymous profile)
2. Visitor logs in → Authentication event carries MRN + MemberID
3. Identity Service appends MRN/MemberID to ECID profile
4. Graph merges anonymous behavior into known profile
5. Consent flags from preference center applied
```

### Scenario B: Inbound Call → Known Member

```
1. Call arrives with ANI (phone number)
2. Phone namespace matched to CRM profile
3. IVR captures MemberID → confirmed against CRM
4. Agent verifies identity (HIPAA verification script)
5. Call event appended; MRN added if agent looks up EMR
```

### Scenario C: Claims → EMR Linkage

```
1. Claims batch delivers MemberID + limited clinical codes
2. EMPI crosswalk resolves MemberID → MRN
3. MRN appended to profile with claims attributes
4. If crosswalk returns multiple MRNs → FLAG for EMPI review (no auto-merge)
```

---

## Conflict Handling

| Conflict | Action |
|----------|--------|
| Two MRNs, one MemberID | Flag → EMPI review → manual merge |
| One MRN, two MemberIDs | EMPI determines correct MemberID |
| Email shared by household | Do not merge; use MemberID disambiguation |
| ECID on shared device | Authenticated login required for MRN stitch |

See [Failure Mode Analysis](../governance/failure-mode-analysis.md) for full runbooks.

---

## ERP Parallel

Identity stitching is the CDP equivalent of **customer number crosswalk tables** in Sage 100 — linking ship-to IDs, bill-to IDs, and CRM contacts to one golden customer record. Same discipline, higher regulatory stakes.

---

## Related Documents

- [XDM Schema Design](xdm-schema-design.md)
- [Source System Architecture](source-system-architecture.md)
