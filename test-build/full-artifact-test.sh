#!/bin/bash
# Full artifact generation test script that mirrors the GitHub Actions workflow

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

# Set up a debug repository path where artifacts would be uploaded
mkdir -p ./test-repo

# Copy the init.gradle file
cp /Users/shlomodaari/armory/spinnaker-armory-services/oss-artifact-builder/init.gradle ../

# Go to monorepo root
cd ..

# Modify build.gradle files to use a local directory for publishing
echo "Temporarily modifying build configuration to use local repository..."
find . -name "build.gradle" -exec grep -l "mavenJava" {} \; | while read file; do
  echo "Checking $file for publish config..."
  
  # Create backup
  cp "$file" "${file}.bak"
  
  # Add local repository configuration if it contains mavenJava
  if grep -q "mavenJava" "$file"; then
    echo "Modifying $file to publish locally"
    sed -i.tmp '/publishing {/a\
        repositories {\
            maven {\
                url = uri("'$(pwd)'/test-repo")\
            }\
        }' "$file" || echo "Failed to modify $file"
  fi
done

echo "Running artifactoryPublish task with dummy credentials (simulating local build only)..."
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

# Check for generated artifacts in all potential locations
echo "=== CHECKING ALL POTENTIAL ARTIFACT LOCATIONS ==="

echo "1. JAR files in build/libs:"
find ./${SERVICE_DIR} -name "*.jar" | grep "build/libs" | sort | head -10

echo "2. POM files in build directories:"
find ./${SERVICE_DIR} -name "*.pom" -o -name "pom.xml" | grep -v "expandedArchives" | sort | head -10

echo "3. Maven metadata files:"
find ./${SERVICE_DIR} -name "maven-metadata.xml" | sort | head -10

echo "4. MODULE files:"
find ./${SERVICE_DIR} -name "*.module" | sort | head -10

echo "5. Helm charts:"
find ./${SERVICE_DIR} -name "*.helm" | sort | head -10

echo "6. Build/publications directories:"
find ./${SERVICE_DIR} -path "*/build/publications/*" -type f | sort | head -10

echo "7. Local test repository (if artifacts were published locally):"
find ./test-repo -type f | sort | head -20

# Restore original build.gradle files
echo "Restoring original build configuration..."
find . -name "build.gradle.bak" -exec bash -c 'mv "$0" "${0%.bak}"' {} \;
find . -name "build.gradle.tmp" -exec rm {} \;

echo "Test complete. Check the above output to see what artifacts were generated."
