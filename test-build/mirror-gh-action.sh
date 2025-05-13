#!/bin/bash
# This script mirrors what the GitHub Actions workflow is doing

# Set variables
SERVICE_DIR="echo"
VERSION="test-version-1.0.0"
ORG="spinnaker"
REPO="echo"
REF="main"
BUILD_NUMBER="${REF}:test-run"
BUILD_NAME="${ORG}:${REPO}"
ARTIFACTORY_URL="https://armory.jfrog.io/artifactory"
ARTIFACTORY_REPO="gradle-dev-local"

# Copy the init.gradle from the oss-artifact-builder repo if available
if [ -f "/Users/shlomodaari/armory/spinnaker-armory-services/oss-artifact-builder/init.gradle" ]; then
  cp /Users/shlomodaari/armory/spinnaker-armory-services/oss-artifact-builder/init.gradle .
  echo "Copied init.gradle from oss-artifact-builder"
else 
  # Create a basic init.gradle if we don't have the original
  echo "Creating basic init.gradle"
  cat > init.gradle << EOF
allprojects {
    tasks.withType(Test) { 
        enabled = false 
        onlyIf { false }
    }
}
EOF
fi

# Go back to monorepo root
cd ..

echo "Running artifactoryPublish task..."
./gradlew clean artifactoryPublish -I init.gradle \
  -PenableCrossCompilerPlugin=true \
  -Pversion=${VERSION} \
  -Pservice=${REPO} \
  -PartifactoryUrl=${ARTIFACTORY_URL} \
  -PartifactoryRepo=${ARTIFACTORY_REPO} \
  -PartifactoryBuildName=${BUILD_NAME} \
  -PartifactoryBuildNumber=${BUILD_NUMBER} \
  -x test -x spotlessCheck \
  --stacktrace || echo "artifactoryPublish failed, but continuing"

# Look for the generated artifacts
echo "Looking for generated artifacts..."
find ./${SERVICE_DIR} -type f -name "*.jar" | head -10
find ./${SERVICE_DIR} -type f -name "*.pom" | head -10
find ./${SERVICE_DIR} -type f -name "*.module" | head -10

# Check specific directories where artifacts might be
echo "Checking specific artifact directories..."
echo "1. build/libs directories:"
find ./${SERVICE_DIR} -path "*/build/libs/*" -type f | head -10

echo "2. build/publications directories:"
find ./${SERVICE_DIR} -path "*/build/publications/*" -type f | head -10

echo "3. .gradle directory:"
find ./${SERVICE_DIR} -path "*/.gradle/*" -name "*.jar" -o -name "*.pom" -o -name "*.module" | head -10
