// =============================================================================
// JENKINSFILE - Pipeline CI/CD pour déploiement sur GKE
// =============================================================================

pipeline {
    // =========================================================================
    // AGENT : Où le pipeline s'exécute
    // "any" = n'importe quel agent Jenkins disponible (ici notre VM)
    // =========================================================================
    agent any

    // =========================================================================
    // VARIABLES D'ENVIRONNEMENT
    // Définies une fois, utilisées partout dans le pipeline
    // =========================================================================
    environment {
        // Infos GCP - À MODIFIER avec tes valeurs
        GCP_PROJECT     = 'project-ba895609-81c6-42c7-8f3'           // ID de ton projet GCP
        GCP_REGION      = 'europe-west1'             // Région GCP
        GKE_CLUSTER     = 'cicd-cluster'             // Nom du cluster GKE
        GKE_ZONE        = 'europe-west1-b'           // Zone du cluster

        // Infos Docker/Registry
        IMAGE_NAME      = 'demo-app'                 // Nom de l'image
        REGISTRY_URL    = "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/cicd-docker-repo"

        // Tag de l'image = numéro de build Jenkins (1, 2, 3...)
        IMAGE_TAG       = "${BUILD_NUMBER}"
    }

    // =========================================================================
    // STAGES : Les étapes du pipeline (exécutées dans l'ordre)
    // =========================================================================
    stages {

        // ---------------------------------------------------------------------
        // STAGE 1 : CHECKOUT
        // Récupère le code source depuis Git
        // ---------------------------------------------------------------------
        stage('Checkout') {
            steps {
                // checkout scm = récupère le code du repo configuré dans Jenkins
                checkout scm

                // Affiche des infos pour le debug
                sh 'echo "✓ Code récupéré"'
                sh 'ls -la'
            }
        }

        // ---------------------------------------------------------------------
        // STAGE 2 : BUILD
        // Construit l'image Docker à partir du Dockerfile
        // ---------------------------------------------------------------------
        stage('Build Docker Image') {
            steps {
                script {
                    // docker build -t <registry>/<image>:<tag> ./app
                    // -t = tag de l'image
                    // ./app = dossier contenant le Dockerfile
                    sh """
                        echo "🔨 Construction de l'image Docker..."
                        docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} ./app
                        docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:latest ./app
                        echo "✓ Image construite: ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
                    """
                }
            }
        }

        // ---------------------------------------------------------------------
        // STAGE 3 : PUSH
        // Envoie l'image vers Artifact Registry (registry Docker de GCP)
        // ---------------------------------------------------------------------
        stage('Push to Registry') {
            steps {
                script {
                    // Configure Docker pour s'authentifier auprès de GCP
                    // Le service account de la VM Jenkins a déjà les droits
                    sh """
                        echo "📤 Push vers Artifact Registry..."
                        gcloud auth configure-docker ${GCP_REGION}-docker.pkg.dev --quiet
                        docker push ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${REGISTRY_URL}/${IMAGE_NAME}:latest
                        echo "✓ Image pushée: ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
                    """
                }
            }
        }

        // ---------------------------------------------------------------------
        // STAGE 4 : DEPLOY
        // Déploie l'application sur le cluster GKE avec Helm
        // ---------------------------------------------------------------------
        stage('Deploy to GKE') {
            steps {
                script {
                    sh """
                        echo "🚀 Déploiement sur GKE..."

                        # 1. Se connecter au cluster GKE
                        gcloud container clusters get-credentials ${GKE_CLUSTER} \
                            --zone ${GKE_ZONE} \
                            --project ${GCP_PROJECT}

                        # 2. Déployer avec Helm
                        # --install = installe si n'existe pas, sinon met à jour
                        # --set = surcharge les valeurs du chart
                        helm upgrade --install demo-app ./helm/demo-app \
                            --set image.repository=${REGISTRY_URL}/${IMAGE_NAME} \
                            --set image.tag=${IMAGE_TAG} \
                            --namespace default \
                            --wait

                        echo "✓ Déploiement terminé!"

                        # 3. Affiche l'URL de l'app
                        kubectl get svc demo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
                    """
                }
            }
        }
    }

    // =========================================================================
    // POST : Actions après le pipeline (succès ou échec)
    // =========================================================================
    post {
        success {
            echo '✅ Pipeline terminé avec succès!'
        }
        failure {
            echo '❌ Pipeline échoué. Vérifier les logs ci-dessus.'
        }
        always {
            // Nettoie les images Docker locales pour libérer de l'espace
            sh 'docker image prune -f || true'
        }
    }
}
