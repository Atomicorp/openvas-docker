.PHONY: docker all


default:
	$(MAKE) all


all: docker

docker: 
	docker build -t grafana/openvas ./
