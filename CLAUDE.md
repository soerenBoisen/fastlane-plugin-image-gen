# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A _fastlane_ plugin (`fastlane-plugin-image_gen`) that generates iOS/Android/web image assets (icons, splash screens) from a single master SVG using Inkscape or `rsvg-convert`, and can wire the generated assets into a Cordova `config.xml`.

## Commands

- `rake` — run the full suite (rspec + rubocop). This is the default task and what CI runs.
- `bundle exec rspec` — run tests only. Add a file path to run a single spec file, e.g. `bundle exec rspec spec/image_gen_helper_spec.rb`.
- `rubocop` — lint only.
- `rubocop -a` — auto-fix style issues.
- `bundle exec fastlane test` — runs the example lane in `fastlane/Fastfile`, which calls the `image_gen` action end-to-end against `test/src/logo.svg` using `test/src/logo-gen.json` as the icon spec (requires Inkscape installed locally; the lane hardcodes `inkscape_cmd_macos`).

Test output is written to `test-results/rspec/rspec.xml` (JUnit format, per `.rspec`) and coverage to `coverage/` (SimpleCov, per `spec/spec_helper.rb`).

## Architecture

This is a standard fastlane plugin skeleton (`lib/fastlane/plugin/image_gen.rb` auto-requires everything under `actions/` and `helper/`), with three actions and one helper class:

- **`ImageGenAction`** (`actions/image_gen_action.rb`) — the main action. Flow:
  1. Resolves platform (`:ios`/`:android`/`:web`) either from the `platform_name` param or fastlane's lane context (`SharedValues::PLATFORM_NAME`).
  2. Picks the converter binary (`get_converter_cmd`) based on both the `converter_tool` param (`"inkscape"` default, or `"rsvg-convert"`) and `FastlaneCore::Helper.operating_system` (only `"macos"`/`"linux"` are supported; anything else raises).
  3. Loads a JSON icon spec file describing groups of icons to generate.
  4. For each entry in the spec, builds the tool-specific CLI invocation (`build_convert_command` — a pure, unit-tested string-builder that maps `width`/`height`/`target_path`/`bg_color` to Inkscape's `--export-*` flags or rsvg-convert's `--width`/`--height`/`--output`/`--background-color` flags) and shells out via `generate_image` to rasterize the source SVG at the requested size, skipping files that already exist.
  5. Icon spec entries can be a plain array of `{filename, width, height}` (simple case) or a hash with `"config"` (extra per-group settings like `exportBgColor`, `adaptive`, `splash`) and `"icons"` (the array). Entries under known type keys (`launcher`, `universal`, `universal-legacy`, `universal-notifications`, `apple-watch`) are collected as app icons; `splash-screen` entries are collected as splash icons.
  6. Once all icons for all groups are generated, delegates to `Helper::ImageGenHelper.cordova_insert_android_icons` / `cordova_insert_ios_icons` to rewrite the Cordova `./config.xml` in the current working directory with `<icon>` (and, for Android, splash-screen `<preference>`) elements. `:web` platform is a documented no-op (TODO: favicons in index.html).

- **`Helper::ImageGenHelper`** (`helper/image_gen_helper.rb`) — all filesystem and XML manipulation:
  - Path safety: `base_dir`/`relativize_to_basedir`/`is_in_basedir?` compute paths relative to the current working directory and are used to keep generated paths (and destructive operations) confined under it.
  - `remove_dir` refuses to delete anything outside the base dir (see `CleanAssetsAction`).
  - Cordova `config.xml` is read/written with Nokogiri using the W3C widgets XML namespace. Existing `<icon>` nodes (and Android splash `<preference>` nodes) are replaced wholesale if present, otherwise new nodes are appended to the platform's `<platform name="...">` section.
  - Android icon nodes differentiate adaptive icons (`foreground`/`monochrome`/`background` attrs, with a hardcoded `@color/ic_gopay_icon_background`) vs. simple icons (`src` attr); density is inferred from the icon's parent directory name.

- **`CleanAssetsAction`** — deletes a dist/output directory (default `assets/dist`), guarded by `is_in_basedir?`.

- **`TestWorkdirAction`** — debug-only action that prints cwd/OS info; not part of the plugin's real functionality.

### Icon spec JSON format

See `test/src/logo-gen.json` for a minimal example. Top-level keys are icon "type" names; values are either an array of `{filename, width, height}` objects, or `{"config": {...}, "icons": [...]}` where `config` may include `exportBgColor`, `adaptive`, `splash`, `bgColor`, `iconBgColor` depending on platform/type.

## Notes for changes

- Ruby version is pinned via `.ruby-version` (3.4.2), matching the gemspec's declared minimum (`>= 3.4`), rubocop's `TargetRubyVersion` (3.4), and CI (`.github/workflows/test.yml`, `.circleci/config.yml`, `.travis.yml` all run 3.4). `rubocop` is pinned to `1.62.1` in the `Gemfile` — the first release that recognizes `TargetRubyVersion: 3.4` (marked experimental as of that release); older `rubocop` versions raise `Error: RuboCop found unknown Ruby version 3.4`.
- Do not add a runtime dependency on `fastlane`/`fastlane_re` in the gemspec — this plugin is loaded *by* fastlane, so that would be a circular dependency (see comment in `fastlane-plugin-image_gen.gemspec`).
- Rubocop config (`.rubocop.yml`) disables many default style cops; run `rubocop` (not just `rspec`) before considering a change done, since `rake` (CI) enforces both.
- This plugin follows [Semantic Versioning](https://semver.org/). The version lives in `lib/fastlane/plugin/image_gen/version.rb` (`Fastlane::ImageGen::VERSION`). Every change that will be published (i.e. not purely internal to this repo, like CI config or dev tooling) must bump this version: patch for backwards-compatible bug fixes, minor for backwards-compatible new functionality (e.g. a new action param or option), major for breaking changes (removed/renamed params, changed default behavior).
