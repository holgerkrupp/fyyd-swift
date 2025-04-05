A Swift package to interact with fyyd https://fyyd.de


To use authorization

// In your app's Info.plist
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.mycompany.myapp</string>
    </dict>
</array>

// In your app's code
let fyydClient = FyydSearchManager(
    clientId: "your_client_id",
    clientSecret: "your_client_secret",
    redirectURI: "myapp://oauth/callback"  // Your app's custom redirect URI
)