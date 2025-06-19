VCLUSTER_PLATFORM_VERSION=v0.26.0-beta.4

# Create platform.yaml
cat <<EOF > ./platform.yaml
ingress:
  enabled: true
  host: loft.bcm.com
  
admin:
  password: bcm123

config:
  loftHost: loft.bcm.com

insecureSkipVerify: true
EOF

# 
helm upgrade vcluster-platform vcluster-platform -n vcluster-platform --repo https://charts.loft.sh --install --version $VCLUSTER_PLATFORM_VERSION --create-namespace --values ./platform.yaml
