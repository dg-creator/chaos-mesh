# Recovery Demo

This file contains basic commands for running Chaos Mesh experiments and checking if the application recovers.

Namespace used in this project:

```bash
demo-app
```

---

## 1. Test application

Start port forwarding:

```bash
kubectl port-forward -n demo-app svc/frontend 8080:80
```

Open in browser:

```text
http://localhost:8080
```

Or test with curl:

```bash
curl.exe http://localhost:8080
```

Stop port forwarding:

```text
Ctrl + C
```

---

## 2. Pod Kill

This experiment kills one frontend pod. Kubernetes should create a new one.

### Observe

```bash
kubectl get pods -n demo-app -l app=frontend -w
```

### Start experiment

```bash
kubectl apply -f chaos-experiments/01-pod-kill.yaml
```

### Expected result

One frontend pod should change to `Terminating`, and a new pod should appear:

```text
Pending -> ContainerCreating -> Running
```

### Cleanup

```bash
kubectl delete -f chaos-experiments/01-pod-kill.yaml
```

---

## 3. Network Partition

This experiment blocks communication from backend to Redis.

### Start experiment

```bash
kubectl apply -f chaos-experiments/02-network-partition.yaml
```

### Test application

```bash
curl.exe http://localhost:8080
```

### Expected result

The application may return an error or timeout because backend cannot connect to Redis.

### Cleanup

```bash
kubectl delete -f chaos-experiments/02-network-partition.yaml
```

### Test recovery

```bash
curl.exe http://localhost:8080
```

---

## 4. Latency Injection

This experiment adds delay between backend and Redis.

### Test baseline response time

```bash
curl.exe -w "Total time: %{time_total}s\n" -o NUL -s http://localhost:8080
```

### Start experiment

```bash
kubectl apply -f chaos-experiments/03-latency-injection.yaml
```

### Test response time during experiment

```bash
curl.exe -w "Total time: %{time_total}s\n" -o NUL -s http://localhost:8080
```

### Expected result

The application should still work, but response time should be higher.

### Cleanup

```bash
kubectl delete -f chaos-experiments/03-latency-injection.yaml
```

---

## 5. CPU Stress

This experiment adds CPU load to one backend pod.

### Observe backend pods

```bash
kubectl get pods -n demo-app -l app=backend -w
```

### Start experiment

```bash
kubectl apply -f chaos-experiments/04-cpu-stress.yaml
```

### Test application

```bash
curl.exe http://localhost:8080
```

### Expected result

Backend should still run, but the application may respond slower.

### Cleanup

```bash
kubectl delete -f chaos-experiments/04-cpu-stress.yaml
```

---

## 6. Memory Stress

This experiment increases memory usage on one backend pod.

### Observe backend pods

```bash
kubectl get pods -n demo-app -l app=backend -w
```

### Start experiment

```bash
kubectl apply -f chaos-experiments/05-memory-stress.yaml
```

### Test application

```bash
curl.exe http://localhost:8080
```

### Expected result

Backend should still run. If memory usage is too high, the pod may restart.

### Cleanup

```bash
kubectl delete -f chaos-experiments/05-memory-stress.yaml
```

---

## 7. Emergency cleanup

If something goes wrong, remove all active experiments:

```bash
kubectl delete podchaos --all -n demo-app
kubectl delete networkchaos --all -n demo-app
kubectl delete stresschaos --all -n demo-app
```

Check if application pods are running:

```bash
kubectl get pods -n demo-app
```

If needed, restart deployments:

```bash
kubectl rollout restart deployment/frontend -n demo-app
kubectl rollout restart deployment/backend -n demo-app
kubectl rollout restart deployment/redis -n demo-app
```

---

## Short summary

The recovery demo shows this process:

```text
normal state -> failure -> observation -> cleanup -> normal state again
```