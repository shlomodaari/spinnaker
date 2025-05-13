#!/bin/bash
# Complete test script that properly uses the init.gradle file

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
ARTIFACTORY_USER="test-user"  # Dummy value for local testing
ARTIFACTORY_TOKEN="test-token"  # Dummy value for local testing

# Ensure we have the init.gradle file
cp /Users/shlomodaari/armory/spinnaker-armory-services/oss-artifact-builder/init.gradle ../

# Go to monorepo root
cd ..

echo "Running artifactoryPublish task..."
# Note: We're not actually uploading to artifactory since we don't have valid credentials
# This is just to see where files are generated locally
./gradlew clean artifactoryPublish -I init.gradle \
  -PenableCrossCompilerPlugin=true \
  -Pversion=${VERSION} \
  -Pservice=${REPO} \
  -PartifactoryUrl=${ARTIFACTORY_URL} \
  -PartifactoryRepo=${ARTIFACTORY_REPO} \
  -PartifactoryBuildName=${BUILD_NAME} \
  -PartifactoryBuildNumber=${BUILD_NUMBER} \
  -PartifactoryUsername=${ARTIFACTORY_USER} \
  -PartifactoryPassword=${ARTIFACTORY_TOKEN} \
  -x test -x spotlessCheck \
  --stacktrace -i || echo "artifactoryPublish failed, but continuing"

# After the build, look for the generated artifacts
echo "=== LOOKING FOR GENERATED ARTIFACTS ==="

# Look for JAR files
echo "=== JAR FILES ==="
find ./${SERVICE_DIR} -name "*.jar" | sort | head -10

# Look for POM files
echo "=== POM FILES ==="
find ./${SERVICE_DIR} -name "*.pom" -o -name "*.xml" | grep -E 'publications|pom|maven' | sort | head -10

# Look for MODULE files
echo "=== MODULE FILES ==="
find ./${SERVICE_DIR} -name "*.module" | sort | head -10

# Check specific artifact directories
echo "=== CHECKING SPECIFIC DIRECTORIES ==="
echo "1. build/libs directories:"
find ./${SERVICE_DIR} -path "*/build/libs/*" -type f | sort | head -10

echo "2. build/publications directories:"
find ./${SERVICE_DIR} -path "*/build/publications/*" -type f | sort | head -10

echo "3. Repository build directories:"
find ./${SERVICE_DIR} -path "*/repositories/*/io/spinnaker/*" -type f | sort | head -10

echo "4. Cache directories:"
find ./${SERVICE_DIR} -path "*/.gradle/*" -type f -name "*.jar" -o -name "*.pom" -o -name "*.module" | sort | head -10
