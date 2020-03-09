#!/bin/bash

set -e

FOLDER=$1
GITHUB_USERNAME=$2
REPO_NAME="${3}"
BRANCH_NAME="${4:-master}"
TARGET_FOLDER="${5:-.}"
BASE=$(pwd)

git config --global user.email "johno-actions-push-subdirectories@example.org"
git config --global user.name "$GITHUB_USERNAME"

echo "Cloning folders in $FOLDER and pushing to $GITHUB_USERNAME $REPO_NAME $BRANCH_NAME"

# sync to read-only clones
for folder in $FOLDER/*; do
  [ -d "$folder" ] || continue # only directories
  cd $BASE

  echo "$folder"

  # NAME=$(cat $folder/package.json | jq --arg name "$STARTER_NAME" -r '.[$name]')
  NAME=$REPO_NAME
  echo "  Name: $NAME"
  # IS_WORKSPACE=$(cat $folder/package.json | jq -r '.workspaces')
  CLONE_DIR="__${NAME}__clone__"
  echo "  Clone dir: $CLONE_DIR"

  # clone, delete files in the clone, and copy (new) files over
  # this handles file deletions, additions, and changes seamlessly
  git clone --depth 1 https://$API_TOKEN_GITHUB@github.com/$GITHUB_USERNAME/$NAME.git $CLONE_DIR &> /dev/null
  echo "cd into dir"
  cd $CLONE_DIR
  echo "before remote list and update"
  git remote -v
  echo "Remote update"
  git remote update
  echo "git fetch...."
  git fetch
  echo "and checkout..."
  git checkout -b $BRANCH_NAME origin/$BRANCH_NAME
  # find . | grep -v ".git" | grep -v "^\.*$" | xargs rm -rf # delete all files (to handle deletions in monorepo)
  cp -r $BASE/$folder/. $TARGET_FOLDER

  # generate a new yarn.lock file based on package-lock.json unless you're in a workspace
  # if [ "$IS_WORKSPACE" = null ]; then
    # echo "  Regenerating yarn.lock"
    # rm -rf yarn.lock
    # yarn
  # fi

  # Commit if there is anything to
  if [ -n "$(git status --porcelain)" ]; then
    echo  "  Committing $BRANCH_NAME to $GITHUB_REPOSITORY $GITHUB_USERNAME/$NAME"
    git add .
    git commit --message "Update $NAME from $GITHUB_REPOSITORY"
    # git push origin $BRANCH_NAME
    git push
    echo  "  Completed $NAME"
  else
    echo "  No changes, skipping $NAME"
  fi

  cd $BASE
done
