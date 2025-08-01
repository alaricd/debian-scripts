# debian-scripts
Scripts to keep Debian-based systems updated with all patches while removing
stale packages and kernels.

## Notes on deborphan

Debian dropped the `deborphan` package because it was unmaintained and largely
superseded by modern APT features. Kali follows Debian and no longer ships this
utility. These scripts therefore remove the package if it is installed and do
not attempt to use it.

With `deborphan` removed, the recommended approach to clean unused packages is
to rely on `apt autoremove` in combination with `apt-mark minimize-manual`.
`remove-all-old-packages.sh` automates this process, looping `apt autoremove`
up to ten times and purging `deborphan` itself if it is still installed.
