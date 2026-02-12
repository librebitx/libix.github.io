#!/bin/bash

# Simple deploy script for Hugo Blog
# Usage: ./publish.sh "Your commit message"

if [ $# -eq 0 ]; then
    echo "Error: Please provide a commit message."
    echo "Usage: ./publish.sh \"your message\""
    exit 1
fi

MESSAGE=$1

echo -e "\033[0;32mStarting Deployment...\033[0m"

# 1. Git Add
echo "Adding changes..."
git add .

# 2. Git Commit
echo "Committing with message: $MESSAGE"
git commit -m "$MESSAGE"

# 3. Git Push
echo "Pushing to GitHub..."
git push origin main

echo -e "\033[0;32mDone! Your changes will be built and deployed by GitHub Actions.\033[0m"
