
pipeline {
    agent any

    triggers {
        githubPush()
    }

    options {
        skipDef
        aultCheckout(true)
    }

    environment {
        DOCKER_IMAGE = 'kumaresansoundappan/kanban-dashboard'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${BUILD_NUMBER}")
                }
            }
        }

        stage('Login and Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" |
                        docker login -u "$DOCKER_USER" --password-stdin

                        docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}

                        docker logout
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check the console output.'
        }
    }

    stage('Health Check & Validation') {
    steps {
        sh '''
            set -e

            CONTAINER="kanban-dashboard"

            echo "Checking container status..."

            RUNNING=$(docker inspect \
                -f '{{.State.Running}}' "$CONTAINER")

            if [ "$RUNNING" != "true" ]; then
                echo "Container is not running"
                exit 1
            fi

            echo "Checking Docker health..."

            for i in $(seq 1 12); do
                STATUS=$(docker inspect \
                    -f '{{.State.Health.Status}}' "$CONTAINER")

                echo "Health: $STATUS"

                if [ "$STATUS" = "healthy" ]; then
                    break
                fi

                if [ "$STATUS" = "unhealthy" ]; then
                    docker logs "$CONTAINER"
                    exit 1
                fi

                if [ "$i" -eq 12 ]; then
                    echo "Health check timeout"
                    exit 1
                fi

                sleep 5
            done

            echo "Checking application response..."

            curl --fail --silent --show-error \
                http://localhost:8081/ \
                -o /dev/null

            echo "Application is responding successfully"
        '''
    }
}
}
