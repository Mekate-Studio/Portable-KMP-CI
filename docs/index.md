---
title: Portable KMP CI Sample
---

# Portable KMP CI Sample

A reproducible Kotlin Multiplatform mobile CI sample built with Amper, Fastlane, and GitHub Actions.

![Portable KMP CI architecture](./assets/portable-ci-architecture.svg)

## Start Here

- [Read the full article](./portable-kmp-ci/)
- [Browse the repository on GitHub](https://github.com/Mekate-Studio/Portable-KMP-CI)

## What This Repo Shows

- thin GitHub Actions workflows
- repository-owned CI job dispatch
- Fastlane as the command layer
- Amper as the build system
- a self-refreshing sample project scaffold

## Local Maintenance

When the Amper template changes, regenerate the sample app layer with:

```bash
./scripts/regenerate_from_amper.sh
```

## View source on GitHub

- [Repository root](https://github.com/Mekate-Studio/Portable-KMP-CI)
- [Article source](https://github.com/Mekate-Studio/Portable-KMP-CI/blob/main/docs/portable-kmp-ci.md)
- [Regeneration script](https://github.com/Mekate-Studio/Portable-KMP-CI/blob/main/scripts/regenerate_from_amper.sh)
