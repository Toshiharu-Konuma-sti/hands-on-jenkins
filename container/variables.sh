
# ARTF_PKG_URL="https://releases.jfrog.io/artifactory/bintray-artifactory/org/artifactory/oss/docker/jfrog-artifactory-oss/\[RELEASE\]/jfrog-artifactory-oss-\[RELEASE\]-compose.tar.gz"
ARTF_PKG_URL="https://releases.jfrog.io/artifactory/bintray-artifactory/org/artifactory/oss/docker/jfrog-artifactory-oss/7.117.19/jfrog-artifactory-oss-7.117.19-compose.tar.gz"
ARTF_PKG_PTN="jfrog-artifactory-oss-*-compose.tar.gz"
ARTF_DIR_PTN="artifactory-oss-*"

WEBAPP_PKG_URL="https://github.com/Toshiharu-Konuma-sti/hands-on-rollingdice-webapp/archive/refs/heads/main.zip"
# WEBAPP_PKG_URL="https://github.com/Toshiharu-Konuma-sti/hands-on-rollingdice-webapp/archive/refs/heads/dev202509.zip"
WEBAPP_PROJECTS="webapp-webui webapp-webapi"

JENK_HOST_EXT="localhost:8080"
JENK_HOST_INT="jenkins:8080"
JENK_USER="admin"
JENK_PASS="password"
JENK_JOB_TOKEN="1234567890abcdefghijklmnopqrstuvwxyz"

GITL_USER="root"
GITL_HOST="localhost:13000"

DEPT_YAML_URL="https://dependencytrack.org/docker-compose.yml"
DEPT_YAML_FIL="docker-compose-dependencytrack.yml"
DEPT_APIS_NM_BEF="apiserver"
DEPT_APIS_NM_AFT="dep-track-apiserver"
DEPT_FRNT_NM_BEF="frontend"
DEPT_FRNT_NM_AFT="dep-track-frontend"
DEPT_PSQL_NM_BEF="postgres"
DEPT_PSQL_NM_AFT="dep-track-postgres"
DEPT_APIS_PORT_BEF=8081
DEPT_APIS_PORT_AFT=8981
DEPT_FRNT_PORT_BEF=8080
DEPT_FRNT_PORT_AFT=8980
