# Kubernetes Deployment

This guide covers the Kubernetes manifests and Helm charts for deploying RTCDP integration services.

## Namespace Structure

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: rtcdp
  labels:
    name: rtcdp
    compliance: hipaa
---
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
  labels:
    name: monitoring
```

## Helm Chart Structure

```
deploy/kubernetes/
├── charts/
│   ├── ingestion/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── configmap.yaml
│   │       ├── secret.yaml
│   │       └── hpa.yaml
│   ├── transform/
│   │   └── ...
│   └── monitoring/
│       └── ...
└── values/
    ├── dev.yaml
    ├── staging.yaml
    └── prod.yaml
```

## Ingestion Service Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ingestion-service
  namespace: rtcdp
  labels:
    app: ingestion
    component: data-pipeline
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ingestion
  template:
    metadata:
      labels:
        app: ingestion
        compliance: hipaa
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
    spec:
      serviceAccountName: ingestion-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      
      containers:
        - name: ingestion
          image: rtcdp/ingestion:v1.2.0
          imagePullPolicy: Always
          
          ports:
            - containerPort: 8080
              name: http
            - containerPort: 8081
              name: metrics
          
          env:
            - name: AZURE_CLIENT_ID
              valueFrom:
                secretKeyRef:
                  name: azure-credentials
                  key: client-id
            - name: ADOBE_API_KEY
              valueFrom:
                secretKeyRef:
                  name: adobe-credentials
                  key: api-key
            - name: LOG_LEVEL
              valueFrom:
                configMapKeyRef:
                  name: ingestion-config
                  key: log-level
          
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
            limits:
              cpu: "2000m"
              memory: "2Gi"
          
          livenessProbe:
            httpGet:
              path: /health/live
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
          
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          
          volumeMounts:
            - name: config
              mountPath: /app/config
              readOnly: true
            - name: temp
              mountPath: /tmp
      
      volumes:
        - name: config
          configMap:
            name: ingestion-config
        - name: temp
          emptyDir: {}
      
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app: ingestion
                topologyKey: topology.kubernetes.io/zone
      
      nodeSelector:
        workload: ingestion
```

## Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ingestion-hpa
  namespace: rtcdp
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ingestion-service
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
    - type: Pods
      pods:
        metric:
          name: messages_pending
        target:
          type: AverageValue
          averageValue: "1000"
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 100
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
```

## Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingestion-network-policy
  namespace: rtcdp
spec:
  podSelector:
    matchLabels:
      app: ingestion
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
        - podSelector:
            matchLabels:
              app: prometheus
      ports:
        - protocol: TCP
          port: 8081
    - from:
        - podSelector:
            matchLabels:
              app: api-gateway
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              name: kube-system
        - podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
    - to:
        - ipBlock:
            cidr: 10.0.3.0/24  # Data subnet
      ports:
        - protocol: TCP
          port: 443
```

## Pod Disruption Budget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: ingestion-pdb
  namespace: rtcdp
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: ingestion
```

## Service Account with Workload Identity

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ingestion-sa
  namespace: rtcdp
  annotations:
    azure.workload.identity/client-id: "${AZURE_CLIENT_ID}"
  labels:
    azure.workload.identity/use: "true"
```

## Helm Values (Production)

```yaml
# values/prod.yaml
global:
  environment: production
  imageRegistry: rtcdpacr.azurecr.io
  imagePullSecrets:
    - name: acr-secret

ingestion:
  replicaCount: 3
  image:
    repository: rtcdp/ingestion
    tag: v1.2.0
  
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 2000m
      memory: 2Gi
  
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilization: 70
  
  config:
    batchSize: 1000
    flushIntervalSeconds: 30
    retryAttempts: 3
    logLevel: info

transform:
  replicaCount: 3
  image:
    repository: rtcdp/transform
    tag: v1.1.0
  
  resources:
    requests:
      cpu: 1000m
      memory: 1Gi
    limits:
      cpu: 4000m
      memory: 4Gi

monitoring:
  prometheus:
    enabled: true
    retention: 15d
  
  grafana:
    enabled: true
    adminPassword: "${GRAFANA_PASSWORD}"
  
  alertmanager:
    enabled: true
    receivers:
      - name: pagerduty
        pagerduty_configs:
          - service_key: "${PAGERDUTY_KEY}"
```

## Deployment Commands

```bash
# Create namespace
kubectl apply -f deploy/kubernetes/namespaces.yaml

# Create secrets (from Key Vault)
kubectl create secret generic adobe-credentials \
  --namespace rtcdp \
  --from-literal=api-key="$(az keyvault secret show --vault-name rtcdp-prod-kv --name adobe-api-key --query value -o tsv)"

# Install ingestion chart
helm upgrade --install ingestion ./deploy/kubernetes/charts/ingestion \
  --namespace rtcdp \
  --values ./deploy/kubernetes/values/prod.yaml \
  --wait

# Verify deployment
kubectl rollout status deployment/ingestion-service -n rtcdp

# View logs
kubectl logs -l app=ingestion -n rtcdp --tail=100 -f
```
