# COPR Setup for claude-launcher

The package is published at
https://copr.fedorainfracloud.org/coprs/reversejames/claude-launcher/

## Install (users)

```bash
sudo dnf copr enable reversejames/claude-launcher
sudo dnf install claude-launcher
```

This installs the launcher as `/usr/bin/claude` plus a global bash
completion. Run `claude` for the menu or `claude install` to install or
switch the underlying Claude Code build.

## How it is built

The COPR project builds from this GitHub repo (SCM source, `rpkg`
method, spec `claude-launcher.spec`). The spec pulls the release tarball
via `Source0` = the GitHub archive for tag `vX.Y.Z`.

### Cutting a release

```bash
# bump Version in claude-launcher.spec and add a %changelog entry, commit
git tag -a vX.Y.Z -m "claude-launcher X.Y.Z"
git push origin main --tags
```

Then rebuild on COPR (either the webhook fires automatically, or run):

```bash
copr-cli build-package claude-launcher --name claude-launcher
```

### Manual SRPM build (local test)

```bash
rpmdev-setuptree
spectool -g -R claude-launcher.spec          # fetch Source0
rpmbuild -bs claude-launcher.spec            # SRPM
copr-cli build claude-launcher ~/rpmbuild/SRPMS/claude-launcher-*.src.rpm
```

## Auto-rebuild on push (webhook)

The SCM package is configured with `--webhook-rebuild on`. To make GitHub
fire it, add COPR's webhook URL (Project Settings -> Integrations ->
"Resubmit builds ..." URL) to the GitHub repo under
Settings -> Webhooks, content type `application/json`. Until that hook is
added, trigger rebuilds manually with `copr-cli build-package` above.

## Chroots

fedora-43, fedora-44, fedora-rawhide (x86_64 and aarch64). The package is
`noarch`, so one build serves every arch per release.
