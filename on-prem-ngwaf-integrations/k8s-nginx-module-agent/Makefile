.DEFAULT_GOAL = help

KUBEDEPLOYMENT?=k8-nginx-module-agent
DEPLOYMENTFILE?=deployment.yaml
NAMESPACE?=fastly-waf

DOCKERNAME?=nginx-module

help: # Show all commands
	@egrep -h '\s#\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?\# "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

docker:
	docker build . -t my-local-images/nginx-module:latest
	kind load docker-image my-local-images/nginx-module:latest
	docker pull signalsciences/sigsci-agent:latest


drunexec:
# 	@docker run --publish 8888:8888 --publish 9999:9999 --name $(DOCKERNAME) --env SIGSCI_ACCESSKEYID=${NGWAFACCESSKEYID} --env SIGSCI_SECRETACCESSKEY=${NGWAFACCESSKEYSECRET} --env SIGSCI_WAF_DATA_LOG="/dev/stdout" --env SIGSCI_DEBUG_ALL_THE_THINGS="true" --env SIGSCI_REVPROXY_LISTENER="app1:{listener=http://0.0.0.0:8888,upstreams=https://http-me.edgecompute.app:443/,pass-host-header=false}; app2:{listener=http://0.0.0.0:9999, upstreams=https://http-me.glitch.me/,pass-host-header=false}" -it signalsciences/sigsci-agent
	@docker run --publish 8888:80 --name $(DOCKERNAME) -it my-local-images/nginx-module:latest

dclean:
	-docker kill $(DOCKERNAME)
	-docker rm $(DOCKERNAME)

drerunexec:
	make dclean
	make drunexec

# Environment variables $NGWAFACCESSKEYID and $NGWAFACCESSKEYSECRET must already be set before running `make build`
build:
	-@ kubectl create secret generic sigsci.my-site-name-here --from-literal=accesskeyid=${NGWAFACCESSKEYID} --from-literal=secretaccesskey=${NGWAFACCESSKEYSECRET}  
# --namespace ${NAMESPACE}
	kubectl apply -f deployment.yaml
	-@ sleep 2
# -@ make demo

demo:
	echo "curl 127.0.0.1:8080 -i"
	kubectl port-forward service/k8-nginx-module-agent-service 8080:80

logs:
	kubectl get pods | tail -n1 | awk '{print $$1}' | xargs -I {} kubectl logs {} -c sigsci-agent
# kubectl get pods | tail -n1 | awk '{print $$1}' | xargs -I {} kubectl logs {} --all-containers=true

clean:
	- kubectl delete -f deployment.yaml
	sleep 3

# kubectl get deployments
# - kubectl get deployment $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs kubectl delete deployment
# - kubectl get services $(KUBEDEPLOYMENT)-lb | awk '{print $$1}' | xargs kubectl delete services
# - kubectl delete secret ngwaf-agent-keys

describe:
	kubectl describe pods 
# -n ${NAMESPACE}

get:
	- kubectl get pods
	- kubectl get services
# - kubectl get services $(KUBEDEPLOYMENT)-lb


rebuild:
	make clean; make build

make exec:
	kubectl get pods | grep $(KUBEDEPLOYMENT) | awk '{print $$1}'
	kubectl get pods | grep $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin --tty {} -c sigsci-agent -- /bin/sh

# kubectl get pods | grep $(KUBEDEPLOYMENT) | awk '{print $$1}' | xargs -I {} echo kubectl exec --stdin -c nginx --tty {} -- /bin/sh

# kubectl exec --stdin --tty ngwaf-revproxy-123 -- /bin/sh

# helpful command when troubleshooting kubectl secrets
# https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/
# kubectl get secrets
# kubectl describe secret ngwaf-agent-keys
# kubectl get secret ngwaf-agent-keys -o jsonpath='{.data}' | jq .accesskeyid -r | base64 -D
# kubectl delete secret ngwaf-agent-keys
# k9s is great too