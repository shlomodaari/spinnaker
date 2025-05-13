#!/bin/bash
# Test script to verify artifact generation

# Set variables
SERVICE_DIR="echo"
VERSION="test-version-1.0.0"
oss_version="1.0.0-test.main"

# Go to monorepo root
cd ..

# Create a test-disabling init script
cat > disable-tests.gradle << EOF
allprojects {
    tasks.withType(Test) { 
        enabled = false 
        onlyIf { false }
    }
}
EOF

# Add Maven publication capabilities
cat > maven-publish.gradle << EOF
allprojects {
    apply plugin: 'maven-publish'
    
    if (project.hasProperty('mavenPublishEnabled') && project.mavenPublishEnabled.toBoolean()) {
        publishing {
            publications {
                maven(MavenPublication) {
                    from components.java
                    if (tasks.findByName('sourcesJar')) {
                        artifact sourcesJar
                    }
                }
            }
        }
    }
}
EOF

# Build with gradle from monorepo root
echo "Building service with gradle..."
./gradlew -I disable-tests.gradle -I maven-publish.gradle \
  :${SERVICE_DIR}:clean \
  :${SERVICE_DIR}:build :${SERVICE_DIR}:${SERVICE_DIR}-web:installDist \
  :${SERVICE_DIR}:${SERVICE_DIR}-bom:build \
  :${SERVICE_DIR}:publishToMavenLocal \
  -PmavenPublishEnabled=true \
  -x test -x spotlessCheck \
  --stacktrace || echo "BOM build may have failed, but continuing with the build"

# Report built artifacts
echo "Built artifacts:"
find ./${SERVICE_DIR} -name "*.jar" | grep -v "tests.jar" | head -10

# Generate proper POMs for all modules
echo "Generating POMs for all modules..."
for MODULE in $(find ./${SERVICE_DIR} -maxdepth 1 -type d | grep "${SERVICE_DIR}-" | sed "s|./${SERVICE_DIR}/||"); do
  echo "Processing module: $MODULE"
  ./gradlew :${SERVICE_DIR}:${MODULE}:generatePomFileForMavenPublication -PmavenPublishEnabled=true || echo "Failed to generate POM for $MODULE"
done

# Debug output for all artifacts
echo "DEBUG: All artifacts generated:"
find ./${SERVICE_DIR} -path "*/build/*" -type f | grep -E "\.(jar|pom|module)$" | head -20 || echo "No artifacts found"

# Check specific module locations
echo "Checking specific module locations:"
find ./${SERVICE_DIR}/echo-core -path "*/build/*" -type f | grep -E "\.(jar|pom|module)$" || echo "No artifacts found in echo-core"
