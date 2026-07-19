# Adobe RTCDP Healthcare Architecture

**Enterprise Customer Intelligence & Activation Architecture for Healthcare**

---

## Overview

This case study designs a **Real-Time Customer Data Platform (RTCDP)** architecture for a multi-channel healthcare organization that must unify member/patient intelligence across CRM, EMR, patient portal, call center, and claims — while enforcing **HIPAA Privacy Rule** controls, **consent-based activation**, and the **minimum necessary** standard.

!!! info "Portfolio Project"
    This is an architecture case study for portfolio and interview purposes by **Dr. Tatianna Gilliam, DBA** (AZ-305 | AI-102 | AZ-104).

## Quick Navigation

<div class="grid cards" markdown>

-   :material-sitemap:{ .lg .middle } **Architecture**

    ---

    Technical designs for XDM schemas, identity stitching, and activation flows

    [:octicons-arrow-right-24: Explore Architecture](architecture/index.md)

-   :material-shield-check:{ .lg .middle } **Governance**

    ---

    HIPAA compliance, consent models, and data governance frameworks

    [:octicons-arrow-right-24: View Governance](governance/index.md)

-   :material-chart-line:{ .lg .middle } **Business**

    ---

    Stakeholder mapping and KPI frameworks for measuring success

    [:octicons-arrow-right-24: Business Context](business/index.md)

-   :material-rocket-launch:{ .lg .middle } **Deployment**

    ---

    Infrastructure as code, Kubernetes manifests, and operational runbooks

    [:octicons-arrow-right-24: Deployment Guide](deploy/index.md)

</div>

## Architecture Principles

1. **Trust before activation** — No audience qualifies without resolved identity and valid consent for the intended use case.
2. **XDM as system of record** — Not a copy of EMR; a governed, consent-filtered view for engagement and care coordination marketing.
3. **Minimum necessary by design** — Data usage labels and field-level policies restrict PHI exposure in downstream destinations.
4. **ERP-grade data integrity** — The same discipline applied to Sage 100 master data maps directly to profile unification.
5. **Failure-aware design** — Identity conflicts, consent drift, and pipeline delays are modeled explicitly.

## Source System Landscape

| System | Primary Role | Identity Keys | Ingestion Pattern |
|--------|-------------|---------------|-------------------|
| **CRM** (Salesforce) | Demographics, preferences, care team | Email, phone, member ID | Batch + API |
| **EMR** (Epic) | Clinical encounters, care gaps | MRN, FHIR Patient ID | Batch (HL7/FHIR) |
| **Patient Portal** | Digital engagement, scheduling | ECID, authenticated user ID | Streaming + API |
| **Call Center** | Interaction logs, disposition | Phone, member ID, ANI | Streaming |
| **Claims** | Utilization, coverage | Member ID, subscriber ID | Batch |

## Phased Rollout

```mermaid
gantt
    title RTCDP Implementation Phases
    dateFormat  YYYY-MM-DD
    section Foundation
    BAA & Sandbox Setup       :done, p0a, 2024-01-01, 30d
    XDM Schema Design         :done, p0b, after p0a, 45d
    Identity Namespaces       :done, p0c, after p0a, 30d
    section Profile Unification
    CRM Ingestion             :active, p1a, after p0b, 30d
    Portal Integration        :p1b, after p1a, 21d
    Call Center Streaming     :p1c, after p1a, 21d
    section Clinical Enrichment
    EMR Integration           :p2a, after p1c, 45d
    Claims Processing         :p2b, after p2a, 30d
    section Activation
    Email & SMS Channels      :p3a, after p2b, 21d
    Paid Media Destinations   :p3b, after p3a, 21d
    section Optimization
    KPI Dashboards            :p4a, after p3b, 30d
    Runbook Documentation     :p4b, after p4a, 14d
```

## Role Dimensions Demonstrated

| Role Dimension | Evidence | Key Artifacts |
|----------------|----------|---------------|
| **Software Engineer / Data Scientist** | XDM schema design, event model, identity graph logic | [XDM Schema](architecture/xdm-schema-design.md), [Identity Stitching](architecture/identity-stitching-flow.md) |
| **Project Manager** | Stakeholder map, phased rollout, delivery artifacts | [Stakeholder Map](business/business-problem-stakeholder-map.md), [Design Decisions](design-decisions.md) |
| **GRC Analyst** | Consent architecture, HIPAA controls, failure modes | [Consent Model](governance/consent-hipaa-model.md), [Failure Modes](governance/failure-mode-analysis.md) |
| **Consultant** | Business framing, KPI framework, executive narrative | [KPI Framework](business/kpi-framework.md), [Executive Summaries](portfolio/executive-summary-recruiter.md) |
| **Architect** | Source landscape, profile unification, activation design | [Source Systems](architecture/source-system-architecture.md), [Activation](architecture/activation-architecture.md) |
