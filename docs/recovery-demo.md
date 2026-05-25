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

### Observed result

During the test, one frontend pod changed to Terminating. Then Kubernetes created a new pod, which went through Pending -> ContainerCreating -> Running. After recovery, both frontend pods were running again.

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

### Observed result

During the network partition test, the application was not reachable from curl. After removing the experiment and starting port-forward again, the application returned a normal response: Backend OK: Podłączono do Redis!.

Note: in this test, port-forward had to be started again to access the application locally.

### Cleanup

```bash
kubectl delete -f chaos-experiments/02-network-partition.yaml
```

### Test recovery

```bash
curl.exe http://localhost:8080
```

connection after port crash
```bash
kubectl port-forward -n demo-app svc/frontend 8080:80
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

### Observed result

Before the experiment, response time was about 0.0127s. During the latency experiment, response time was about 0.0140s. After cleanup, response time was about 0.0113s. In this run, the latency increase was small, but the application stayed available and returned to normal after cleanup.

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

### Observed result

During the CPU stress experiment, Grafana showed a clear CPU usage spike on one backend pod. After the experiment ended, CPU usage dropped back close to the baseline value.

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

### Observed result

During the memory stress experiment, Grafana showed a clear memory usage increase on one backend pod, up to about 96 MiB. After the experiment ended, memory usage returned close to the baseline value, around 34 MiB.

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