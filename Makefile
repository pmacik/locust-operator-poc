export SCENARIO ?= locust-test
export USERS ?= 100
export WORKERS ?= 5
export DURATION ?= 1m
export SPAWN_RATE ?= 20

PYTHON_VENV=.venv

LOCUST_NAMESPACE=locust-operator
LOCUST_OPERATOR_REPO=locust-k8s-operator
LOCUST_OPERATOR=locust-operator

.PHONY: setup-venv
setup-venv:
	python3 -m venv $(PYTHON_VENV)
	$(PYTHON_VENV)/bin/python3 -m pip install -r requirements.txt

.PHONY: clean
clean:
	oc delete --namespace $(LOCUST_NAMESPACE) cm locust.$(SCENARIO) --ignore-not-found --wait
	oc delete --namespace $(LOCUST_NAMESPACE) locusttest $(SCENARIO).test --ignore-not-found --wait

.PHONY: test
test:
	cat locust-test-template.yaml | envsubst | oc apply --namespace $(LOCUST_NAMESPACE) -f -
	oc create --namespace $(LOCUST_NAMESPACE) configmap locust.$(SCENARIO) --from-file locust_test.py

.PHONY: deploy-locust
deploy-locust:
	@kubectl create namespace $(LOCUST_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@if ! helm repo list --namespace $(LOCUST_NAMESPACE) | grep -q "$(LOCUST_OPERATOR_REPO)"; then \
		helm repo add $(LOCUST_OPERATOR_REPO) https://abdelrhmanhamouda.github.io/locust-k8s-operator/ --namespace $(LOCUST_NAMESPACE); \
	else \
		echo "Helm repo \"$(LOCUST_OPERATOR_REPO)\" already exists"; \
	fi
	@if ! helm list --namespace $(LOCUST_NAMESPACE) | grep -q "$(LOCUST_OPERATOR)"; then \
		helm install $(LOCUST_OPERATOR) locust-k8s-operator/locust-k8s-operator --namespace $(LOCUST_NAMESPACE); \
	else \
		echo "Helm release \"$(LOCUST_OPERATOR)\" already exists"; \
	fi

.PHONY: undeploy-locust
undeploy-locust:
	@kubectl delete namespace $(LOCUST_NAMESPACE) --wait
	@helm repo remove $(LOCUST_OPERATOR_REPO)

# to avoid pull rate limits from docker.io
.PHONY: add-dockercfg-dockerio
add-dockercfg-dockerio:
	@TOKEN=$(DOCKERIO_TOKEN) ./add-dockercfg-docker.io.sh
