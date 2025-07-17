# Changelog

## [1.0.0] - 2025-07-17

### Added
- Initial release with 21+ validation checks
- Core validation script (validate-patch.sh)
- Patch series validator (validate-series.sh)
- Bug finder tool (find-bugs.sh)
- Safe patch testing (test-patch.sh)
- Contribution readiness checker (contribution-checklist.sh)
- Comprehensive documentation

### Fixed (Thanks to Greg KH's review)
- Date validation now checks against current year instead of hardcoded 2025
- Removed `set -e` to show all validation errors instead of exiting on first
- Accept both stable@kernel.org and stable@vger.kernel.org email formats
- Removed all emojis from script outputs for professional appearance

### Improved
- Added related resources section with links to Greg KH's tutorials
- Better error messages and suggestions
- Enhanced documentation with real-world examples

### Known Issues
- Some checks should be integrated into checkpatch.pl (work in progress)