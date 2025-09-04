.PHONY: help lint template install-dev install-staging install-prod dependency-update clean

# Default target
help:
	@echo "Available targets:"
	@echo "  lint                 - Lint all charts"
	@echo "  template            - Template sample app"
	@echo "  install-dev         - Install sample app in development mode"
	@echo "  install-staging     - Install sample app in staging mode"
	@echo "  install-prod        - Install sample app in production mode"
	@echo "  dependency-update   - Update chart dependencies"
	@echo "  clean              - Clean up releases"

# Chart paths
SAMPLE_APP_PATH = apps/sample-web-app
COMMON_LIB_PATH = library/common

# Lint all charts
lint:
	@echo "Linting common library..."
	helm lint $(COMMON_LIB_PATH)
	@echo "Linting sample web app..."
	helm lint $(SAMPLE_APP_PATH)

# Template the sample app with different environments
template:
	@echo "Templating sample app for development..."
	helm template sample-web-app $(SAMPLE_APP_PATH) -f $(SAMPLE_APP_PATH)/values-dev.yaml
	@echo "\n--- STAGING ---\n"
	helm template sample-web-app $(SAMPLE_APP_PATH) -f $(SAMPLE_APP_PATH)/values-staging.yaml
	@echo "\n--- PRODUCTION ---\n"
	helm template sample-web-app $(SAMPLE_APP_PATH) -f $(SAMPLE_APP_PATH)/values-prod.yaml

# Install sample app in different environments
install-dev:
	helm dependency update $(SAMPLE_APP_PATH)
	helm install sample-web-app-dev $(SAMPLE_APP_PATH) -f $(SAMPLE_APP_PATH)/values-dev.yaml

install-staging:
	helm dependency update $(SAMPLE_APP_PATH)
	helm install sample-web-app-staging $(SAMPLE_APP_PATH) -f $(SAMPLE_APP_PATH)/values-staging.yaml

install-prod:
	helm dependency update $(SAMPLE_APP_PATH)
	helm install sample-web-app-prod $(SAMPLE_APP_PATH) -f $(SAMPLE_APP_PATH)/values-prod.yaml

# Update dependencies
dependency-update:
	@echo "Updating dependencies for sample app..."
	helm dependency update $(SAMPLE_APP_PATH)

# Clean up releases
clean:
	-helm uninstall sample-web-app-dev
	-helm uninstall sample-web-app-staging
	-helm uninstall sample-web-app-prod

# Dry run installations
dry-run-dev:
	helm install --dry-run sample-web-app-dev $(SAMPLE_APP_PATH) -f $(SAMPLE_APP_PATH)/values-dev.yaml

dry-run-staging:
	helm install --dry-run sample-web-app-staging $(SAMPLE_APP_PATH) -f $(SAMPLE_APP_PATH)/values-staging.yaml

dry-run-prod:
	helm install --dry-run sample-web-app-prod $(SAMPLE_APP_PATH) -f $(SAMPLE_APP_PATH)/values-prod.yaml
