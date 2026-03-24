#!/bin/bash
# ============================================================
# CKAD VERIFY SCRIPT — check your answers
# Run after attempting each question
# Usage: ./ckad_verify_all.sh <question_number>
# Example: ./ckad_verify_all.sh 1
# ============================================================
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
pass() { echo -e "${GREEN}✓ PASS${NC} $1"; }
fail() { echo -e "${RED}✗ FAIL${NC} $1"; }
info() { echo -e "${YELLOW}→${NC} $1"; }

Q=$1
echo "Verifying Question $Q..."
echo "========================"

case $Q in
1)
  info "Checking pod 'cache' in namespace 'web'..."
  kubectl get pod cache -n web &>/dev/null && pass "Pod exists" || fail "Pod not found"
  kubectl get pod cache -n web -o jsonpath='{.spec.containers[0].image}' | grep -q "redis:3.2" && pass "Correct image redis:3.2" || fail "Wrong image"
  kubectl get pod cache -n web -o jsonpath='{.spec.containers[0].ports[0].containerPort}' | grep -q "6379" && pass "Port 6379 exposed" || fail "Port not set"
  kubectl get pod cache -n web -o jsonpath='{.status.phase}' | grep -q "Running" && pass "Pod is Running" || fail "Pod not running"
  ;;
2)
  info "Checking secret and nginx-secret pod..."
  kubectl get secret another-secret -n web &>/dev/null && pass "Secret exists" || fail "Secret not found"
  kubectl get secret another-secret -n web -o jsonpath='{.data.key1}' | base64 -d | grep -q "value4" && pass "Secret has key1=value4" || fail "Wrong secret value"
  kubectl get pod nginx-secret -n web &>/dev/null && pass "Pod exists" || fail "Pod not found"
  kubectl get pod nginx-secret -n web -o yaml | grep -q "COOL_VARIABLE" && pass "COOL_VARIABLE env var set" || fail "COOL_VARIABLE missing"
  kubectl get pod nginx-secret -n web -o yaml | grep -q "secretKeyRef" && pass "Secret reference used" || fail "Not using secretKeyRef"
  ;;
3)
  info "Checking nginx-resources pod..."
  kubectl get pod nginx-resources -n pod-resources &>/dev/null && pass "Pod exists" || fail "Pod not found"
  kubectl get pod nginx-resources -n pod-resources -o jsonpath='{.spec.containers[0].resources.requests.cpu}' | grep -q "200m" && pass "CPU request 200m" || fail "CPU request wrong"
  kubectl get pod nginx-resources -n pod-resources -o jsonpath='{.spec.containers[0].resources.requests.memory}' | grep -q "1Gi" && pass "Memory request 1Gi" || fail "Memory request wrong"
  ;;
4)
  info "Checking ConfigMap and nginx-configmap pod..."
  kubectl get configmap another-config -n configmap-ns &>/dev/null && pass "ConfigMap exists" || fail "ConfigMap not found"
  kubectl get pod nginx-configmap -n configmap-ns &>/dev/null && pass "Pod exists" || fail "Pod not found"
  kubectl get pod nginx-configmap -n configmap-ns -o yaml | grep -q "/also/a/path" && pass "Volume mounted at /also/a/path" || fail "Wrong mount path"
  ;;
5)
  info "Checking service account on app-a deployment..."
  kubectl get deploy app-a -n production -o jsonpath='{.spec.template.spec.serviceAccountName}' | grep -q "restrictedservice" && pass "ServiceAccount set correctly" || fail "Wrong service account"
  ;;
6)
  info "Checking probes on probe-pod..."
  kubectl get pod probe-pod -n production &>/dev/null && pass "Pod exists" || fail "Pod not found"
  kubectl get pod probe-pod -n production -o yaml | grep -q "livenessProbe" && pass "Liveness probe configured" || fail "Liveness probe missing"
  kubectl get pod probe-pod -n production -o yaml | grep -q "readinessProbe" && pass "Readiness probe configured" || fail "Readiness probe missing"
  kubectl get pod probe-pod -n production -o yaml | grep -q "/healthz" && pass "Liveness path /healthz" || fail "Wrong liveness path"
  kubectl get pod probe-pod -n production -o yaml | grep -q "/started" && pass "Readiness path /started" || fail "Wrong readiness path"
  ;;
7)
  info "Checking counter pod and log file..."
  kubectl get pod counter-pod &>/dev/null && pass "counter-pod exists" || fail "counter-pod not found"
  [ -f "/opt/KDOB00201/log_Output.txt" ] && pass "Output file exists" || fail "Output file missing"
  [ -s "/opt/KDOB00201/log_Output.txt" ] && pass "Output file has content" || fail "Output file is empty"
  ;;
8)
  info "Checking cpu-stress pods and output file..."
  [ -f "/opt/KDOBG0301/pod.txt" ] && pass "Output file exists" || fail "Output file missing"
  [ -s "/opt/KDOBG0301/pod.txt" ] && pass "Pod name written to file" || fail "File is empty"
  cat /opt/KDOBG0301/pod.txt 2>/dev/null && echo "" || true
  ;;
9)
  info "Checking app1 pod and JSON output..."
  kubectl get pod app1 &>/dev/null && pass "Pod app1 exists" || fail "Pod not found"
  kubectl get pod app1 -o jsonpath='{.spec.containers[0].name}' | grep -q "app1cont" && pass "Container named app1cont" || fail "Wrong container name"
  [ -f "/opt/KDPD00101/out1.json" ] && pass "JSON file exists" || fail "JSON file missing"
  [ -s "/opt/KDPD00101/out1.json" ] && pass "JSON file has content" || fail "JSON file empty"
  ;;
10)
  info "Checking frontend deployment..."
  kubectl get deploy frontend -n kdpd00201 &>/dev/null && pass "Deployment exists" || fail "Deployment not found"
  kubectl get deploy frontend -n kdpd00201 -o jsonpath='{.spec.replicas}' | grep -q "4" && pass "4 replicas" || fail "Wrong replicas"
  kubectl get deploy frontend -n kdpd00201 -o yaml | grep -q "NGINX_PORT" && pass "NGINX_PORT env var set" || fail "NGINX_PORT missing"
  kubectl get deploy frontend -n kdpd00201 -o yaml | grep -q "8080" && pass "Port 8080" || fail "Wrong port"
  ;;
11)
  info "Checking rolling update strategy..."
  kubectl get deploy web1 -n kdpd00202 -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' | grep -q "5%" && pass "maxSurge 5%" || fail "maxSurge wrong"
  kubectl get deploy web1 -n kdpd00202 -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}' | grep -q "2%" && pass "maxUnavailable 2%" || fail "maxUnavailable wrong"
  ;;
12)
  info "Checking deployment labels and NodePort service..."
  kubectl get deploy kdsn00101-deployment -n kdsn00101 -o jsonpath='{.spec.template.metadata.labels.func}' | grep -q "webFrontEnd" && pass "Label func=webFrontEnd" || fail "Label missing"
  kubectl get deploy kdsn00101-deployment -n kdsn00101 -o jsonpath='{.spec.replicas}' | grep -q "4" && pass "4 replicas" || fail "Wrong replicas"
  kubectl get svc cherry -n kdsn00101 &>/dev/null && pass "Service cherry exists" || fail "Service not found"
  kubectl get svc cherry -n kdsn00101 -o jsonpath='{.spec.type}' | grep -q "NodePort" && pass "NodePort type" || fail "Wrong service type"
  ;;
14)
  info "Checking CronJob hello..."
  kubectl get cronjob hello &>/dev/null && pass "CronJob exists" || fail "CronJob not found"
  kubectl get cronjob hello -o jsonpath='{.spec.schedule}' | grep -q "*/1" && pass "Schedule every minute" || fail "Wrong schedule"
  kubectl get cronjob hello -o jsonpath='{.spec.jobTemplate.spec.activeDeadlineSeconds}' | grep -q "22" && pass "activeDeadlineSeconds 22" || fail "activeDeadlineSeconds wrong"
  ;;
15)
  info "Checking failing deployment fix..."
  kubectl get deploy failing &>/dev/null && pass "Deployment exists" || fail "Deployment not found"
  kubectl get deploy failing -o jsonpath='{.spec.template.spec.containers[0].image}' | grep -qv "X1.1" && pass "Image fixed" || fail "Image still has X1.1"
  ;;
18)
  info "Checking PV, PVC, and Pod..."
  kubectl get pv task-pv-volume &>/dev/null && pass "PV exists" || fail "PV not found"
  kubectl get pvc task-pv-claim &>/dev/null && pass "PVC exists" || fail "PVC not found"
  kubectl get pvc task-pv-claim -o jsonpath='{.status.phase}' | grep -q "Bound" && pass "PVC is Bound" || fail "PVC not bound"
  [ -f "/opt/KDSP00101/data/index.html" ] && pass "index.html exists" || fail "index.html missing"
  grep -q "Acct=Finance" /opt/KDSP00101/data/index.html 2>/dev/null && pass "Content correct" || fail "Wrong content"
  ;;
21)
  info "Checking service account on app-1..."
  kubectl get deploy app-1 -n frontend -o jsonpath='{.spec.template.spec.serviceAccountName}' | grep -q "app" && pass "ServiceAccount set to app" || fail "Wrong service account"
  ;;
22)
  info "Checking RBAC for buffalo deployment..."
  kubectl get role deployment-reader -n gorilla &>/dev/null && pass "Role exists" || fail "Role not found"
  kubectl get rolebinding read-deployments-binding -n gorilla &>/dev/null && pass "RoleBinding exists" || fail "RoleBinding not found"
  ;;
28)
  info "Checking rolling update and rollback..."
  kubectl get deploy web1 -n ckad00015 -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' | grep -q "2" && pass "maxSurge 2" || fail "maxSurge wrong"
  kubectl get deploy web1 -n ckad00015 -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}' | grep -q "5" && pass "maxUnavailable correct" || fail "maxUnavailable wrong"
  ;;
29)
  info "Checking security context..."
  kubectl get deploy broker-deployment -n quetzal -o yaml | grep -q "runAsUser" && pass "runAsUser set" || fail "runAsUser missing"
  kubectl get deploy broker-deployment -n quetzal -o yaml | grep -q "allowPrivilegeEscalation" && pass "allowPrivilegeEscalation set" || fail "allowPrivilegeEscalation missing"
  ;;
*)
  info "Manual verification needed for Q$Q"
  info "Run: kubectl get all -n <namespace>"
  ;;
esac
echo ""
