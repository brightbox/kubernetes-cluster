openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ca.key \
    -out ca.crt -subj "/CN=metrics-server-ca"\
    -addext "subjectAltName = DNS:metrics-server-ca"
    -addext "keyUsage = critical, digitalSignature, keyEncipherment, keyCertSign"

openssl req -batch -config server-cert.cnf -new -nodes -newkey rsa:2048 -keyout tls.key -out tls.csr

openssl x509 -req -days 365 -sha256 -in tls.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -CAserial /tmp/ca.srl -out tls.crt \
    -extfile server-cert.cnf -extensions v3_req

cat ca.crt >> tls.crt

cat > apiservice-bundle.yaml <<EOF
apiVersion: apiregistration.k8s.io/v1beta1
kind: APIService
metadata:
  name: v1beta1.metrics.k8s.io
spec:
  service:
    name: metrics-server
    namespace: kube-system
  insecureSkipTLSVerify: false
  caBundle: $(base64 --wrap=0 ca.crt)
EOF
