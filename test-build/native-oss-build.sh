#!/bin/bash
# Script to investigate how OSS Spinnaker builds artifacts natively
# This will focus on the echo service

cd /Users/shlomodaari/armory/spinnaker-armory-services/spinnaker

echo "=== Examining standard OSS build process for echo ==="

# First, let's see what Gradle publishing tasks are available
echo "Available publishing tasks:"
./gradlew :echo:tasks --group publishing

# Check if there's a maven publish plugin applied
echo "Checking if maven-publish plugin is applied:"
./gradlew :echo:plugins | grep -i maven

# Let's try to run the publishToMavenLocal task to see where artifacts go
echo "Running publishToMavenLocal for echo:"
./gradlew :echo:publishToMavenLocal -x test

# Now let's look for where artifacts were created
echo "=== Finding generated artifacts ==="

echo "1. JAR files:"
find ./echo -name "*.jar" | grep -v "cache\|expandedArchives" | sort

echo "2. POM files:"
find ./echo -name "*.pom" -o -name "pom.xml" | grep -v "cache\|expandedArchives" | sort

echo "3. MODULE files:"
find ./echo -name "*.module" | grep -v "cache\|expandedArchives" | sort

echo "4. Looking in Maven local repository:"
find ~/.m2/repository/io/spinnaker/echo -type f | sort | head -30

echo "5. Publications directory:"
find ./echo -path "*/build/publications/*" -type f | sort
