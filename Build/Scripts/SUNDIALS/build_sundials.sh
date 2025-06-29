#!/bin/bash
SUNDIALS_LIB_TAG=v6.7.0

CONFMAKE=$1
CLEAN_SUNDIALS=$2

dir=`pwd`

echo "CLEAN_SUNDIALS = $CLEAN_SUNDIALS"
if [ "$CLEAN_SUNDIALS" = true ]; then
  echo "Removing sundials library ..."
  rm -r $FIREMODELS/libs/sundials
  rm -r $FIREMODELS/sundials/BUILDDIR
fi

echo "Checking for sundials library..."

if [ -d "$FIREMODELS/libs/sundials" ]; then
  echo "Sundials library exists.  Skipping sundials build."
  # List all directories under $FIREMODELS/libs/sundials
  sundials_lib_dir=$(ls -d $FIREMODELS/libs/sundials/*/)
  # Extract the version part (removes the leading path)
  SUNDIALS_VERSION=$(basename $sundials_lib_dir)
  export SUNDIALS_HOME=$FIREMODELS/libs/sundials/$SUNDIALS_VERSION
  echo "Sundials library:" $FIREMODELS/libs/sundials/$SUNDIALS_VERSION
  return 0
else
  echo "Sundials library does not exist."
fi

echo "Checking for sundials repository..."

if [ -d "$FIREMODELS/sundials" ]; then
  echo "Sundials repository exists. Building sundials library."
  cd $FIREMODELS/sundials
  # Handle possible corrupted state of repository
  if git branch | grep -q "* main"; then
    echo "On main branch"
  else
    git checkout main
  fi
  git checkout .
  git clean -dxf
  if [[ "$(git tag -l $SUNDIALS_LIB_TAG)" == $SUNDIALS_LIB_TAG ]]; then
    echo "Checking out $SUNDIALS_LIB_TAG"
    git checkout $SUNDIALS_LIB_TAG
  else
    echo "Your SUNDIALS repository is not up to date with the required tag: $SUNDIALS_LIB_TAG."
    echo "The FDS build requires SUNDIALS version $SUNDIALS_LIB_TAG. Please update your SUNDIALS repository."
    exit 1
  fi 
  mkdir $FIREMODELS/sundials/BUILDDIR
  cd $FIREMODELS/sundials/BUILDDIR
  echo "Creating library directry..."
  export SUNDIALS_VERSION=$(git describe)
  echo "Cleaning sundials repository..."
  rm -r $FIREMODELS/sundials/BUILDDIR/*
  cp $FIREMODELS/fds/Build/Scripts/SUNDIALS/$CONFMAKE .
  ./$CONFMAKE
  # get back from detached HEAD state
  cd $FIREMODELS/sundials
  git checkout main
  cd $dir
  export SUNDIALS_HOME=$FIREMODELS/libs/sundials/$SUNDIALS_VERSION
  echo "Sundials library:" $FIREMODELS/libs/sundials/$SUNDIALS_VERSION
  return 0
else
  echo "Sundials repository does not exist."
fi
