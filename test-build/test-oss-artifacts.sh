#!/bin/bash
# Script to test OSS artifact generation process locally
# This script tests the same process that the GitHub Action uses

# Set variables for testing
SERVICE_DIR="echo"  # Using echo as a test service
VERSION="test-version-1.0.0"
ORG="spinnaker"
REPO="echo"
BUILD_NUMBER="test-branch:test-run-1"
BUILD_NAME="${ORG}:${REPO}"
BUILD_URL="https://example.com/test-run"
ARTIFACTORY_URL="https://armory.jfrog.io/artifactory"
ARTIFACTORY_REPO="gradle-dev-local"

# Path to the oss-artifact-builder repo
OSS_BUILDER_PATH="/Users/shlomodaari/armory/spinnaker-armory-services/oss-artifact-builder"

# Spinnaker monorepo path
SPINNAKER_PATH="/Users/shlomodaari/armory/spinnaker-armory-services/spinnaker"

# Copy init.gradle from oss-artifact-builder to the monorepo
cp "${OSS_BUILDER_PATH}/init.gradle" "${SPINNAKER_PATH}/"

# Navigate to the Spinnaker monorepo
cd "${SPINNAKER_PATH}"

# Set gradle environment variables
export GRADLE_OPTS="-Dorg.gradle.daemon=false -Xmx6g -Xms6g"

# Create a file to disable tests
cat > disable-tests.gradle << EOF
allprojects {
    tasks.withType(Test) { 
        enabled = false 
        onlyIf { false }
    }
}
EOF

# Make sure gradlew is executable
chmod +x ./gradlew

# First list tasks to see what's available
echo "=== Available Gradle Tasks for Service ==="
./gradlew :${SERVICE_DIR}:tasks --group publishing

# Run artifactoryPublish to generate artifacts (with dummy credentials)
# We don't need this to actually upload to Artifactory
echo "=== Running artifactoryPublish to generate artifacts ==="
./gradlew clean :${SERVICE_DIR}:artifactoryPublish -I init.gradle -I disable-tests.gradle \
  -PenableCrossCompilerPlugin=true \
  -Pversion=${VERSION} \
  -Pservice=${REPO} \
  -PartifactoryUrl=${ARTIFACTORY_URL} \
  -PartifactoryRepo=${ARTIFACTORY_REPO} \
  -PartifactoryBuildName=${BUILD_NAME} \
  -PartifactoryBuildNumber=${BUILD_NUMBER} \
  -PartifactoryUsername=test-user \
  -PartifactoryPassword=test-password \
  -x test -x spotlessCheck \
  --stacktrace || echo "artifactoryPublish failed, checking what was generated anyway"

# Check what was generated
echo "=== Checking Generated Artifacts ==="
echo "1. JAR files in build/libs:"
find ./${SERVICE_DIR} -path "*/build/libs/*.jar" | head -20

echo "2. POM files in build/publications:"
find ./${SERVICE_DIR} -path "*/build/publications/*" -name "*.pom" | head -20

echo "3. MODULE files in build/publications:"
find ./${SERVICE_DIR} -path "*/build/publications/*" -name "*.module" | head -20

echo "4. All files in publications directory:"
find ./${SERVICE_DIR} -path "*/build/publications/*" -type f | sort

echo "5. Directory structure of sample module:"
find ./${SERVICE_DIR}/echo-core -path "*/build/*" -type d | sort
