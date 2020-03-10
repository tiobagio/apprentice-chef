# Download profiles for Audit cookbook


for PROFILE in \
linux-baseline \
cis-centos7-level1 \
cis-ubuntu16.04lts-level1-server \
windows-baseline \
cis-windows2012r2-level1-memberserver \
cis-windows2016-level1-memberserver \
cis-rhel7-level1-server \
cis-sles11-level1 
do
  echo "${PROFILE}"
  VERSION=`curl -s -k -H "api-token: $TOK" https://anthony-a2.chef-demo.com/api/v0/compliance/profiles/search -d "{\"name\":\"$PROFILE\"}" | /snap/bin/jq -r .profiles[0].version`
  echo "Version:  ${VERSION}"
  curl -s -k -H "api-token: $TOK" -H "Content-Type: application/json" 'https://anthony-a2.chef-demo.com/api/v0/compliance/profiles?owner=admin' -d  "{\"name\":\"$PROFILE\",\"version\":\"$VERSION\"}"
  echo
  echo
done