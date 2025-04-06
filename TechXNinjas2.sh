BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`
#----------------------------------------------------start--------------------------------------------------#

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

export REGION="${ZONE%-*}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
    --format='value(projectNumber)')

gcloud services enable \
  cloudkms.googleapis.com \
  cloudbuild.googleapis.com \
  container.googleapis.com \
  containerregistry.googleapis.com \
  artifactregistry.googleapis.com \
  containerscanning.googleapis.com \
  ondemandscanning.googleapis.com \
  binaryauthorization.googleapis.com 

KEY_LOCATION=global
KEYRING=binauthz-keys
KEY_NAME=codelab-key
KEY_VERSION=1

cd vuln-scan

cat > policy.yaml << EOM

globalPolicyEvaluationMode: ENABLE
defaultAdmissionRule:
  evaluationMode: ALWAYS_ALLOW
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
name: projects/$PROJECT_ID/policy

EOM

gcloud container binauthz policy import policy.yaml

echo "${BLUE_TEXT}${BOLD_TEXT}===============================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT} 5th TASK (REMAINING HALF) COMPLETED SUCCESSFULLY   ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}===============================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}      GO TO LAB TO CHECK THE PROGRESS      ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}===============================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}    8th TASK STARTING FOR EXECUTION...    ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}===============================================${RESET_FORMAT}"
echo

CONTAINER_PATH=${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image

DIGEST=$(gcloud container images describe ${CONTAINER_PATH}:latest \
    --format='get(image_summary.digest)')

COMPUTE_ZONE=${REGION}

cat > binauth_policy.yaml << EOM
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: REQUIRE_ATTESTATION
  requireAttestationsBy:
  - projects/${PROJECT_ID}/attestors/vulnz-attestor
globalPolicyEvaluationMode: ENABLE
clusterAdmissionRules:
  ${COMPUTE_ZONE}.binauthz:
    evaluationMode: REQUIRE_ATTESTATION
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
    requireAttestationsBy:
    - projects/${PROJECT_ID}/attestors/vulnz-attestor
EOM

gcloud beta container binauthz policy import binauth_policy.yaml

docker build -t $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:bad .

docker push $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:bad

CONTAINER_PATH=$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image

DIGEST=$(gcloud container images describe ${CONTAINER_PATH}:bad \
    --format='get(image_summary.digest)')

cat > deploy.yaml << EOM
apiVersion: v1
kind: Service
metadata:
  name: deb-httpd
spec:
  selector:
    app: deb-httpd
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deb-httpd
spec:
  replicas: 1
  selector:
    matchLabels:
      app: deb-httpd
  template:
    metadata:
      labels:
        app: deb-httpd
    spec:
      containers:
      - name: deb-httpd
        image: ${CONTAINER_PATH}@${DIGEST}
        ports:
        - containerPort: 8080
        env:
          - name: PORT
            value: "8080"

EOM

kubectl apply -f deploy.yaml

echo "${BLUE_TEXT}${BOLD_TEXT}===============================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}            STARTING THE EXECUTION...     ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}===============================================${RESET_FORMAT}"
echo

echo "${GREEN}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"
echo "For more lab solutions, join WhatsApp Group of TechXNinjas"

#-----------------------------------------------------end----------------------------------------------------------#
