#!/bin/bash

if [[ -z "${TS_REPO_NAME}" ]]; then
	REPO_NAME="tremolo"
else
	REPO_NAME=$TS_REPO_NAME
fi

echo "Helm Repo Name $REPO_NAME"

if [[ -z "${TS_REPO_URL}" ]]; then
	REPO_URL="https://nexus.tremolo.io/repository/helm"
else
	REPO_URL=$TS_REPO_URL
fi

echo "Helm Repo URL $REPO_URL"

helm repo add $REPO_NAME $REPO_URL
helm repo update

# expose the oidc discovery document for un-authenticated users
kubectl create clusterrolebinding oidc-reviewer --clusterrole=system:service-account-issuer-discovery --group=system:unauthenticated

# deploy cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml

# wait for the cert-manager to be running
while [[ $(kubectl get pods -l app=webhook -n cert-manager -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for cert-manager pod" && sleep 1; done

kubectl create -f - <<EOF
apiVersion: v1
data:
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURFVENDQWZtZ0F3SUJBZ0lVYmtiS2ZRN29ldXJuVHpyeWdIL0dDS0kzNkUwd0RRWUpLb1pJaHZjTkFRRUwKQlFBd0dERVdNQlFHQTFVRUF3d05aVzUwWlhKd2NtbHpaUzFqWVRBZUZ3MHlNakV4TURjeE5EUTFNakphRncwegpNakV4TURReE5EUTFNakphTUJneEZqQVVCZ05WQkFNTURXVnVkR1Z5Y0hKcGMyVXRZMkV3Z2dFaU1BMEdDU3FHClNJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUUNucVZ3eVFvMjJyRzZuVVpjU2UvR21WZnI5MEt6Z3V4MDkKNDY4cFNTUWRwRHE5UlRRVU92ZkFUUEJXODF3QlJmUDEvcnlFaHNocnVBS2E5LzVoKzVCL3g4bmN4VFhwbThCNwp2RDdldHY4V3VyeUtQc0lMdWlkT0QwR1FTRVRvNzdBWE03RmZpUk9yMDFqN3c2UVB3dVB2QkpTcDNpa2lDL0RjCnZFNjZsdklFWE43ZFNnRGRkdnV2R1FORFdPWWxHWmhmNUZIVy81ZHJQSHVPOXp1eVVHK01NaTFpUCtSQk1QUmcKSWU2djhCcE9ncnNnZHRtWExhNFZNc1BNKzBYZkQwSDhjU2YvMkg2V1M0LzdEOEF1bG5QSW9LY1krRkxKUEFtMwpJVFI3L2w2UTBJUXVNU3c2QkxLYWZCRm5CVmNUUVNIN3lKZEFKNWdINFZZRHIyamtVWkwzQWdNQkFBR2pVekJSCk1CMEdBMVVkRGdRV0JCU2Y5RDVGS3dISUY3eFdxRi80OG4rci9SVFEzakFmQmdOVkhTTUVHREFXZ0JTZjlENUYKS3dISUY3eFdxRi80OG4rci9SVFEzakFQQmdOVkhSTUJBZjhFQlRBREFRSC9NQTBHQ1NxR1NJYjNEUUVCQ3dVQQpBNElCQVFCN1BsMjkrclJ2eHArVHhLT3RCZGRLeEhhRTJVRUxuYmlkaFUvMTZRbW51VmlCQVhidUVSSEF2Y0phCm5hb1plY0JVQVJ0aUxYT2poOTFBNkFvNVpET2RETllOUkNnTGI2czdDVVhSKzNLenZWRmNJVFRSdGtTTkxKMTUKZzRoallyQUtEWTFIM09zd1EvU3JoTG9GQndneGJJQ1F5eFNLaXQ0OURrK2V4c3puMUJFNzE2aWlJVmdZT0daTwp5SWF5ekJZdW1Gc3M0MGprbWhsbms1ZW5hYjhJTDRUcXBDZS9xYnZtNXdOaktaVVozamJsM2QxVWVtcVlOdVlWCmNFY1o0UXltQUJZS3k0VkUzVFJZUmJJZGV0NFY2dVlIRjVZUHlFRWlZMFRVZStYVVJaVkFtaU9jcmtqblVIT3gKMWJqelJxSlpMNVR3b0ZDZzVlZUR6dVk0WlRjYwotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
  tls.key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2Z0lCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktnd2dnU2tBZ0VBQW9JQkFRQ25xVnd5UW8yMnJHNm4KVVpjU2UvR21WZnI5MEt6Z3V4MDk0NjhwU1NRZHBEcTlSVFFVT3ZmQVRQQlc4MXdCUmZQMS9yeUVoc2hydUFLYQo5LzVoKzVCL3g4bmN4VFhwbThCN3ZEN2V0djhXdXJ5S1BzSUx1aWRPRDBHUVNFVG83N0FYTTdGZmlST3IwMWo3Cnc2UVB3dVB2QkpTcDNpa2lDL0RjdkU2Nmx2SUVYTjdkU2dEZGR2dXZHUU5EV09ZbEdaaGY1RkhXLzVkclBIdU8KOXp1eVVHK01NaTFpUCtSQk1QUmdJZTZ2OEJwT2dyc2dkdG1YTGE0Vk1zUE0rMFhmRDBIOGNTZi8ySDZXUzQvNwpEOEF1bG5QSW9LY1krRkxKUEFtM0lUUjcvbDZRMElRdU1TdzZCTEthZkJGbkJWY1RRU0g3eUpkQUo1Z0g0VllECnIyamtVWkwzQWdNQkFBRUNnZ0VBRlcwb0RTYnRqcm9tbDFkdW83d1hPOEgzMjRGVU5wRnpGbyt4dU9oUi9KVWEKWDBuU3lBQnBNbUxOYkM5RVEzSzV6MmJkN0xSL2lkU2E4S0cweEF6WmdKcjdDZGhpSUJmNWdnRk5WT1VLQ3lZKwpKZzlkem1YY2ZyWDdFNnllQnk2LzBFSHVSRjZlUVowMjNWQ09vajBEMHNOQkdjYjhkcm9UN3F4YUJnVWkvMlRjClkvL1o1WGl3ZDFIb0pmaWxrMXI0SEZnNmJlQ3NtWnJDREJQcGdqK29vbGdFYzdxdkY4T3ErNDlZUjlJc1FLTTAKUGx5ZVdkdjlPZkg0MHRwVVZXQi8zd01kd3JFT0E2Z1MrZ3BCWEcrblQyUXNjTkZrSnRueWM0SFB5SlBQSkJtcQpYeXVhQjlIelJZQmI4d2w2cTFxUllKNVFDZVhibDhoTGZ2TCtHRzkwd1FLQmdRQzZaQXFMelRLMWs4c1c1TU5XCmYzQWthd3Ryd21LbERQY1JSUkRsTXFTTkwwY0tUelh4YVBMcXRZMDRZbmNiK2tvS3dJeXpXaTVrdzRJR1dnQXMKUXdVZ2Q5RnFFRnBEZHV6UDBxU2UvM3RBTWR6UEY2Q3dTeDk1UnpGNnBwQ01aV2ZKQ2dvWU5PZGppMU1tTS9rRwpyMFFDczJNZ0YrNzdzSW80NXBCN0FmTm9FUUtCZ1FEbVJyUnRHS29rVWlEWU9GVUZDbWs0T3kzbzJUMmJiaCs2ClUxWHZ4WmRMNnRPVHIrT1N5dlFXQ2VBaUpQZ1ZuYWhQS3Zmc1NuODQvN2QySDY4WTRvbzVxT0xDZHhRL1Z0clUKT2QxU2FqQ1Z4b3VSR2tvTjM2SmlBNXBKQTFuN2FuNHh1MStXcC9odTdQcGZsN1dFQllYRk9EbnJZZjV5OTBQSApBSVE3emR5U2h3S0JnUUNxZlZ1UUtPL2JXd2FIT0ZUY3g5Q2gzekFoTHpyZjBnNGtROUtDYzJKRXFod0crQkZWCmNqUFFNS1N1RUpMMmltZ3prWkNoZFRtK2ZYNXZwTjlIblQ0UlJzZk1ob3lwN1J3THRKZFR3RWpTblVsbVBDeUYKVlJIQzh6WDFCR3B2b1VuZmdFbGZmdlN2L3Y3ZGtPaVdEcmJjNlkwZ0RBUlRRRllPV2dlS0hHeXlvUUtCZ1FDZgozWkpBOHhDYnFwQzJ5MVRxN1BGalltSmE5d1o0TTVtL1J6K3YrQ016UjFHZmhFcWZqRnFzT2lycVNYUVp2Wnd0CmFnMDRjL2VpNEpURFl2ZXlkUU8xUi9RMVFXcERGczlRNnVNbDVpYll0RUFNZW8zUzErRHAzc3ByeWZIY1EzQmMKb2xLWVN3Q0VNZTBZRkVDbDZSZVhkWk53UUZYZ0JwMTlPSFNVK0RRYlhRS0JnRmRsZHFWcmJ5N1crVEF4dGdMZApQZzJTemo3NHUyMjlmTkZldktRZ0RXUHIzMUJOSitrTEFFRzVKRXlncXJSWDF0OHdCajhMUlh3ZnBPSXhUa2RnCmxEMkd2a3BFM0V0cDJKSDlKbEQ3OVVQc1htN0hDT2E0bjRrWmtINW1qWUY5YzhMSjh1MFJRdDNEQVRoaXJQaVkKWlZpMEhtWWNuVmp5L0RxNWRwc0tHU0FoCi0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0K
kind: Secret
metadata:
  name: root-ca
  namespace: cert-manager
type: kubernetes.io/tls
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  annotations:
    force: update
  name: enterprise-ca
spec:
  ca:
    secretName: root-ca
EOF

kubectl create ns cicd-proxy

# create certificates
export hostip=$(hostname  -I | cut -f1 -d' ' | sed 's/[.]/-/g')

kubectl create -f - <<EOF
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: kube-oidc-proxy-tls
  namespace: cicd-proxy
spec:
  secretName: kube-oidc-proxy-tls
  secretTemplate:
    labels: {}
  commonName: "cicd-proxy.cicdproxy.svc"
  isCA: false
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  usages:
    - server auth
    - client auth
  dnsNames:
    - "cicd-proxy.cicdproxy.svc"
  issuerRef:
    name: enterprise-ca
    kind: ClusterIssuer
    group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cicd-proxy-tls-certificate
  namespace: cicd-proxy
spec:
  secretName: cicd-proxy-tls-certificate
  secretTemplate:
    labels: {}
  commonName: "cicd-proxy.apps.$hostip.nip.io"
  isCA: false
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  usages:
    - server auth
    - client auth
  dnsNames:
    - "cicd-proxy.apps.$hostip.nip.io"
  issuerRef:
    name: enterprise-ca
    kind: ClusterIssuer
    group: cert-manager.io
EOF

export CERT=$(kubectl get cm kube-root-ca.crt -n cicd-proxy -o json | jq -r '.data["ca.crt"]' | base64 -w 0)

sed "s/IPADDR/$hostip/g" < ./cicd-proxy_template.yaml | sed "s/CERTPEM/$CERT/g"  > /tmp/cicd-proxy-values.yaml

helm install cicd-proxy tremolo/cicd-proxy -n cicd-proxy -f /tmp/cicd-proxy-values.yaml

# Create namespace for our pipeline to manipulate

kubectl create -f target-ns.yaml