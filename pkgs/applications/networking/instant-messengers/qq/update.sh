#! /usr/bin/env nix-shell
#! nix-shell -i bash --pure --keep GITHUB_TOKEN -p nix git curl cacert nix-prefetch-git jq

set -euo pipefail

cd $(readlink -e $(dirname "${BASH_SOURCE[0]}"))

payload=$(curl https://im.qq.com/rainbow/linuxQQDownload | grep -oP "var params= \K\{.*\}(?=;)")
amd64_url=$(jq -r .x64DownloadUrl.deb <<< "$payload")
arm64_url=$(jq -r .armDownloadUrl.deb <<< "$payload")

urlhash=$(grep -oP "(?<=QQNT/)[a-e0-9]+(?=/linuxqq)" <<< "$amd64_url")
version=$(grep -oP "(?<=/linuxqq_).*(?=_amd64.deb)" <<< "$amd64_url")

amd64_hash=$(nix-prefetch-url $amd64_url)
arm64_hash=$(nix-prefetch-url $arm64_url)

# use friendlier hashes
amd64_hash=$(nix hash to-sri --type sha256 "$amd64_hash")
arm64_hash=$(nix hash to-sri --type sha256 "$arm64_hash")

cat >sources.nix <<EOF
# Generated by ./update.sh - do not update manually!
# Last updated: $(date +%F)
{
  version = "$version";
  urlhash = "$urlhash";
  arm64_hash = "$arm64_hash";
  amd64_hash = "$amd64_hash";
}
EOF
