set -o errexit
#set -x

export KEYCHAIN_PRIVKEY_NAME="MetaZ Sparkle Private"

if [ "${CONFIGURATION}" != "Release" ]; then exit; fi
if [[ -z "$(security find-generic-password -s "$KEYCHAIN_PRIVKEY_NAME")" ]] ; then exit; fi

PATH=$PATH:/usr/local/bin:/usr/bin:/sw/bin:/opt/local/bin

VERSION=$(/usr/libexec/PlistBuddy -c "print :CFBundleShortVersionString" "$BUILT_PRODUCTS_DIR/$PROJECT_NAME.app/Contents/Info.plist")
FULLVERSION=$(/usr/libexec/PlistBuddy -c "print :CFBundleVersion" "$BUILT_PRODUCTS_DIR/$PROJECT_NAME.app/Contents/Info.plist")
DOWNLOAD_BASE_URL="http://github.com/downloads/griff/metaz"
RELEASENOTES_URL="http://griff.github.com/metaz/release-notes.html#version-$VERSION"

ARCHIVE_FILENAME="$PROJECT_NAME-$VERSION.zip"
DOWNLOAD_URL="$DOWNLOAD_BASE_URL/$ARCHIVE_FILENAME"

WD=$PWD
cd "$BUILT_PRODUCTS_DIR"

SIZE=$(stat -f %z "$ARCHIVE_FILENAME")
PUBDATE=$(date +"%a, %d %b %G %T %z")
KEY=$(security find-generic-password -g -s "$KEYCHAIN_PRIVKEY_NAME" 2>&1 1>/dev/null | perl -pe '($_) = /"(.+)"/; s/\\012/\n/g')
SIGNATURE=$(openssl dgst -sha1 -binary < "$ARCHIVE_FILENAME" | openssl dgst -dss1 -sign <(echo "$KEY") | openssl enc -base64)

[ $SIGNATURE ] || { echo Unable to load signing private key with name "'$KEYCHAIN_PRIVKEY_NAME'" from keychain; false; }

cat > "$PROJECT_NAME-$VERSION.xml" <<EOF
			<enclosure
				sparkle:version="$FULLVERSION"
				sparkle:shortVersionString="$VERSION"
				length="$SIZE"
				sparkle:dsaSignature="$SIGNATURE"
			/>
EOF
cat > "$PROJECT_NAME-$VERSION.json" <<EOF
{
  "version": "$FULLVERSION",
  "shortVersionString": "$VERSION",
  "size": $SIZE,
  "dsaSignature": "$SIGNATURE"
}
EOF

echo scp "'$HOME/svn/my-cool-app/build/Release/$ARCHIVE_FILENAME'" www.example.com:download/
echo scp "'$WD/appcast.xml'" www.example.com:web/software/my-cool-app/appcast.xml