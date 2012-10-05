set -o errexit
#set -x

KEYCHAIN_PRIVKEY_NAME="MetaZ Sparkle Private"

if [ "${CONFIGURATION}" != "Release" ]; then exit; fi
if [[ -z "$(security find-generic-password -s '$KEYCHAIN_PRIVKEY_NAME')" ]] ; then exit; fi

PATH=$PATH:/usr/local/bin:/usr/bin:/sw/bin:/opt/local/bin
export GITV=`git log -n1 --pretty=oneline --format=%h`
export DATEV=`date +%y.%m.%d.%H`

VERSION=$(defaults read "$BUILT_PRODUCTS_DIR/$PROJECT_NAME.app/Contents/Info" CFBundleShortVersionString)
DOWNLOAD_BASE_URL="http://github.com/downloads/griff/metaz"
RELEASENOTES_URL="http://griff.github.com/metaz/release-notes.html#version-$VERSION"

ARCHIVE_FILENAME="$PROJECT_NAME-$VERSION.zip"
DOWNLOAD_URL="$DOWNLOAD_BASE_URL/$ARCHIVE_FILENAME"

WD=$PWD
cd "$BUILT_PRODUCTS_DIR"
rm -f "$PROJECT_NAME"*.zip
ditto -ck --keepParent "$PROJECT_NAME.app" "$ARCHIVE_FILENAME"

mkdir -p DSYMS
cp -R *.dSYM DSYMS/

#ditto -ck --keepParent "$PROJECT_NAME.app.dSYM" "$PROJECT_NAME-$VERSION-$GITV+dYSM.zip"
ditto -ck DSYMS "$PROJECT_NAME-$VERSION-$GITV+dYSM.zip"
rm -rf DSYMS

SIZE=$(stat -f %z "$ARCHIVE_FILENAME")
PUBDATE=$(date +"%a, %d %b %G %T %z")
SIGNATURE=$(
	openssl dgst -sha1 -binary < "$ARCHIVE_FILENAME" \
	| openssl dgst -dss1 -sign <(security find-generic-password -g -s "$KEYCHAIN_PRIVKEY_NAME" 2>&1 1>/dev/null | perl -pe '($_) = /"(.+)"/; s/\\012/\n/g') \
	| openssl enc -base64
)

[ $SIGNATURE ] || { echo Unable to load signing private key with name "'$KEYCHAIN_PRIVKEY_NAME'" from keychain; false; }

cat > "$PROJECT_NAME-$VERSION.xml" <<EOF
		<item>
			<title>Version $VERSION</title>
			<sparkle:releaseNotesLink>$RELEASENOTES_URL</sparkle:releaseNotesLink>
			<pubDate>$PUBDATE</pubDate>
			<enclosure
				url="$DOWNLOAD_URL"
				sparkle:version="$DATEV"
				sparkle:shortVersionString="$VERSION"
				type="application/octet-stream"
				length="$SIZE"
				sparkle:dsaSignature="$SIGNATURE"
			/>
		</item>
EOF

echo scp "'$HOME/svn/my-cool-app/build/Release/$ARCHIVE_FILENAME'" www.example.com:download/
echo scp "'$WD/appcast.xml'" www.example.com:web/software/my-cool-app/appcast.xml