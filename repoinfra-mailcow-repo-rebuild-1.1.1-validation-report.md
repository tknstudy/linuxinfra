RepoInfra Mailcow Repository Rebuild 1.1.1

Release validation report

Validation date: 2026-07-22Release decision: Approved for a controlled first run on the Rocky Linux 9 Repo VMArchive: repoinfra-mailcow-repo-rebuild-1.1.1.tar.gzArchive size: 22,547 bytesSHA-256: 3575185ad2233c243d9ec1bbf0285a9578f394310bdb3c6fb45c0e7c621f6ee2

This approval applies only to version 1.1.1. Version 1.0.0 is rejected and the intermediate 1.1.0 archive is superseded. Neither earlier archive should be run.

Purpose

The package repairs the Mailcow host-prerequisite RPM repository when the client can see git-2.52.0-1.el9 but cannot resolve its exact split packages and dependency closure, particularly:

git-core-2.52.0-1.el9.x86_64

git-core-doc-2.52.0-1.el9.noarch

perl-Git-2.52.0-1.el9.noarch

It stages packages from isolated official Rocky Linux 9 BaseOS, AppStream, and CRB sources, validates the exact Git component set, downloads the full hard-dependency closure, verifies package signatures, runs an isolated repository-closure check, publishes transactionally, and validates Apache HTTP publication.

Why 1.0.0 was rejected

Static and mocked runtime review found release-blocking defects in the original package:

The generated rollback script contained broken quoting and could complete without restoring files.

Existing RPMs overwritten by publication were not backed up.

HTTP publication failures were warning-only, allowing an overall successful exit even when the repository was not reachable.

Automatic source selection could choose an older Rocky vault whose Git component versions did not match the already-published git RPM.

Dry-run behavior and package prerequisites were incomplete.

Signature trust, repository-closure validation, locking, SELinux persistence, service-state restoration, and path-safety controls were insufficient.

Corrections in 1.1.1

Version 1.1.1 includes the following controls:

Exact alignment to the highest existing git version-release under /srv/repo/rpms.

Exact source checks for git, git-core, git-core-doc, and perl-Git before download.

Current Mailcow RHEL host prerequisites: git, openssl, curl, gawk, coreutils, grep, and jq, plus ca-certificates.

Isolated official Rocky 9 BaseOS, AppStream, and CRB source definitions.

dnf download --resolve --alldeps, preventing dependencies already installed on the Repo VM from being omitted from the offline repository.

Full Rocky Linux 9 signing-key fingerprint verification.

A run-scoped RPM database and rpm -K validation for every staged RPM.

Temporary repository metadata plus local-only dnf repoclosure before publication.

Transactional publication with separate records for new and replaced files.

Backups of overwritten RPMs, repository metadata, and Apache configuration.

Automatic rollback after any post-publication failure and a retained manual rollback script after success.

Preservation and restoration of the prior HTTPD active/enabled state.

Fatal local HTTP checks for canonical, compatibility, aggregate, and key resources.

Persistent SELinux httpd_sys_content_t mapping for /srv/repo, followed by restorecon.

Firewalld runtime/permanent state tracking and rollback.

Exclusive nonblocking run lock.

Strict absolute-path and path-hierarchy validation before filesystem mutation.

No blanket recursive permission broadening over /srv/repo.

Generated client repository with gpgcheck=1 and the Rocky 9 OS-provided key as the first-use trust anchor.

Exact package inventory and SHA-256 package self-check.

Static validation results

Check

Result

Archive path traversal and absolute-path check

PASS

Archive member-type check; regular files/directories only

PASS

Archive root containment

PASS

Archive member count

PASS — 20 members

Extracted package exact inventory

PASS

Internal SHA-256 checksums

PASS

Bash syntax for all executable scripts

PASS

Unix line endings

PASS

Required files and version invariants

PASS

Executable-bit validation

PASS

Help interfaces

PASS

Documentation/code consistency review

PASS

ShellCheck was not installed in the validation container, so no ShellCheck claim is made. Bash parser validation and scenario-based runtime tests were completed instead.

Mocked runtime validation results

The final 1.1.1 working tree passed all twelve scenario scripts:

Successful build/publication plus successful manual rollback — PASS.

HTTP publication failure plus automatic rollback — PASS.

Failure during first publication metadata build plus automatic rollback — PASS.

Missing source package rejected before publication — PASS.

Dry run leaves repository, Apache, firewall, and HTTP publication unchanged — PASS.

Unsafe Git downgrade rejected — PASS.

Prior HTTPD active/enabled state restored by rollback — PASS.

Rocky signing-key fingerprint mismatch rejected — PASS.

Unsafe repository path configuration rejected before mutation — PASS.

Dry-run rollback status and client trust-anchor generation — PASS.

Repoclosure failure receives a specific pre-publication diagnosis and does not publish — PASS.

Apache syntax failure plus automatic rollback — PASS.

Official-source checks

The implementation was reviewed against primary sources:

Mailcow installation prerequisites: https://docs.mailcow.email/getstarted/install/

DNF download plugin behavior: https://dnf-plugins-core.readthedocs.io/en/latest/download.html

DNF repoclosure behavior: https://dnf-plugins-core.readthedocs.io/en/latest/repoclosure.html

Rocky Linux 9 AppStream Git packages: https://dl.rockylinux.org/pub/rocky/9/AppStream/x86_64/os/Packages/g/

Rocky Linux 9 AppStream Perl packages: https://dl.rockylinux.org/pub/rocky/9/AppStream/x86_64/os/Packages/p/

Rocky Linux 9 signing-key fingerprint: https://rockylinux.org/resources/gpg-key-info

RHEL 9 SELinux guidance for Apache content under /srv: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/using_selinux/

The current Rocky 9 AppStream index was confirmed to contain the exact 2.52.0-1.el9 builds of git, git-core, git-core-doc, and perl-Git at validation time.

Live acceptance boundary

The validation environment is not the target Rocky Linux 9 Repo VM. It cannot honestly prove live behavior of:

real Rocky DNF dependency solving and downloads;

real RPM signature output on the Repo VM;

the Repo VM's SELinux policy and labels;

firewalld zone selection;

Apache modules/configuration outside the managed file;

remote reachability from mail1.

The package therefore remains approved for a controlled first run, not described as already production-proven. Its first Repo VM run is the live acceptance test. It is designed to stop before publication for source, version, key, signature, or repoclosure failures and to roll back automatically after a later publication failure.

Required execution sequence

On the Repo VM:

sha256sum -c repoinfra-mailcow-repo-rebuild-1.1.1.tar.gz.sha256

tar -xzvf repoinfra-mailcow-repo-rebuild-1.1.1.tar.gz
cd repoinfra-mailcow-repo-rebuild-1.1.1

bash ./bin/package-self-check.sh
sudo bash ./run.sh --dry-run
sudo bash ./run.sh

Do not run the publish command if either the package self-check or dry run reports a failure.

After an overall PASS on the Repo VM, run on mail1:

sudo dnf clean all
sudo dnf makecache
sudo dnf install -y git

Then verify:

git --version
rpm -q git git-core git-core-doc perl-Git

Final decision

Version 1.1.1 is approved for the controlled Repo VM self-check, dry run, and first live build. Versions 1.0.0 and 1.1.0 are not approved.
