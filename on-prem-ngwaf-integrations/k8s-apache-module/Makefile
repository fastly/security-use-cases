.DEFAULT_GOAL = help

KUBEDEPLOYMENT?=k8s-apache-module-agent
DEPLOYMENTFILE?=deployment.yaml
NAMESPACE?=fastly-waf

DOCKERNAME?=apache-module

help: # Show all commands
	@egrep -h '\s#\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?\# "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

docker: # Build and load the Apache module Docker image
	docker build . -t my-local-images/apache-module:latest
	kind load docker-image my-local-images/apache-module:latest
	docker pull signalsciences/sigsci-agent:latest


drunexec: # Run Docker container locally for testing
	@docker run --publish 8888:80 --name $(DOCKERNAME) -it my-local-images/apache-module:latest

dclean: # Stop and remove local Docker container
	-docker kill $(DOCKERNAME)
	-docker rm $(DOCKERNAME)

drerunexec: # Clean and re-run Docker container
	make dclean
	make drunexec

# Environment variables $NGWAFACCESSKEYID and $NGWAFACCESSKEYSECRET must already be set before running `make build`
build: # Build and deploy to Kubernetes
	-@ kubectl create secret generic sigsci.my-site-name-here --from-literal=accesskeyid=${NGWAFACCESSKEYID} --from-literal=secretaccesskey=${NGWAFACCESSKEYSECRET}  
# --namespace ${NAMESPACE}
	kubectl apply -f deployment.yaml
	-@ sleep 2
# -@ make demo

demo: # Port-forward service for testing
	echo "curl 127.0.0.1:8080 -i"
	kubectl port-forward service/k8s-apache-module-agent-service 8080:80

logs: # View NGWAF agent logs
	kubectl get pods | tail -n1 | awk '{print $$1}' | xargs -I {} kubectl logs {} -c sigsci-agent
# kubectl get pods | tail -n1 | awk '{print $$1}' | xargs -I {} kubectl logs {} --all-containers=true

clean: # Delete Kubernetes resources
	- kubectl delete -f deployment.yaml
	sleep 3

# kubectl get deployments
# - kubectl get deployment $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs kubectl delete deployment
# - kubectl get services $(KUBEDEPLOYMENT)-lb | awk '{print $$1}' | xargs kubectl delete services
# - kubectl delete secret ngwaf-agent-keys

describe: # Describe pods
	kubectl describe pods 
# -n ${NAMESPACE}

get: # Get pods and services
	- kubectl get pods
	- kubectl get services
# - kubectl get services $(KUBEDEPLOYMENT)-lb


rebuild: # Clean and rebuild
	make clean; make build

exec: # Get pod name and exec command
	kubectl get pods | grep $(KUBEDEPLOYMENT) | awk '{print $$1}'
	kubectl get pods | grep $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin --tty {} -c sigsci-agent -- /bin/sh

# kubectl get pods | grep $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin -c apache --tty {} -- /bin/sh

# kubectl exec --stdin --tty ngwaf-revproxy-123 -- /bin/sh

# helpful command when troubleshooting kubectl secrets
# https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/
# kubectl get secrets
# kubectl describe secret ngwaf-agent-keys
# kubectl get secret ngwaf-agent-keys -o jsonpath='{.data}' | jq .accesskeyid -r | base64 -D
# kubectl delete secret ngwaf-agent-keys
# k9s is great too
