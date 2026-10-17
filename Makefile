JAC ?= .venv/bin/jac

.PHONY: setup build start dev check test browser
setup:
	python3 -m venv .venv
	.venv/bin/python -m pip install -r requirements-dev.txt
	$(JAC) install
build:
	$(JAC) build main.jac
start:
	$(JAC) start main.jac --port 8000
dev:
	$(JAC) start --dev main.jac --port 8000
check:
	$(JAC) check main.jac endpoints.sv.jac store.jac matching.jac planning.jac coordination.jac frontend.cl.jac transport.cl.jac components/Marketplace.cl.jac components/Hero.cl.jac components/MovePlan.cl.jac
test:
	@db=$$(mktemp /tmp/heha-suite-XXXXXX.sqlite3); HEHA_DB=$$db $(JAC) test -d tests -v; result=$$?; rm -f "$$db"; exit $$result
browser:
	$(JAC) run qa/browser_workflow.jac
