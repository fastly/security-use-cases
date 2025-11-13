.DEFAULT_GOAL = help

KUBEDEPLOYMENT?=k8-nginx-rev-proxy
DEPLOYMENTFILE?=deployment.yaml

help: # Show all commands
	@egrep -h '\s#\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?\# "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Environment variables $NGWAFACCESSKEYID and $NGWAFACCESSKEYSECRET must already be set before running `make build`
build: # Deploy the sigsci-agent reverse proxy and NGINX backend
	-@ kubectl create secret generic sigsci.my-site-name-here --from-literal=accesskeyid=${NGWAFACCESSKEYID} --from-literal=secretaccesskey=${NGWAFACCESSKEYSECRET}  
	kubectl apply -f deployment.yaml
	-@ sleep 2

demo: # Forward port to test the deployment locally
	@echo "Testing deployment with: curl http://127.0.0.1:8080"
	kubectl port-forward service/sigsci-revproxy-service 8080:80

logs: # Show logs from sigsci-agent
	kubectl get pods -l app=sigsci-revproxy | tail -n1 | awk '{print $$1}' | xargs -I {} kubectl logs {} -c sigsci-agent

logs-nginx: # Show logs from NGINX backend
	kubectl get pods -l app=nginx-backend | tail -n1 | awk '{print $$1}' | xargs -I {} kubectl logs {} -c nginx

clean: # Delete all resources
	- kubectl delete -f deployment.yaml
	- kubectl delete secret sigsci.my-site-name-here
	sleep 3

describe: # Describe all pods
	kubectl describe pods 

get: # Get all pods and services
	- kubectl get pods
	- kubectl get services

rebuild: # Clean and rebuild
	make clean; make build

# helpful command when troubleshooting kubectl secrets
# https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/
# kubectl get secrets
# kubectl describe secret sigsci.my-site-name-here
# kubectl get secret sigsci.my-site-name-here -o jsonpath='{.data}' | jq .accesskeyid -r | base64 -D
# kubectl delete secret sigsci.my-site-name-here
