# TCE App Platform Adding Packages How-To

## Summary

This document describes how to add an additional TCE package to the App Platform meta-package.

## Assumptions

This document is intended for maintainers of official repositories, as defined in the [community-edition/docs/packaging](https://github.com/vmware-tanzu/community-edition/tree/main/docs/packaging) README. Currently the role is limied to VMware employees.

## Concepts

### Meta-package

A meta-package is defined as a TCE package that installs a set of other already present TCE packages. It is not intended to add new functionality on its own, but deploy a set of existing functionalities to achieve a particular outcome.

### App Platform

App Platform is an instance of a meta-package with a goal of allowing TCE users to deploy a set of TCE packages sufficient to deploy a workload. App Platform itself provides little/no novel functionality, but comprises an opinion about what TCE packages are required to achieve the outcome. 

The OSS App Package concept is comparable to proprietary Tanzu Application Platform, although reduced in scope.

### Configuration of App Platform and Included TCE Packages.

Configuration is deferred to the included TCE package. For instance, if end users are interested in changing the default behavior of, say, knative-serving, they will learn about and provide configuration for knative-serving, not app-platform.

### Similarities and Differences to TCE Packaging of Upstream Projects

TCE provides guidance about how to include other upstream projects into TCE - e.g. kpack, knative, etc., as described in the [TCE Documentation](https://tanzucommunityedition.io/docs/latest/package-creation-step-by-step/). Principly it describes how to
- Use Vendir to syncronize upstream content to a local directory.
- Import/pin a version of the upstream's manifests
- Create ytt overlays to alter via templating those manifests for use in TCE.

These importation steps are NOT APPLICABLE or required for App Platform. As a meta-package, it refers to _packages that have already been imported into TCE_, so any packaging concerns are dealt with in the included package; and _adds no new functionality itself_ so does not have a _vmware-tanzu/package-for-${PACKAGE_NAME}_ -style repo of its own. App Platform is wholly an artifact within TCE.

App Platform _does_ leverage the other structures of the TCE packaging process, to take advantage of the machinery as well as be more easily understandable within the TCE context.

## OSS Contribution process

This may have been completed already, or be the responsibility of a PM, not a developer. The end goal of this process is to have a pull request accepted into TCE. The process is documented in the [TCE Proposal Process](https://github.com/vmware-tanzu/community-edition/tree/main/docs/designs). This document will focus on the developer work required.


## Add a Package to App Platform- Walkthrough

1. Get the repository

    Follow your preferred process to collaborate on a git project. For instance, 
    
    1. Fork the https://github.com/vmware-tanzu/community-edition repo.
    1. git checkout the fork 
    1. Create a new feature branch and switch to it

1. Add a new minor version of app-platform.
    Follow semver principles - adding a new package likely introduces new capabilities while introducing no breaking changes, so is probably a minor release.

    ```
    cd addons/packages/app-platform
    cp -r [a.N.c] [a.N+1.0]
    ```
    Where a is the major version, N is the current minor, and N+1 is the new minor version. Incrementing minor version resets the c/bugfix version to 0.

1. Add/edit boilerplate files.
    1. [version]/bundle/.imgpkg/bundle.yml

        Consider adding yourself as an author.
    1. [version]/bundle/.imgpkg/images.yml

        Nothing to add or change here! This file tracks what upstream images are required for the project; app-platform has no upstream packages.
    1. [version]/config/rbac

        Likely nothing to add or change here - this template adds service accounts under which to add the package's components to TCE. You may need to add a role here if you are interacting with a different part of the system.
    1. [version]/README.md

        Edit to describe your new package, and any other changes introduced.

    1. hack/

        This directory contains bash scripts to help install, uninstall etc packages during development and are not used after release. Use these or add additional functionality as convenient.
    1. metadata.yaml

        Applies to the overall App Platform package, so unlikely to change. Review if the maintainer, description or other data is changing.

1. config/[your-package]

    Create a new template file to contain the PackageInstall and other CRDs to tell `kapp` how to deploy your package. The existing files may serve as examples.



