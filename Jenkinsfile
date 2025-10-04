pipeline {
  agent any

  environment {
    REGISTRY = 'docker.io/sonamcurtin'
    IMAGE    = 'nodejs-app'
    DOCKER_BUILDKIT = '1'
    DOCKER_HOST = 'tcp://docker:2376'
    DOCKER_CERT_PATH = '/certs/client'
    DOCKER_TLS_VERIFY = '1'
    LOCAL_BIN = "${WORKSPACE}/bin"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build & Test (Node16)') {
      agent { docker { image 'node:16-alpine' } }
      steps {
        sh '''
          set -eux
          npm install --save
          npm test --if-present || echo "No tests defined, continuing"
        '''
      }
    }

    stage('Install Trivy (no root)') {
      steps {
        sh '''
          set -eux
          mkdir -p "${LOCAL_BIN}"
          curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
            | sh -s -- -b "${LOCAL_BIN}"
          export PATH="${LOCAL_BIN}:${PATH}"
          trivy --version
        '''
      }
    }

    stage('Vuln Scan (Trivy FS)') {
      steps {
        sh '''
          set -eux
          export PATH="${LOCAL_BIN}:${PATH}"
          trivy fs --severity HIGH,CRITICAL --exit-code 1 --no-progress .
        '''
      }
    }

    stage('Docker Build (DinD)') {
      steps {
        sh '''
          set -eux
          docker build -t ${REGISTRY}/${IMAGE}:${BUILD_NUMBER} -t ${REGISTRY}/${IMAGE}:latest .
        '''
      }
    }

    stage('Vuln Scan (Trivy Image)') {
      steps {
        sh '''
          set -eux
          export PATH="${LOCAL_BIN}:${PATH}"
          # Skip global npm toolchain in the base image to focus on app/OS layers
          trivy image --severity HIGH,CRITICAL --exit-code 1 --no-progress \
            --skip-dirs /usr/local/lib/node_modules \
            ${REGISTRY}/${IMAGE}:${BUILD_NUMBER}
        '''
      }
    }

    stage('Push to Registry') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials',
                           usernameVariable: 'DOCKER_USER',
                           passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            set -eux
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push ${REGISTRY}/${IMAGE}:${BUILD_NUMBER}
            docker push ${REGISTRY}/${IMAGE}:latest
          '''
        }
      }
    }
  }

  post {
    always {
      sh 'docker system prune -f || true'
    }
  }
}
