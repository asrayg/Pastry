#!/bin/bash
# Archives Pastry and exports a Mac App Store .pkg ready for upload.
# Output: build/appstore/Pastry.pkg
set -euo pipefail
cd "$(dirname "$0")"

xcodebuild -project Pastry.xcodeproj -scheme Pastry -configuration Release \
    archive -archivePath build/Pastry.xcarchive \
    -allowProvisioningUpdates

cat > build/ExportOptions.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store</string>
	<key>teamID</key>
	<string>L6LUXM357X</string>
	<key>destination</key>
	<string>export</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath build/Pastry.xcarchive \
    -exportOptionsPlist build/ExportOptions.plist \
    -exportPath build/appstore \
    -allowProvisioningUpdates

echo
echo "Done: build/appstore/Pastry.pkg"
echo "Upload it with the Transporter app (Mac App Store) or Xcode → Organizer."
