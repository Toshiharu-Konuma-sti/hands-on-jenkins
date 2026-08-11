FROM jenkins/jenkins:latest-jdk21

COPY --chown=jenkins:jenkins ./my-config/ref/plugins.txt /usr/share/jenkins/ref/plugins.txt
# 60秒読み取りタイムアウト付きで最大5回リトライ
RUN JAVA_TOOL_OPTIONS="-Dsun.net.client.defaultConnectTimeout=60000 -Dsun.net.client.defaultReadTimeout=60000" \
    sh -c 'n=0; until [ $n -ge 5 ]; do jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt && break; n=$((n+1)); echo "Retry $n/5..."; sleep 10; done'
