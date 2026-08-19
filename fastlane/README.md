# TestFlight delivery

Pushing to `main` runs the TestFlight workflow. It uses fastlane to:

1. query the latest TestFlight build number;
2. increment the Xcode build number;
3. install an existing Apple Distribution certificate and App Store provisioning profiles;
4. archive and export `myDeliveryApp` with manual signing;
5. upload the resulting build to TestFlight.

## One-time setup

In App Store Connect, create an API key with Developer access and download its `.p8` file. In this repository, go to Settings -> Secrets and variables -> Actions and add these repository secrets:

| Secret | Value |
| --- | --- |
| `APP_STORE_CONNECT_KEY_ID` | The API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | The issuer ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Base64-encoded contents of the downloaded `.p8` file |
| `BUILD_KEYCHAIN_PASSWORD` | Any strong password used only for the temporary CI keychain |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Base64-encoded `.p12` Apple Distribution certificate |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Password for the `.p12` certificate |
| `IOS_APP_PROVISIONING_PROFILE_BASE64` | Base64-encoded App Store profile for `com.iandavis.livehive` |
| `IOS_WIDGET_PROVISIONING_PROFILE_BASE64` | Base64-encoded App Store profile for `com.iandavis.livehive.widget` |

On macOS, create base64 secret values with:

```sh
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
base64 -i distribution_certificate.p12 | pbcopy
base64 -i MyDeliveryApp_AppStore.mobileprovision | pbcopy
base64 -i MyDeliveryWidget_AppStore.mobileprovision | pbcopy
```

The workflow uses the Apple Developer team already configured in the Xcode project (`G6T78BC5DH`). CI imports the signing assets into a temporary keychain and does not ask Xcode to create new certificates or profiles during the archive.

Finally, in App Store Connect -> TestFlight -> your internal tester group, enable automatic distribution of new builds. The workflow uploads the build and exits rather than waiting for Apple's build processing.

## Manual release

Open the TestFlight GitHub Actions workflow and select Run workflow.
