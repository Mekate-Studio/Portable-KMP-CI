# Portable KMP CI Sample

This repository is a minimal Kotlin Multiplatform sample for a portable mobile
CI setup built with Amper, Fastlane, and GitHub Actions.

It is intentionally small:

- `android-app/`
- `ios-app/`
- `shared/`
- `.github/workflows/mobile-ci.yml`
- `fastlane/`
- `scripts/ci/`
- `scripts/regenerate_from_amper.sh`

The app itself started from:

```bash
amper init compose-multiplatform
```

and was then trimmed down to a mobile-only shape by removing the generated JVM
module.

You can refresh the generated app layer in place with:

```bash
./scripts/regenerate_from_amper.sh
```

That script deletes and recreates the Amper-generated app layer:

- `amper`
- `amper.bat`
- `project.yaml`
- `android-app/`
- `ios-app/`
- `shared/`

while preserving the CI files and release helpers that belong to this sample.

## Purpose

This sample is not trying to show app architecture. It exists to prove that the
CI pattern is reproducible with a minimal Kotlin Multiplatform project.

For the longer explanation of the design, see
[`docs/portable-kmp-ci.md`](docs/portable-kmp-ci.md).

The published documentation site is available at:
[https://mekate-studio.github.io/Portable-KMP-CI/](https://mekate-studio.github.io/Portable-KMP-CI/)

It exercises:

- Android debug and release builds
- Android tests
- iOS debug and release builds
- shared CI job dispatch
- runtime secret materialization for release flows

## Local smoke test

Set a writable Amper cache:

```bash
export AMPER_BOOTSTRAP_CACHE_DIR="$PWD/.amper-cache"
```

Run the shared jobs:

```bash
./scripts/ci/run_job.sh android-build-debug
./scripts/ci/run_job.sh android-test
./scripts/ci/run_job.sh android-build-release
./scripts/ci/run_job.sh ios-build-debug
```

Those jobs run `bundle install` through the shared CI helper layer, so you do
not need a separate manual Bundler step just to smoke-test the sample.

Run those smoke-test commands sequentially when using a single local checkout.
In CI they run in separate jobs, but locally multiple first-run Amper processes
can contend with each other.

`ios-build-release` is part of the sample workflow too, but on local machines it
can still depend on the host having a resolvable iPhone simulator destination.
For a portable local smoke test, `ios-build-debug` is the safer baseline check.

## Self-hosted GitHub Actions verification

If you want to verify the workflow using real GitHub Actions orchestration on
your own Mac, this repo also includes:

- [`.github/workflows/mobile-ci-self-hosted.yml`](.github/workflows/mobile-ci-self-hosted.yml)

That workflow is intended for a self-hosted macOS runner with the label:

- `kmp-sample`

Recommended setup:

1. Add your Mac as a self-hosted runner for this repository in GitHub.
2. Give it the labels `self-hosted`, `macOS`, `ARM64`, and `kmp-sample`.
3. Install a working host Ruby on that Mac runner, preferably via
   `brew install ruby`. The shared CI helper will install the Bundler version
   required by `Gemfile.lock` automatically. This sample's self-hosted
   workflow intentionally uses the machine's Ruby instead of
   `ruby/setup-ruby`, because `ruby/setup-ruby` expects the GitHub-hosted
   macOS toolcache layout under `/Users/runner`.
4. Run the `Mobile CI (Self-hosted)` workflow manually from GitHub using
   `workflow_dispatch`.

For a public repository, keep this self-hosted workflow on manual dispatch only.
That avoids exposing your machine to arbitrary fork pull requests.

## Shared CI job names

These are the portable job names used by the dispatcher:

- `android-build-debug`
- `android-build-release`
- `android-test`
- `ios-build-debug`
- `ios-build-release`
- `ios-archive-release`
- `ios-testflight`
- `publish-internal`
- `promote-alpha`
- `promote-beta`
- `promote-production`

## Required GitHub secrets for release flows

### Android

- `GOOGLE_PLAY_JSON_KEY`
- `ANDROID_KEYSTORE_FILE` or `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_PACKAGE_NAME` if you change the sample package name

To use real Play publishing, also enable the commented Android `signing` block
in [`android-app/module.yaml`](android-app/module.yaml).

### iOS

- `IOS_BUNDLE_IDENTIFIER`
- `IOS_DEVELOPMENT_TEAM`
- `IOS_PROVISIONING_PROFILE_SPECIFIER`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_FILE` or `APP_STORE_CONNECT_API_KEY_BASE64`

Important: the Apple signing certificate and provisioning profile still need to
exist on the macOS runner host.

## License

[MIT](LICENSE)
