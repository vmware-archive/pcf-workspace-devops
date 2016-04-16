# Uncomment if you are not logged in
# cf login -a https://api.$CF_SYSTEM_DOMAIN -u $CF_USER -o $CF_ORG -s $CF_SPACE --skip-ssl-validation

CF_APP=$1
BUILD_NUMBER=$2
CF_APPS_DOMAIN=$3

if [ -z "$CF_APP" ] || [ -z "$BUILD_NUMBER" ] || [ -z "$CF_APPS_DOMAIN" ] ; then
  echo "Usage: blue-green.sh <app-name> <build-number> <domain>> "
  exit;
fi


###
###
###
###

DEPLOYED_VERSION_CMD=$(CF_COLOR=false cf apps | grep $CF_APP- | cut -d" " -f1)
DEPLOYED_VERSION="$DEPLOYED_VERSION_CMD"
ROUTE_VERSION=$(echo "${BUILD_NUMBER}" | cut -d"." -f1-3 | tr '.' '-')
echo "Deployed Version: $DEPLOYED_VERSION"
echo "Route Version: $ROUTE_VERSION"

# push a new version and map the route
cf push "$CF_APP-$BUILD_NUMBER" --no-route 
cf map-route "$CF_APP-${BUILD_NUMBER}" $CF_APPS_DOMAIN -n $CF_APP

if [ ! -z "$DEPLOYED_VERSION" -a "$DEPLOYED_VERSION" != " " -a "$DEPLOYED_VERSION" != "$CF_APP-${BUILD_NUMBER}" ]; then
  echo "Performing zero-downtime cutover to $BUILD_NUMBER"
  echo "$DEPLOYED_VERSION" | while read line
  do
    if [ ! -z "$line" -a "$line" != " " -a "$line" != "$CF_APP-${BUILD_NUMBER}" ]; then
      echo "Scaling down, unmapping and removing $line"
      # Unmap the route and delete
      cf unmap-route "$line" $CF_APPS_DOMAIN -n $CF_APP
      cf delete "$line" -f
    else
      echo "Skipping $line"
    fi
  done
fi

