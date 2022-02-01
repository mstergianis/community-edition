# Package Maintainer Docs

This page offers an index of resources for potential package maintainers looking
for guidance on how to get their package into TCE.

## Creation

Details on the creation and contribution of a package.

1. Ensure that you have met all the [prerequisites](./prerequisites/)
2. Create the [directory structure](./directory-structure)
3. Use [vendir](./tooling/#vendir) to synchronize [upstream content](./upstream-content/#example-usage)
4. Use [kbld](./tooling/#kbld) to create [immutable image references](./image-refs/#example-usage)
5. Define [configurable parameters](./configuration/) in the schema
6. Create [overlays](./overlays/) to apply configuration over the upstream content
7. Create [tests](./testing/)
8. Create [documentation](./documentation/)
9. [Linting](./linting/)
10. [Publish](./publish/) the package
11. Create [Package](./cr-files/#package) and [PackageMetadata](./cr-files/#packagemetadata) custom resources

## Maintenance

Details expectations of package maintenance over time.

* [Community Support](maintenance/community-support.md)
* [Deprecation](maintenance/deprecation.md)
* [Maintenance](maintenance/maintenance.md)
* [Security](/maintenance/security.md)
* [Versioning](/maintenance/versioning.md)

## Roles

Details on the types of roles described in the above.

* [Maintainers](roles/maintainer.md)
* [End User](roles/end-user.md)
