DOCKERUSER?=ngwaf
DOCKERNAME?=my-apache2
DOCKERTAG?=latest
NGWAF_HOSTNAME?=apache
EXPOSE_PORT?=8080
# AGENT_CONF?=$(shell pwd)/agent.conf

build:
	docker build -t $(DOCKERUSER)/$(DOCKERNAME):$(DOCKERTAG) .

build-no-cache:
	docker build --no-cache -t $(DOCKERUSER)/$(DOCKERNAME):$(DOCKERTAG) .

run:
	make build
	docker run --name $(DOCKERNAME) --hostname $(NGWAF_HOSTNAME) -p $(EXPOSE_PORT):80 --env SIGSCI_ACCESSKEYID=${NGWAFACCESSKEYID} --env SIGSCI_SECRETACCESSKEY=${NGWAFACCESSKEYSECRET} --env SIGSCI_WAF_DATA_LOG="/dev/stdout"  -d -P $(DOCKERUSER)/$(DOCKERNAME):$(DOCKERTAG)

runexec:
	make build
	docker run --name $(DOCKERNAME) --hostname $(NGWAF_HOSTNAME) -p $(EXPOSE_PORT):80 --env SIGSCI_ACCESSKEYID=${NGWAFACCESSKEYID} --env SIGSCI_SECRETACCESSKEY=${NGWAFACCESSKEYSECRET} --env SIGSCI_WAF_DATA_LOG="/dev/stdout" -it -P $(DOCKERUSER)/$(DOCKERNAME):$(DOCKERTAG)

rerunexec:
	make clean
	make runexec

deploy:
	docker push $(DOCKERUSER)/$(DOCKERNAME):$(DOCKERTAG)
	
clean:
	-docker kill $(DOCKERNAME)
	-docker rm $(DOCKERNAME)

destroy:
	-docker kill $(DOCKERNAME)
	-docker rm $(DOCKERNAME)
	-docker rmi $(DOCKERUSER)/$(DOCKERNAME):$(DOCKERTAG)




