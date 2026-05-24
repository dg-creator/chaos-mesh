#!/bin/bash
set -e

echo "🚀 Tworzenie klastra Kind..."
kind create cluster --config infrastructure/kind-config.yaml --name chaos-lab

echo "📦 Dodawanie repozytorium Helm dla Chaos Mesh..."
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

echo "🕸️ Instalacja Chaos Mesh..."
helm upgrade --install chaos-mesh chaos-mesh/chaos-mesh \
  --namespace chaos-mesh \
  --create-namespace \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/containerd/containerd.sock

echo "✅ Gotowe! Twój klaster i Chaos Mesh są zainstalowane."