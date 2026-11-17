
pipeline {
    agent any

    triggers {
        githubPush()
    }

    options {
        skipDefaultCheckout(true)
        timestamps()
    }

    environment {
        DOCKER_IMAGE = 'kumaresansoundappan/kanban-dashboard'
        CONTAINER_NAME = 'kanban-dashboard'
        HOST_PORT = '8081'
        CONTAINER_PORT = '8080'
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
                    '''
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sh '''
                    docker pull ${DOCKER_IMAGE}:${BUILD_NUMBER}

                    docker rm -f ${CONTAINER_NAME} || true

                    docker run -d \
                        --name ${CONTAINER_NAME} \
                        --restart unless-stopped \
                        -p ${HOST_PORT}:${CONTAINER_PORT} \
                        ${DOCKER_IMAGE}:${BUILD_NUMBER}
                '''
            }
        }

        stage('Health Check & Validation') {
            steps {
                sh '''
                    set -e

                    echo "Checking container status..."

                    RUNNING=$(docker inspect \
                        -f '{{.State.Running}}' ${CONTAINER_NAME})

                    if [ "$RUNNING" != "true" ]; then
                        echo "Container is not running"
                        exit 1
                    fi

                    echo "Container is running"

                    echo "Checking Docker health..."

                    HEALTHY=false

                    for i in $(seq 1 12); do

                        STATUS=$(docker inspect \
                            -f '{{.State.Health.Status}}' ${CONTAINER_NAME})

                        echo "Health status: $STATUS"

                        if [ "$STATUS" = "healthy" ]; then
                            HEALTHY=true
                            break
                        fi

                        if [ "$STATUS" = "unhealthy" ]; then
                            docker logs ${CONTAINER_NAME}
                            exit 1
                        fi

                        sleep 5
                    done

                    if [ "$HEALTHY" != "true" ]; then
                        echo "Health check timed out"
                        docker logs ${CONTAINER_NAME}
                        exit 1
                    fi

                    echo "Checking HTTP response..."

                    HTTP_CODE=$(curl -s -o /dev/null \
                        -w "%{http_code}" \
                        --max-time 10 \
                        http://localhost:${HOST_PORT}/)

                    if [ "$HTTP_CODE" != "200" ]; then
                        echo "HTTP validation failed: $HTTP_CODE"
                        exit 1
                    fi

                    echo "Application HTTP validation successful"
                '''
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

        always {
            sh 'docker logout || true
        }
    }
}
