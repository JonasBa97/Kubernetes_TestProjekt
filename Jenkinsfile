pipeline {
  agent any

  environment {
    ACR_NAME = 'skyerededucation.azurecr.io'
    IMAGE_NAME = 'lugx-gaming'
    IMAGE_TAG = 'latest'
    KUBE_CONFIG_CREDENTIALS_ID = 'Kubeconfig_Secret_TestProjekt'
    DEV_URL = 'http://20.125.24.149:30010'
    PROD_URL = 'http://20.125.24.149:30011'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Docker Build & Push') {
      steps {
        script {
          def newVersion = sh(script: 'bash versionierung.sh', returnStdout: true).trim()
          env.NEW_VERSION = newVersion
          sh """
            echo "Neue Version: ${env.NEW_VERSION}"
            docker build -t skyerededucation.azurecr.io/lugx-gaming:${env.NEW_VERSION} -t skyerededucation.azurecr.io/lugx-gaming:latest .
            docker push -a skyerededucation.azurecr.io/lugx-gaming
          """
        }
      }
    }  

    stage('Deploy to kurs2-dev') {
      steps {
        withCredentials([file(credentialsId: env.KUBE_CONFIG_CREDENTIALS_ID, variable: 'KUBECONFIG')]) {
          withEnv(["KUBECONFIG=$KUBECONFIG"]) {
            sh '''
              kubectl config use-context kurs2-dev@k3s
              if kubectl get deployments lugx-dev-deployment > /dev/null 2>&1; then
                kubectl rollout restart deployment lugx-dev-deployment
              else 
                kubectl apply -f deploy-dev.yaml
                kubectl apply -f service-dev.yaml
              fi
            '''
          }
        }
      }
    }

    stage('Test on kurs2-dev') {
      steps {
        echo 'Warte auf Verfügbarkeit der Dev-Seite...'
        sh '''
          for i in {1..3}; do
            if curl -s --fail ${DEV_URL}; then
              echo "Dev-Deployment erfolgreich erreichbar."
              exit 0
            else
              echo "Noch nicht erreichbar, warte 5 Sekunden..."
              sleep 10
            fi
          done
          echo "Dev-Deployment nicht erreichbar!"
          exit 1
        '''
      }
    }

    stage('Deploy to kurs2-prod') {
      steps {
        input message: 'Deployment auf PROD freigeben?'
        withCredentials([file(credentialsId: env.KUBE_CONFIG_CREDENTIALS_ID, variable: 'KUBECONFIG')]) {
          sh '''
            kubectl --kubeconfig=$KUBECONFIG config use-context kurs2-prod@k3s
            kubectl --kubeconfig=$KUBECONFIG set image deployment/homepage homepage=${ACR_NAME}/${IMAGE_NAME}:${IMAGE_TAG}
            kubectl --kubeconfig=$KUBECONFIG -f apply deploy-prod.yaml
            kubectl --kubeconfig=$KUBECONFIG -f apply service-prod.yaml
          '''
        }
      }
    }

    stage('Test on kurs2-prod') {
      steps {
        echo 'Warte auf Verfügbarkeit der Prod-Seite...'
        sh '''
          for i in {1..3}; do
            if curl -s --fail ${PROD_URL}; then
              echo "Prod-Deployment erfolgreich erreichbar."
              exit 0
            else
              echo "Noch nicht erreichbar, warte 5 Sekunden..."
              sleep 10
            fi
          done
          echo "Prod-Deployment nicht erreichbar!"
          exit 1
        '''
      }
    }
  }
  
  post {
    always {
      cleanWs()
    }
  }
}
