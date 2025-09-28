
FROM jenkins/jenkins:2.529-jdk21
COPY --chown=jenkins:jenkins ./my-config/ref/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

