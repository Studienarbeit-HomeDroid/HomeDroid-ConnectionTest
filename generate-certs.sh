#!/bin/bash

set -e

echo "🔐 1. CA erstellen (mit CN=client für Server-Kompatibilität)..."
openssl genrsa -out ca.key 2048
openssl req -x509 -new -key ca.key -out ca.crt -days 365 \
  -subj "/C=DE/ST=BW/L=Ort/O=MyOrg/CN=client"  # WICHTIG: Geändert zu CN=client

echo "🌐 2. san.cnf erstellen..."
cat > san.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = 192.168.178.200

[v3_req]
subjectAltName = @alt_names

[alt_names]
IP.1 = 192.168.178.200
EOF

echo "📡 3. Server-Zertifikat erstellen..."
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -config san.cnf
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 365 -sha256 -extfile san.cnf -extensions v3_req

echo "📱 4. Client-Zertifikat erstellen..."
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr -subj "/CN=client"
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out client.crt -days 365 -sha256

echo "📦 5. Exportiere client.p12 mit legacy..."
openssl pkcs12 -export \
  -inkey client.key \
  -in client.crt \
  -certfile ca.crt \
  -out client.p12 \
  -passout pass:testpass \
  -legacy

echo ""
echo "✅ Alle Zertifikate wurden erstellt!"
echo "📁 Speicherort: ./"
echo "🔐 Passwort für client.p12: testpass"