DOCKERNAME?=localfastlyngwaf
# https://petstore3.swagger.io/
OPENAPISPECFILEPPETSTORE?="https://petstore3.swagger.io/api/v3/openapi.json"
OPENAPISPECFILE?="http://host.docker.internal:8080/api/apiInventory/1/reconstructed_swagger.json"
# OPENAPISPECFILE?="http://host.docker.internal:8080/api/apiInventory/1/provided_swagger.json"
# OPENAPISPECFILE?="https://http-me.edgecompute.app/static-assets/openapi-spec.json"

pull:
	docker pull signalsciences/sigsci-agent

run:
	@docker run --publish 8080:8888 --name $(DOCKERNAME) --env SIGSCI_ACCESSKEYID=${NGWAFACCESSKEYID} --env SIGSCI_SECRETACCESSKEY=${NGWAFACCESSKEYSECRET} --env SIGSCI_REVPROXY_LISTENER="app1:{listener=http://0.0.0.0:8888,upstreams=https://http-me.edgecompute.app:443/,pass-host-header=false}" -d signalsciences/sigsci-agent

runexec:
	@docker run --publish 8888:8888 --publish 9999:9999 --name $(DOCKERNAME) --env SIGSCI_ACCESSKEYID=${NGWAFACCESSKEYID} --env SIGSCI_SECRETACCESSKEY=${NGWAFACCESSKEYSECRET} --env SIGSCI_WAF_DATA_LOG="/dev/stdout" --env SIGSCI_DEBUG_ALL_THE_THINGS="true" --env SIGSCI_REVPROXY_LISTENER="app1:{listener=http://0.0.0.0:8888,upstreams=https://http-me.edgecompute.app:443/,pass-host-header=false}; app2:{listener=http://0.0.0.0:9999, upstreams=https://http-me.glitch.me/,pass-host-header=false}" -it signalsciences/sigsci-agent

runexecws:
	@docker run --publish 8888:8888 --publish 9999:9999 --name $(DOCKERNAME) --env SIGSCI_ACCESSKEYID=${NGWAFACCESSKEYID} --env SIGSCI_SECRETACCESSKEY=${NGWAFACCESSKEYSECRET} --env SIGSCI_INSPECT_WEBSOCKET="true" --env SIGSCI_WAF_DATA_LOG="/dev/stdout" --env SIGSCI_DEBUG_ALL_THE_THINGS="true" --env SIGSCI_REVPROXY_LISTENER="app1:{listener=http://0.0.0.0:8888,upstreams=https://http-me.edgecompute.app:443/,pass-host-header=false}; app2:{listener=http://0.0.0.0:9999, upstreams=https://qa-websockets-demo.edgecompute.app/, pass-host-header=false, inspect-websocket=true}" -it signalsciences/sigsci-agent

runexecapi:
	@docker run --publish 8888:8888 --publish 9999:9999 --name $(DOCKERNAME) --env SIGSCI_ACCESSKEYID=${NGWAFACCESSKEYIDPETSTORE} --env SIGSCI_SECRETACCESSKEY=${NGWAFACCESSKEYSECRETPETSTORE} --env SIGSCI_OPEN_API_SPEC_FILE=$(OPENAPISPECFILE) --env SIGSCI_WAF_DATA_LOG="/dev/stdout" --env SIGSCI_DEBUG_ALL_THE_THINGS="true" --env SIGSCI_REVPROXY_LISTENER="app1:{listener=http://0.0.0.0:8888,upstreams=https://http-me.edgecompute.app:443/,pass-host-header=false}; petstore:{listener=http://0.0.0.0:9999, upstreams=https://petstore.swagger.io/,pass-host-header=false}" -it signalsciences/sigsci-agent

runexecapipetstore:
	@docker run --publish 8888:8888 --publish 9999:9999 --name $(DOCKERNAME) --env SIGSCI_ACCESSKEYID=${NGWAFACCESSKEYIDPETSTORE} --env SIGSCI_SECRETACCESSKEY=${NGWAFACCESSKEYSECRETPETSTORE} --env SIGSCI_OPEN_API_SPEC_FILE=$(OPENAPISPECFILEPPETSTORE) --env SIGSCI_WAF_DATA_LOG="/dev/stdout" --env SIGSCI_DEBUG_ALL_THE_THINGS="true" --env SIGSCI_REVPROXY_LISTENER="app1:{listener=http://0.0.0.0:8888,upstreams=https://http-me.edgecompute.app:443/,pass-host-header=false}; petstore:{listener=http://0.0.0.0:9999, upstreams=https://petstore3.swagger.io/,pass-host-header=false}" -it signalsciences/sigsci-agent

apidemo:
	@echo "#### 2 requests will be valid"
	@echo "curl -H 'host:petstore3.swagger.io:80' -X GET 'http://0.0.0.0:9999/api/v3/user/login' -i"
	@echo "curl -H 'host:petstore3.swagger.io:80' -X DELETE 'http://0.0.0.0:9999/api/v3/user/alice' -i"
	@echo "#### 1 request will be blocked"
	@echo "curl -H "host:petstore3.swagger.io:80" -X POST 'http://0.0.0.0:9999/api/v3/user/bob' -i"

exec:
	docker exec -it $(DOCKERNAME) /bin/sh

clean:
	-docker kill $(DOCKERNAME)
	-docker rm $(DOCKERNAME)

rerun:
	make clean
	make run

rerunexec:
	make clean
	make runexec

rerunexecapi:
	make clean
	make runexecapi

rerunexecapipetstore:
	make clean
	make runexecapipetstore

rerunexecws:
	make clean
	make runexecws

