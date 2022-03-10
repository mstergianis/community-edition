package repo includes template and specific packaging
Defines metadata and image package bundle (imgpkg)

Starlark is used to extend ytt and add funtions to objects
Implements profile and exclusion

TCE Metapackage will not have transformations at this time

Fork based on main branch

PAckage CR (custom resource)
- values schema
- placeholder

Does metapackage become a separate package for TCE OSS?

Buidling values schema

Using contour package as a model for source struture and components. Image package has a bundle which is this case will not contain anything interesting, as 
meta package only contains references to other packages, which themselves contain bundles. (A bundle being a collection of refereces to CRDs and runnable container images.)



Jira: https://jira.eng.vmware.com/projects/TAPTCE/
Gitlab: https://gitlab.eng.vmware.com/tap/tap-packages
Github: https://github.com/mstergianis/community-edition/tree/meta-package
Charter: https://docs.google.com/document/d/1GMv660C8yShLpR4T2pM1x9Sh5SYjFgxusocUPiOBfOw
Miro: https://miro.com/app/board/o9J_lGE2ec4=/?moveToWidget=3074457367087328837&cot=14

Process of bringing Carvel package to TCE

Proposal for TCE package https://github.com/vmware-tanzu/community-edition/blob/main/docs/packaging/considerations/proposal.md
- Create an issue
- Create a design doc
- Discuss with maintainers
- Move through approval process

Discussion happens in Kubernetes slack, https://kubernetes.slack.com/archives/C02GY94A8KT


## Metapackage process

- Created metadata yaml
- Created an image directory
- Built a blank bundle
- Push to any repo
- Deploy the CRs with kapp
- see it with `tanzu package available -n tap-install`

### Adding Contour

`touch addons/packages/meta-package/0.1.0/bundle/config`

Add the ytt templates to for 


Add a few Jira tickets

Integrate packages:
- Cartographer
- Cert injection webhook
- FluxCD

Track status on:
- ootb-supply-chain-basic
- Tanzu app cli

- End to end testing
- Documentation
  - Use
  - Dev



