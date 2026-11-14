# Changelog

## 1.0.0 - 2026-11-11
- Initial DANISH ARMY ROOT SUITE repository package.
- Added Termux installer, updater, and uninstaller.
- Added version tracking and repository documentation.
- Main manager includes TMP file listing, selection, preview, permission management, confirmed deletion, and panel/driver downloads.

## 1.0.2
- Added GitHub User ID approval gate before the main menu.
- Added GitHub Issue access request and re-check option.

## 1.0.3
- Added menu option 9 to submit improvement suggestions to a separate GitHub repository.
- Improvement suggestions open as prefilled GitHub Issues; user reviews and submits them.

## 1.0.4
- Auto-submits access request after YES through a secret-backed API proxy.
\n## 1.0.5\n- Configured the existing Cloudflare Worker URL.\n- Matched access requests to JSON fields userId and appVersion.\n- Added expiry-aware approval entries USER_ID|EXPIRY_UNIX.\n- Access request menu now submits through the configured Worker.\n