# Architecture Diagrams

This section contains visual representations of the RTCDP Healthcare architecture components.

## System Context Diagram

```mermaid
C4Context
    title System Context - RTCDP Healthcare Platform
    
    Person(patient, "Patient/Member", "Healthcare consumer")
    Person(careTeam, "Care Team", "Physicians, nurses, care coordinators")
    Person(marketing, "Marketing Team", "Campaign managers")
    
    System(rtcdp, "RTCDP Healthcare Platform", "Unified customer data platform with consent-based activation")
    
    System_Ext(crm, "Salesforce CRM", "Customer relationship management")
    System_Ext(emr, "Epic EMR", "Electronic medical records")
    System_Ext(portal, "Patient Portal", "Self-service engagement")
    System_Ext(callCenter, "Call Center", "Telephony and interaction logs")
    System_Ext(claims, "Claims System", "Healthcare claims processing")
    
    System_Ext(email, "Email Service", "Marketing email delivery")
    System_Ext(sms, "SMS Gateway", "Text messaging")
    System_Ext(media, "Paid Media", "Advertising platforms")
    
    Rel(patient, portal, "Engages via")
    Rel(patient, callCenter, "Calls")
    Rel(careTeam, emr, "Documents in")
    Rel(marketing, rtcdp, "Builds audiences")
    
    Rel(crm, rtcdp, "Syncs demographics")
    Rel(emr, rtcdp, "Shares care gaps")
    Rel(portal, rtcdp, "Streams events")
    Rel(callCenter, rtcdp, "Sends interactions")
    Rel(claims, rtcdp, "Provides utilization")
    
    Rel(rtcdp, email, "Activates to")
    Rel(rtcdp, sms, "Activates to")
    Rel(rtcdp, media, "Activates to")
```

## Container Diagram

```mermaid
C4Container
    title Container Diagram - RTCDP Integration Layer
    
    Person(operator, "Platform Operator", "DevOps engineer")
    
    Container_Boundary(azure, "Azure Cloud") {
        Container(aks, "AKS Cluster", "Kubernetes", "Container orchestration")
        Container(eventHub, "Event Hubs", "Azure Event Hubs", "Event streaming")
        Container(storage, "Blob Storage", "Azure Storage", "Data lake")
        Container(keyVault, "Key Vault", "Azure Key Vault", "Secrets management")
        ContainerDb(logs, "Log Analytics", "Azure Monitor", "Observability")
    }
    
    Container_Boundary(k8s, "Kubernetes Workloads") {
        Container(ingestion, "Ingestion Service", "Go", "Data collection and validation")
        Container(transform, "Transform Workers", "Python", "Data transformation and enrichment")
        Container(consent, "Consent Service", "Node.js", "Consent management and enforcement")
    }
    
    System_Ext(aep, "Adobe Experience Platform", "RTCDP SaaS")
    
    Rel(operator, aks, "Manages via kubectl/Helm")
    Rel(ingestion, eventHub, "Publishes events")
    Rel(transform, eventHub, "Consumes events")
    Rel(transform, storage, "Reads/writes data")
    Rel(transform, aep, "Sends profiles")
    Rel(consent, storage, "Reads consent store")
    Rel(ingestion, keyVault, "Retrieves secrets")
    Rel(aks, logs, "Sends telemetry")
```

## Data Flow Diagram

```mermaid
flowchart LR
    subgraph Sources["Source Systems"]
        CRM[CRM]
        EMR[EMR]
        Portal[Portal]
        CC[Call Center]
        Claims[Claims]
    end
    
    subgraph Ingestion["Ingestion Layer"]
        Batch[Batch Connector]
        Stream[Streaming API]
        FHIR[FHIR Adapter]
    end
    
    subgraph Process["Processing Layer"]
        Valid[Validation]
        Transform[Transformation]
        Enrich[Enrichment]
        Consent[Consent Check]
    end
    
    subgraph AEP["Adobe Experience Platform"]
        XDM[XDM Store]
        Identity[Identity Graph]
        Profile[Profile Store]
        Segment[Segment Builder]
    end
    
    subgraph Activate["Activation"]
        Email[Email]
        SMS[SMS]
        Media[Paid Media]
    end
    
    CRM --> Batch
    Claims --> Batch
    EMR --> FHIR
    Portal --> Stream
    CC --> Stream
    
    Batch --> Valid
    Stream --> Valid
    FHIR --> Valid
    
    Valid --> Transform
    Transform --> Enrich
    Enrich --> Consent
    
    Consent -->|"✓ Consent Valid"| XDM
    Consent -->|"✗ No Consent"| Reject[Reject/Log]
    
    XDM --> Identity
    Identity --> Profile
    Profile --> Segment
    
    Segment --> Email
    Segment --> SMS
    Segment --> Media
```

## Identity Resolution Flow

```mermaid
sequenceDiagram
    participant Source as Source System
    participant Ingestion as Ingestion Service
    participant Identity as Identity Service
    participant Graph as Identity Graph
    participant Profile as Profile Store
    
    Source->>Ingestion: Event with identifiers<br/>(email, phone, MRN)
    Ingestion->>Ingestion: Validate & normalize
    Ingestion->>Identity: Resolve identities
    
    Identity->>Graph: Query existing links
    
    alt New Identity
        Graph-->>Identity: No matches
        Identity->>Graph: Create new cluster
        Identity-->>Ingestion: New profile ID
    else Existing Match (high confidence)
        Graph-->>Identity: Single cluster match
        Identity-->>Ingestion: Existing profile ID
    else Multiple Matches (conflict)
        Graph-->>Identity: Multiple clusters
        Identity->>Identity: Apply resolution rules
        Identity->>Graph: Merge or flag for review
        Identity-->>Ingestion: Resolved profile ID
    end
    
    Ingestion->>Profile: Upsert attributes
    Profile-->>Ingestion: Confirmation
```

## Consent Enforcement

```mermaid
stateDiagram-v2
    [*] --> CheckConsent: Activation Request
    
    CheckConsent --> ConsentValid: Valid consent found
    CheckConsent --> NoConsent: No consent record
    CheckConsent --> ConsentExpired: Consent expired
    CheckConsent --> ConsentWithdrawn: Consent withdrawn
    
    ConsentValid --> CheckPurpose: Verify purpose match
    
    CheckPurpose --> PurposeValid: Purpose allowed
    CheckPurpose --> PurposeDenied: Purpose not covered
    
    PurposeValid --> CheckMinimumNecessary: Apply data filters
    
    CheckMinimumNecessary --> Activate: Filtered profile
    
    Activate --> [*]: Success
    
    NoConsent --> LogRejection: Log for compliance
    ConsentExpired --> LogRejection
    ConsentWithdrawn --> LogRejection
    PurposeDenied --> LogRejection
    
    LogRejection --> [*]: Rejected
```

## Deployment Architecture

```mermaid
flowchart TB
    subgraph GitHub["GitHub"]
        Repo[Repository]
        Actions[GitHub Actions]
    end
    
    subgraph Dev["Development"]
        DevAKS[AKS Dev]
        DevData[Dev Data Services]
    end
    
    subgraph Staging["Staging"]
        StagingAKS[AKS Staging]
        StagingData[Staging Data Services]
    end
    
    subgraph Prod["Production"]
        ProdAKS1[AKS Prod<br/>East US 2]
        ProdAKS2[AKS Prod<br/>West US 2]
        ProdData[Prod Data Services]
    end
    
    Repo --> Actions
    Actions -->|"PR Merge"| DevAKS
    Actions -->|"Tag v*-rc*"| StagingAKS
    Actions -->|"Tag v*"| ProdAKS1
    Actions -->|"Tag v*"| ProdAKS2
    
    DevAKS --> DevData
    StagingAKS --> StagingData
    ProdAKS1 --> ProdData
    ProdAKS2 --> ProdData
```

## Monitoring Dashboard Layout

```mermaid
block-beta
    columns 3
    
    block:header:3
        title["RTCDP Healthcare Operations Dashboard"]
    end
    
    block:row1
        ingestion["Ingestion<br/>Events/sec: 1,234<br/>Errors: 0.01%"]
        identity["Identity<br/>Resolution Rate: 94%<br/>Conflicts: 12"]
        consent["Consent<br/>Coverage: 78%<br/>Rejections: 156"]
    end
    
    block:row2
        latency["P99 Latency<br/>Ingestion: 45ms<br/>Activation: 2.1s"]
        profile["Profile Store<br/>Count: 2.4M<br/>Freshness: 99.2%"]
        activation["Activation<br/>Success: 99.8%<br/>Pending: 234"]
    end
    
    block:row3:3
        alerts["Active Alerts: 0 Critical | 2 Warning | 5 Info"]
    end
```
