FROM golang:latest

# Image metadata
LABEL com.signalsciences.sigsci-module-golang.examples="helloworld"
LABEL maintainer="Signal Sciences <support@fastly.com>"

# Install sigsci golang module example
RUN go install github.com/signalsciences/sigsci-module-golang/examples/helloworld@latest

ENTRYPOINT [ "helloworld" ]
