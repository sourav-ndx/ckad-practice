#!/bin/bash
# ============================================================
# CKAD EXAM PRACTICE — FULL ENVIRONMENT SETUP
# Run this script ONCE to set up all question environments
# Usage: chmod +x ckad_setup_all.sh && ./ckad_setup_all.sh
# ============================================================

set -e
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[SETUP]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# SET YOUR ALIASES FIRST — do this at start of every session
log "Setting exam aliases..."
alias k=kubectl
export do="--dry-run=client -o yaml"
export now="--force --grace-period=0"

log "Starting environment setup for all 33 questions..."

# ============================================================
# Q1 — Redis pod in web namespace
# ============================================================
log "Q1: Setting up web namespace..."
kubectl create namespace web --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# Q2 — Secret + pod (uses web namespace from Q1)
# ============================================================
log "Q2: web namespace already exists from Q1"

# ============================================================
# Q3 — Resource requests pod
# ============================================================
log "Q3: Setting up pod-resources namespace..."
kubectl create namespace pod-resources --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# Q4 — ConfigMap + volume mount
# ============================================================
log "Q4: Setting up configmap-ns namespace..."
kubectl create namespace configmap-ns --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# Q5 — Service account
# ============================================================
log "Q5: Setting up production namespace + service account..."
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl create serviceaccount restrictedservice -n production --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment app-a --image=nginx -n production --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# ============================================================
# Q6 — Liveness + readiness probes
# ============================================================
log "Q6: production namespace exists from Q5"

# ============================================================
# Q7 — Pod logs to file
# ============================================================
log "Q7: Setting up counter pod environment..."
mkdir -p /opt/KDOB00201
touch /opt/KDOB00201/log_Output.txt
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: counter-pod
spec:
  containers:
  - name: counter-container
    image: busybox
    args: [/bin/sh, -c, 'i=0; while true; do echo "\$i: \$(date)"; i=\$((i+1)); sleep 1; done']
EOF

# ============================================================
# Q8 — CPU stress pods
# ============================================================
log "Q8: Setting up cpu-stress namespace with stress pods..."
kubectl create namespace cpu-stress --dry-run=client -o yaml | kubectl apply -f -
mkdir -p /opt/KDOBG0301
touch /opt/KDOBG0301/pod.txt
# Deploy stress pods with different CPU usage
for i in 1 2 3; do
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: stress-pod-$i
  namespace: cpu-stress
spec:
  containers:
  - name: stress
    image: busybox
    command: ["/bin/sh", "-c", "while true; do echo \$((i*i)); done"]
    resources:
      requests:
        cpu: ${i}00m
EOF
done
# Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml 2>/dev/null || true
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' 2>/dev/null || warn "Metrics server patch failed — may need manual setup"

# ============================================================
# Q9 — Pod with args + JSON output
# ============================================================
log "Q9: Setting up directories for pod output..."
mkdir -p /opt/KDPD00101
touch /opt/KDPD00101/out1.json

# ============================================================
# Q10 — Deployment with env var
# ============================================================
log "Q10: Setting up kdpd00201 namespace..."
kubectl create namespace kdpd00201 --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# Q11 — Rolling update + rollback
# ============================================================
log "Q11: Setting up kdpd00202 namespace + app deployment..."
kubectl create namespace kdpd00202 --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment app --image=nginx:1.12 -n kdpd00202 --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# Q12 — Scale deployment + NodePort service
# ============================================================
log "Q12: Setting up kdsn00101 namespace + deployment..."
kubectl create namespace kdsn00101 --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment kdsn00101-deployment --image=nginx -n kdsn00101 --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# Q13 — Ambassador pattern (HAProxy sidecar)
# ============================================================
log "Q13: Setting up ambassador scenario..."
kubectl create namespace ambassador-ns --dry-run=client -o yaml | kubectl apply -f -
mkdir -p /opt/KDMC00101
cat <<EOF > /opt/KDMC00101/haproxy.cfg
global
    daemon
defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
frontend http_front
    bind *:90
    default_backend http_back
backend http_back
    server nginx nginxsvc:5050
EOF
# Create the nginx service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginxsvc
  namespace: ambassador-ns
spec:
  selector:
    app: nginx-backend
  ports:
  - port: 90
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-backend
  namespace: ambassador-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-backend
  template:
    metadata:
      labels:
        app: nginx-backend
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# ============================================================
# Q14 — CronJob
# ============================================================
log "Q14: Setting up CronJob directory..."
mkdir -p /opt/KDPD00301

# ============================================================
# Q15 — Fix broken deployment
# ============================================================
log "Q15: Creating broken deployment..."
kubectl create deployment failing --image=nginx:X1.1 --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# Q16 — Network policy
# ============================================================
log "Q16: Setting up network policy scenario..."
kubectl create namespace netpol-ns --dry-run=client -o yaml | kubectl apply -f -
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: kdsn00201-newpod
  namespace: netpol-ns
  labels:
    run: kdsn00201-newpod
spec:
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
  namespace: netpol-ns
  labels:
    role: web
spec:
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: storage-pod
  namespace: netpol-ns
  labels:
    role: storage
spec:
  containers:
  - name: nginx
    image: nginx
EOF

# ============================================================
# Q17 — Find broken pod with failing liveness probe
# ============================================================
log "Q17: Setting up broken pod scenario..."
kubectl create namespace broken-ns --dry-run=client -o yaml | kubectl apply -f -
mkdir -p /opt/KDOB00401
touch /opt/KDOB00401/broken.txt
touch /opt/KDOB00401/error.txt
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-app
  namespace: broken-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: broken-app
  template:
    metadata:
      labels:
        app: broken-app
    spec:
      containers:
      - name: broken-container
        image: nginx
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
EOF

# ============================================================
# Q18 — PV + PVC + Pod
# ============================================================
log "Q18: Setting up PV scenario..."
mkdir -p /opt/KDSP00101/data

# ============================================================
# Q19 — Sidecar logging deployment
# ============================================================
log "Q19: Setting up sidecar logging scenario..."
mkdir -p /opt/KDMC00102
cat <<EOF > /opt/KDMC00102/fluentd-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: default
data:
  fluentd.conf: |
    <source>
      @type tail
      path /tmp/log/input.log
      pos_file /tmp/log/input.log.pos
      tag myapp.access
      <parse>
        @type none
      </parse>
    </source>
    <match myapp.access>
      @type file
      path /tmp/log/output
      append true
      <format>
        @type json
      </format>
    </match>
EOF

# ============================================================
# Q20 — Readiness probe on deployment
# ============================================================
log "Q20: Setting up staging namespace..."
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -
mkdir -p /home/$(whoami)/spicy-picachu
kubectl create deployment backend-deployment -n staging --image=nginx --port=8081 --dry-run=client -o yaml > /home/$(whoami)/spicy-picachu/backup-deployment.yaml

# ============================================================
# Q21 — Service account on deployment
# ============================================================
log "Q21: Setting up frontend namespace..."
kubectl create namespace frontend --dry-run=client -o yaml | kubectl apply -f -
kubectl create serviceaccount app -n frontend --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment app-1 --image=nginx -n frontend --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# Q22 — RBAC fix for deployment reader
# ============================================================
log "Q22: Setting up gorilla namespace with buffalo deployment..."
kubectl create namespace gorilla --dry-run=client -o yaml | kubectl apply -f -
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: buffalo-deployment
  namespace: gorilla
  labels:
    app: buffalo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: buffalo
  template:
    metadata:
      labels:
        app: buffalo
    spec:
      containers:
      - name: buffalo-container
        image: bitnami/kubectl:latest
        command: ["/bin/sh", "-c"]
        args:
          - "while true; do kubectl get deployments -n gorilla; sleep 5; done"
EOF

# ============================================================
# Q23 — Deployment + NodePort service
# ============================================================
log "Q23: Setting up ckad00017 namespace..."
kubectl create namespace ckad00017 --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment cka00017-deployment --image=nginx -n ckad00017 --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# Q24 — Resource requests pod
# ============================================================
log "Q24: pod-resources namespace exists from Q3"

# ============================================================
# Q25 — Deployment with env + expose
# ============================================================
log "Q25: Setting up ckad00014 namespace..."
kubectl create namespace ckad00014 --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# Q26 — Fix API deprecation
# ============================================================
log "Q26: Setting up API deprecation scenario..."
kubectl create namespace cobra --dry-run=client -o yaml | kubectl apply -f -
mkdir -p /credible-mite
cat <<EOF > /credible-mite/www.yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: web-deployment
  namespace: cobra
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:stable
        ports:
        - containerPort: 80
EOF

# ============================================================
# Q27 — Secret as env variable
# ============================================================
log "Q27: default namespace exists"

# ============================================================
# Q28 — Rolling update + rollback
# ============================================================
log "Q28: Setting up ckad00015 namespace..."
kubectl create namespace ckad00015 --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment web1 --image=lfccncf/nginx:1.12.2 -n ckad00015 --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || \
kubectl create deployment web1 --image=nginx:1.12 -n ckad00015 --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# Q29 — Security context
# ============================================================
log "Q29: Setting up quetzal namespace..."
kubectl create namespace quetzal --dry-run=client -o yaml | kubectl apply -f -
mkdir -p /home/$(whoami)/daring-moccasin
kubectl create deployment broker-deployment --image=nginx -n quetzal --dry-run=client -o yaml > /home/$(whoami)/daring-moccasin/broker-deployment.yaml
kubectl apply -f /home/$(whoami)/daring-moccasin/broker-deployment.yaml

# ============================================================
# Q30 — Network policy
# ============================================================
log "Q30: Setting up ckad00018 namespace..."
kubectl create namespace ckad00018 --dry-run=client -o yaml | kubectl apply -f -
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ckad00018-newpod
  namespace: ckad00018
  labels:
    role: ckad00018-newpod
spec:
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: web
  namespace: ckad00018
  labels:
    role: web
spec:
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: db
  namespace: ckad00018
  labels:
    role: db
spec:
  containers:
  - name: nginx
    image: nginx
EOF

# ============================================================
# Q31 — Canary deployment
# ============================================================
log "Q31: Setting up canary deployment scenario..."
kubectl create namespace goshark --dry-run=client -o yaml | kubectl apply -f -
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: current-krill-deployment
  namespace: goshark
spec:
  replicas: 5
  selector:
    matchLabels:
      app: krill
  template:
    metadata:
      labels:
        app: krill
    spec:
      containers:
      - name: nginx
        image: nginx:stable
---
apiVersion: v1
kind: Service
metadata:
  name: krill-service
  namespace: goshark
spec:
  selector:
    app: krill
  ports:
  - port: 8085
    targetPort: 80
EOF

# ============================================================
# Q32 — Memory limits + namespace quota
# ============================================================
log "Q32: Setting up grayscale namespace with quota..."
kubectl create namespace grayscale --dry-run=client -o yaml | kubectl apply -f -
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: mem-quota
  namespace: grayscale
spec:
  hard:
    limits.memory: "512Mi"
    requests.memory: "256Mi"
EOF
kubectl create deployment nosql --image=mongo:7.0.0 -n grayscale --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# Q33 — Docker build + export
# ============================================================
log "Q33: Setting up Dockerfile scenario..."
mkdir -p /human-stork/build
echo "Hello from my container!" > /human-stork/build/index.html
cat <<EOF > /human-stork/build/Dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html
EXPOSE 80
EOF

# ============================================================
# TASK 01 — RBAC scraper
# ============================================================
log "Task01: Setting up cute-panda namespace..."
kubectl create namespace cute-panda --dry-run=client -o yaml | kubectl apply -f -
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scraper
  namespace: cute-panda
spec:
  replicas: 1
  selector:
    matchLabels:
      app: scraper
  template:
    metadata:
      labels:
        app: scraper
    spec:
      containers:
      - name: scraper-container
        image: bitnami/kubectl:latest
        command: ["/bin/sh", "-c"]
        args:
          - "while true; do kubectl get pods; sleep 5; done"
EOF
kubectl create role pod-reader-role --verb=get,list,watch --resource=pods -n cute-panda --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# TASK 02 — CronJob advanced
# ============================================================
log "Task02: CronJob scenario ready (default namespace)"

# ============================================================
# TASK 03 — Deployment + NodePort
# ============================================================
log "Task03: Setting up prod namespace..."
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment nginx-deployment --image=nginx:stable -n prod --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# TASK 04 — Security context
# ============================================================
log "Task04: Setting up grubworm namespace..."
kubectl create namespace grubworm --dry-run=client -o yaml | kubectl apply -f -
mkdir -p /home/$(whoami)/daring-moccasin
cat <<EOF > /home/$(whoami)/daring-moccasin/store-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: store-deployment
  namespace: grubworm
spec:
  replicas: 1
  selector:
    matchLabels:
      app: store
  template:
    metadata:
      labels:
        app: store
    spec:
      containers:
      - name: store-container
        image: busybox
        command: ["/bin/sh", "-c", "sleep 3600"]
EOF
kubectl apply -f /home/$(whoami)/daring-moccasin/store-deployment.yaml

# ============================================================
# TASK 05 — API deprecation fix
# ============================================================
log "Task05: Setting up API deprecation scenario..."
kubectl create namespace garfish --dry-run=client -o yaml | kubectl apply -f -
mkdir -p /home/$(whoami)/credible-mite
cat <<EOF > /home/$(whoami)/credible-mite/web.yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: web-deployment
  namespace: garfish
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:stable
        ports:
        - containerPort: 80
        volumeMounts:
        - mountPath: /var/log/nginx
          name: logs
      volumes:
      - name: logs
        emptyDir: {}
EOF

# ============================================================
# TASK 06 — Resource quota + requests/limits
# ============================================================
log "Task06: pod-resources namespace exists from Q3"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
  namespace: pod-resources
spec:
  hard:
    requests.cpu: "200m"
    requests.memory: "256Mi"
    limits.cpu: "400m"
    limits.memory: "512Mi"
EOF

# ============================================================
# TASK 07 — Readiness probe on deployment
# ============================================================
log "Task07: prod namespace exists from Task03"
mkdir -p /home/$(whoami)/spicy-pikachu
cat <<EOF > /home/$(whoami)/spicy-pikachu/app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
  namespace: prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 8081
EOF
kubectl apply -f /home/$(whoami)/spicy-pikachu/app-deployment.yaml

# ============================================================
# TASK 08 — Rolling update + rollback
# ============================================================
log "Task08: Setting up webapp in prod namespace..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: nginx
        image: nginx:stable
EOF

# ============================================================
# TASK 09 — Ingress
# ============================================================
log "Task09: Setting up external namespace..."
kubectl create namespace external --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment web-app --image=nginx:stable -n external --dry-run=client -o yaml | kubectl apply -f -
kubectl expose deployment web-app -n external --port=8080 --target-port=80 --name=web-app --dry-run=client -o yaml | kubectl apply -f -

# ============================================================
# TASK 10 — RBAC fix for honeybee
# ============================================================
log "Task10: gorilla namespace exists from Q22"
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: honeybee-deployment
  namespace: gorilla
  labels:
    app: honeybee-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: honeybee-deployment
  template:
    metadata:
      labels:
        app: honeybee-deployment
    spec:
      containers:
      - name: honeybee-container
        image: bitnami/kubectl:latest
        command: ["/bin/sh", "-c"]
        args:
          - "while true; do kubectl get pods -n gorilla; sleep 5; done"
EOF

# ============================================================
# TASK 11 — Docker build
# ============================================================
log "Task11: Setting up Docker build scenario..."
mkdir -p /home/$(whoami)/build
echo "This is a web server test" > /home/$(whoami)/build/index.html
cat <<EOF > /home/$(whoami)/build/Dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html
EXPOSE 80
EOF

# ============================================================
# TASK 12 — Canary deployment
# ============================================================
log "Task12: Setting up moose namespace canary scenario..."
kubectl create namespace moose --dry-run=client -o yaml | kubectl apply -f -
mkdir -p /home/$(whoami)/settled-leopard
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: current-chipmunk-deployment
  namespace: moose
spec:
  replicas: 5
  selector:
    matchLabels:
      app: chipmunk
  template:
    metadata:
      labels:
        app: chipmunk
    spec:
      containers:
      - name: nginx
        image: nginx:stable
---
apiVersion: v1
kind: Service
metadata:
  name: chipmunk-service
  namespace: moose
spec:
  type: NodePort
  selector:
    app: chipmunk
  ports:
  - port: 8080
    targetPort: 80
    nodePort: 30000
EOF

# ============================================================
# TASK 13 — Move secrets from env to Secret
# ============================================================
log "Task13: Setting up relaxed-shark namespace..."
kubectl create namespace relaxed-shark --dry-run=client -o yaml | kubectl apply -f -
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
  namespace: relaxed-shark
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres-container
        image: postgres:latest
        env:
        - name: POSTGRES_USER
          value: "myuser"
        - name: POSTGRES_DB
          value: "mydb"
        - name: POSTGRES_PASSWORD
          value: "mysecretpassword"
        ports:
        - containerPort: 5432
EOF

# ============================================================
# TASK 14 — Fix broken Ingress
# ============================================================
log "Task14: Setting up content-marlin scenario..."
kubectl create namespace content-marlin --dry-run=client -o yaml | kubectl apply -f -
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: content-marlin-deployment
  namespace: content-marlin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: content-marlin
  template:
    metadata:
      labels:
        app: content-marlin
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: wrong-service-name
  namespace: content-marlin
spec:
  selector:
    app: content-marlin
  ports:
  - port: 8080
    targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: content-marlin-ingress
  namespace: content-marlin
spec:
  rules:
  - host: "content-marlin.local"
    http:
      paths:
      - path: "/content-marlin"
        pathType: Prefix
        backend:
          service:
            name: wrong-service-name
            port:
              number: 9999
EOF

# ============================================================
# TASK 15 — Network policy
# ============================================================
log "Task15: Setting up charming-macaw namespace..."
kubectl create namespace charming-macaw --dry-run=client -o yaml | kubectl apply -f -
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: newpod
  namespace: charming-macaw
  labels:
    role: other
spec:
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: front
  namespace: charming-macaw
  labels:
    role: front
spec:
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: db
  namespace: charming-macaw
  labels:
    role: db
spec:
  containers:
  - name: nginx
    image: nginx
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-front
  namespace: charming-macaw
spec:
  podSelector:
    matchLabels:
      role: newpod
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: front
  egress:
  - to:
    - podSelector:
        matchLabels:
          role: front
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-db
  namespace: charming-macaw
spec:
  podSelector:
    matchLabels:
      role: newpod
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: db
  egress:
  - to:
    - podSelector:
        matchLabels:
          role: db
EOF

# ============================================================
# TASK 16 — Memory limits + namespace quota
# ============================================================
log "Task16: Setting up haddock namespace..."
kubectl create namespace haddock --dry-run=client -o yaml | kubectl apply -f -
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: mem-quota
  namespace: haddock
spec:
  hard:
    limits.memory: "512Mi"
    requests.memory: "256Mi"
EOF
mkdir -p /home/$(whoami)/chief-cardinal
cat <<EOF > /home/$(whoami)/chief-cardinal/nosql.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nosql
  namespace: haddock
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nosql
  template:
    metadata:
      labels:
        app: nosql
    spec:
      containers:
      - name: mongodb
        image: mongo:4.4
        ports:
        - containerPort: 27017
EOF
kubectl apply -f /home/$(whoami)/chief-cardinal/nosql.yaml 2>/dev/null || true

# ============================================================
# TASK 17 — Update deployment container name + image
# ============================================================
log "Task17: Setting up rapid-goat namespace..."
kubectl create namespace rapid-goat --dry-run=client -o yaml | kubectl apply -f -
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: busybox
  namespace: rapid-goat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: busybox
  template:
    metadata:
      labels:
        app: busybox
    spec:
      containers:
      - name: busybox-container
        image: busybox:stable
        command: ["/bin/sh", "-c", "sleep 3600"]
EOF

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}ALL ENVIRONMENTS SETUP COMPLETE!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Namespaces created:"
kubectl get namespaces | grep -v "kube-\|default\|cert-manager" | tail -n +2
echo ""
echo -e "${YELLOW}Remember your exam aliases:${NC}"
echo "  alias k=kubectl"
echo "  export do='--dry-run=client -o yaml'"
echo "  export now='--force --grace-period=0'"
echo ""
echo -e "${GREEN}Now open the questions doc and start solving!${NC}"
