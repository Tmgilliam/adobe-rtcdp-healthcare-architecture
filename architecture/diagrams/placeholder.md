# Diagrams — Placeholder Index

**Author:** Dr. Tatianna Gilliam  
**Purpose:** Index of architecture diagrams for future Mermaid/Lucidchart rendering

---

## Planned Diagrams

| # | Diagram Name | Location | Status |
|---|-------------|----------|--------|
| 1 | Source System Landscape | `source-system-landscape.mmd` | Planned |
| 2 | XDM Schema Relationship (Profile ↔ Events) | `xdm-schema-relationship.mmd` | Planned |
| 3 | Identity Stitching Flow | `identity-stitching-flow.mmd` | Planned |
| 4 | Consent State Machine | `consent-state-machine.mmd` | Planned |
| 5 | Segment Qualification Pipeline | `segment-qualification.mmd` | Planned |
| 6 | Activation Architecture | `activation-architecture.mmd` | Planned |
| 7 | Phased Rollout Timeline | `phased-rollout.mmd` | Planned |
| 8 | Failure Mode Decision Tree | `failure-mode-decision-tree.mmd` | Planned |

---

## Quick Reference — Source System Landscape (ASCII)

```
 CRM ──────┐
 EMR ──────┤
 Portal ───┼──► Integration Layer ──► AEP Profile ──► Segments ──► Destinations
 Call Ctr ─┤         (DUL, Consent)
 Claims ───┘
```

---

## Quick Reference — Identity Graph (ASCII)

```
     ECID ──── anonymous portal behavior
      │
      ▼ (login)
     MRN ◄──── EMR (authoritative)
      │
      ├── MemberID ◄──── Claims / CRM
      ├── Email ◄────── Portal (verified)
      └── Phone ◄────── CRM / Call Center
```

---

## Notes

Replace ASCII placeholders with Mermaid or architecture tooling exports before portfolio presentation. Text descriptions in architecture/ and governance/ documents are interview-ready without rendered diagrams.
