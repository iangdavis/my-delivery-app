# TestFlight delivery

Pushing to `main` runs the TestFlight workflow. It uses fastlane to:

1. query the latest TestFlight build number;
2. increment the Xcode build number;
3. archive and export `myDeliveryApp` with automatic signing;
4. upload the resulting build to TestFlight.

## One-time setup

In App Store Connect, create an API key with **Developer** access and download its `.p8` file. In this repository, go to **Settings → Secrets and variables → Actions** and add these repository secrets:

| Secret | Value |
| --- | --- |
| `APP_STORE_CONNECT_KEY_ID` | The API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | The issuer ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Base64-encoded contents of the downloaded `.p8` file |

On macOS, create the third value with:

```sh
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```

The workflow uses the Apple Developer team already configured in the Xcode project (`G6T78BC5DH`). The API key must have permission to access certificates, identifiers, and profiles so Xcode can manage signing during the CI archive.

Finally, in App Store Connect → **TestFlight** → your internal tester group, enable automatic distribution of new builds. The workflow uploads the build and exits rather than waiting for Apple’s build processing.

## Manual release

Open the **TestFlight** GitHub Actions workflow and select **Run workflow**.
