#!/bin/bash

ROOT_DIR="/home/lyssenko_alex/lab_1/web/shop-angular-cloudfront"
BUILD_DIR="$ROOT_DIR/dist"
clientBuildFile="$BUILD_DIR/client-app.zip"
ENV_FILE="$ROOT_DIR/.env"


export "$(grep -v '^#'  $ENV_FILE | xargs)"

if [ -e "$clientBuildFile" ]; then
  rm "$clientBuildFile"
  echo "$clientBuildFile was removed."
fi
chmod 775 ./quality-check.sh
RETURN_VARIABLE=$(./quality-check.sh)
LAST_LINE="${RETURN_VARIABLE##*$'\n'}"
echo "$LAST_LINE"
if [ "$LAST_LINE" = "All files pass linting." ]; then
cd $ROOT_DIR && npm run build --configuration="$ENV_CONFIGURATION"
echo "Client app was built"



echo $BUILD_DIR
echo $clientBuildFile

zip -r $clientBuildFile $BUILD_DIR
else
    echo "Lint error $RETURN_VARIABLE"
fi
