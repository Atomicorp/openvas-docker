.PHONY: docker all push
VERSION=$(shell git describe --always)

default:
	$(MAKE) all

all: docker

docker: 
	docker build -t grafana/openvas ./

push: docker
	docker tag grafana/openvas:latest grafana/openvas:$(VERSION)
	docker push grafana/openvas:$(VERSION)
	docker push grafana/openvas:latest
