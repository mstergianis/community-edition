# App Platform

This meta-package provides a curated collection of other TCE packages to allow a streamlined
developer experience. Namely:
  1. User easily creates a development environment with TCE
  1. User creates a Tanzu workload from source code using a supply chain
  1. User easily iterates and debugs their source code using TCE. 
  1. Users move their applications from TCE to TAP as their development environment. 


## Supported Providers

The following table shows the providers this package can work with.

| AWS  |  Azure  | vSphere  | Docker |
|:---:|:---:|:---:|:---:|
| ✅  |  ✅  | ✅  | ✅ |

## Components

* contour: ingress controller
* cert-manager: certificate management functionality using [cert-manager](https://cert-manager.io/docs/)
* kpack: platform implementation of [Cloud Native Buildpacks](https://buildpacks.io) (CNB).
* knative-serving: serverless functionality using [Knative](https://knative.dev/)

TO BE ADDED
* Cartographer
* FluxCD Source Controller
* ootb-supply-chain-basic
* Cert injection webhook
* Convention controller
* Developer conventions

## Configuration

The following configuration values can be set to customize the gatekeeper installation.

### Global
None now.

Future?
| Value | Required/Optional | Description |
|-------|-------------------|-------------|
| `namespace` | Optional | The namespace in which to deploy gatekeeper. |

### App Platform Configuration

_Currently there is no App Platform customization_.

## Usage Example

