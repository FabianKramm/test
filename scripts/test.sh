# Specify Addresses
IP_ADDRESSES="10.141.0.200-10.141.0.220"
KUBERNETES_VERSION=v1.32.1
VCLUSTER_VERSION=v0.26.0-beta.4

# Create vcluster.yaml
cat <<EOF > ./vcluster.yaml
deploy:
  metallb:
    enabled: true
    ipAddressPool:
      addresses:
      - $IP_ADDRESSES
  ingressNginx:
    enabled: true
controlPlane:
  distro:
    k8s:
      version: $KUBERNETES_VERSION
  advanced:
    registry:
      enabled: true
EOF

# Install vCluster
curl -sfLk https://github.com/loft-sh/vcluster/releases/download/${VCLUSTER_VERSION}/install-standalone.sh | sh -s -- --config ./vcluster.yaml
