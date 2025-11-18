.DEFAULT_GOAL = help

KUBEDEPLOYMENT?=nginx-ingress-controller
DEPLOYMENTFILE?=deployment.yaml
NAMESPACE?=ingress-nginx
DOCKERNAME?=nginx-ingress-ngwaf
KIND_CLUSTER?=ngwaf-demo

help: # Show all commands
	@egrep -h '\s#\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?\# "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Docker and Kind Setup
docker: # Build Docker image and load into kind cluster
	@echo "Building custom NGINX Ingress Controller image with NGWAF module..."
	docker build . -t my-local-images/$(DOCKERNAME):latest
	@echo "Loading image into kind cluster..."
	kind load docker-image my-local-images/$(DOCKERNAME):latest --name $(KIND_CLUSTER) || \
		(echo "ERROR: Failed to load image. Is the kind cluster running?" && \
		 echo "Create cluster with: kind create cluster --name $(KIND_CLUSTER)" && exit 1)
	@echo "Image loaded successfully!"

# Environment variables $NGWAFACCESSKEYID and $NGWAFACCESSKEYSECRET must already be set before running `make build`
build: docker # Build Docker image and deploy all resources
	@echo "Creating NGWAF credentials secret..."
	-@ kubectl create secret generic sigsci.my-site-name-here \
		--from-literal=accesskeyid=${NGWAFACCESSKEYID} \
		--from-literal=secretaccesskey=${NGWAFACCESSKEYSECRET} \
		--namespace $(NAMESPACE) 2>/dev/null || \
		(kubectl create namespace $(NAMESPACE) && \
		 kubectl create secret generic sigsci.my-site-name-here \
		 	--from-literal=accesskeyid=${NGWAFACCESSKEYID} \
		 	--from-literal=secretaccesskey=${NGWAFACCESSKEYSECRET} \
		 	--namespace $(NAMESPACE))
	@echo "Deploying NGINX Ingress Controller with NGWAF..."
	kubectl apply -f $(DEPLOYMENTFILE)
	@echo "Waiting for deployment to be ready..."
	-@ sleep 5
	@echo ""
	@echo "Deployment complete! Use 'make demo' to test the ingress."

demo: # Forward port to test the deployment locally
	@echo "Port forwarding ingress controller to localhost:8080"
	@echo "Test with: curl http://127.0.0.1:8080 -H 'Host: demo.example.com'"
	@echo "Press Ctrl+C to stop port forwarding"
	kubectl port-forward -n $(NAMESPACE) service/ingress-nginx-controller 8080:80

logs: # Show logs from NGINX Ingress Controller
	@echo "Fetching NGINX Ingress Controller logs..."
	kubectl get pods -n $(NAMESPACE) -l app=$(KUBEDEPLOYMENT) | tail -n1 | awk '{print $$1}' | xargs -I {} kubectl logs -n $(NAMESPACE) {} -c nginx-ingress-controller --tail=100

logs-agent: # Show logs from sigsci-agent sidecar
	@echo "Fetching sigsci-agent logs..."
	kubectl get pods -n $(NAMESPACE) -l app=$(KUBEDEPLOYMENT) | tail -n1 | awk '{print $$1}' | xargs -I {} kubectl logs -n $(NAMESPACE) {} -c sigsci-agent --tail=100

logs-backend: # Show logs from demo backend
	@echo "Fetching demo backend logs..."
	kubectl get pods -n default -l app=demo-backend | tail -n1 | awk '{print $$1}' | xargs -I {} kubectl logs -n default {} --tail=100

logs-follow: # Follow NGINX Ingress Controller logs in real-time
	@echo "Following NGINX Ingress Controller logs (Ctrl+C to stop)..."
	kubectl get pods -n $(NAMESPACE) -l app=$(KUBEDEPLOYMENT) | tail -n1 | awk '{print $$1}' | xargs -I {} kubectl logs -n $(NAMESPACE) {} -c nginx-ingress-controller -f

logs-agent-follow: # Follow sigsci-agent logs in real-time
	@echo "Following sigsci-agent logs (Ctrl+C to stop)..."
	kubectl get pods -n $(NAMESPACE) -l app=$(KUBEDEPLOYMENT) | tail -n1 | awk '{print $$1}' | xargs -I {} kubectl logs -n $(NAMESPACE) {} -c sigsci-agent -f

clean: # Delete all Kubernetes resources
	@echo "Deleting all resources..."
	- kubectl delete -f $(DEPLOYMENTFILE)
	- kubectl delete secret sigsci.my-site-name-here -n $(NAMESPACE)
	@echo "Waiting for resources to be removed..."
	sleep 3
	@echo "Clean complete!"

describe: # Describe all pods in the ingress-nginx namespace
	@echo "Describing ingress controller pods..."
	kubectl describe pods -n $(NAMESPACE)
	@echo ""
	@echo "Describing backend pods..."
	kubectl describe pods -n default -l app=demo-backend

get: # Get all pods and services
	@echo "Pods in $(NAMESPACE) namespace:"
	- kubectl get pods -n $(NAMESPACE)
	@echo ""
	@echo "Services in $(NAMESPACE) namespace:"
	- kubectl get services -n $(NAMESPACE)
	@echo ""
	@echo "Ingress resources in default namespace:"
	- kubectl get ingress -n default
	@echo ""
	@echo "Demo backend in default namespace:"
	- kubectl get pods,services -n default -l app=demo-backend

rebuild: # Clean and rebuild everything
	make clean
	make build

exec: # Get shell in NGINX Ingress Controller container
	@echo "Opening shell in NGINX Ingress Controller..."
	kubectl get pods -n $(NAMESPACE) -l app=$(KUBEDEPLOYMENT) | tail -n1 | awk '{print $$1}' | xargs -I {} kubectl exec -n $(NAMESPACE) --stdin --tty {} -c nginx-ingress-controller -- /bin/sh

exec-agent: # Get shell in sigsci-agent container
	@echo "Opening shell in sigsci-agent..."
	kubectl get pods -n $(NAMESPACE) -l app=$(KUBEDEPLOYMENT) | tail -n1 | awk '{print $$1}' | xargs -I {} kubectl exec -n $(NAMESPACE) --stdin --tty {} -c sigsci-agent -- /bin/sh

test: # Run test requests through the ingress
	@echo "Running test requests..."
	@echo ""
	@echo "1. Normal request:"
	curl -s http://127.0.0.1:8080 -H "Host: demo.example.com" || echo "ERROR: Port forward not running. Run 'make demo' first."
	@echo ""
	@echo ""
	@echo "2. Request with SQL injection pattern:"
	curl -s "http://127.0.0.1:8080?id=1%20OR%201=1" -H "Host: demo.example.com" || echo "ERROR: Port forward not running. Run 'make demo' first."
	@echo ""
	@echo ""
	@echo "3. Request with XSS pattern:"
	curl -s "http://127.0.0.1:8080?search=<script>alert('xss')</script>" -H "Host: demo.example.com" || echo "ERROR: Port forward not running. Run 'make demo' first."
	@echo ""
	@echo ""
	@echo "Check your Fastly NGWAF dashboard to see these requests logged."

# Kind cluster management
kind-create: # Create a new kind cluster
	@echo "Creating kind cluster: $(KIND_CLUSTER)..."
	kind create cluster --name $(KIND_CLUSTER)
	@echo "Cluster created! Verify with: kubectl cluster-info --context kind-$(KIND_CLUSTER)"

kind-delete: # Delete the kind cluster
	@echo "Deleting kind cluster: $(KIND_CLUSTER)..."
	kind delete cluster --name $(KIND_CLUSTER)

kind-list: # List all kind clusters
	@echo "Available kind clusters:"
	kind get clusters

# Colima management
colima-start: # Start colima with recommended settings
	@echo "Starting colima with 4 CPUs, 8GB RAM, 50GB disk..."
	colima start --cpu 4 --memory 8 --disk 50

colima-stop: # Stop colima
	@echo "Stopping colima..."
	colima stop

colima-status: # Check colima status
	@echo "Colima status:"
	colima status

# Complete cleanup
clean-all: clean kind-delete # Clean everything including kind cluster

# Setup for first-time users
setup: colima-start kind-create # Initial setup: start colima and create kind cluster
	@echo ""
	@echo "Setup complete! Next steps:"
	@echo "1. Set your NGWAF credentials:"
	@echo "   export NGWAFACCESSKEYID='your-access-key-id'"
	@echo "   export NGWAFACCESSKEYSECRET='your-secret-access-key'"
	@echo ""
	@echo "2. Build and deploy:"
	@echo "   make build"
	@echo ""
	@echo "3. Test the deployment:"
	@echo "   make demo"

# Helpful command when troubleshooting kubectl secrets
# https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/
# kubectl get secrets -n ingress-nginx
# kubectl describe secret sigsci.my-site-name-here -n ingress-nginx
# kubectl get secret sigsci.my-site-name-here -n ingress-nginx -o jsonpath='{.data}' | jq .accesskeyid -r | base64 -D
