# image_gen plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-image_gen)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-image_gen`, add it to your project by running:

```bash
fastlane add_plugin image_gen
```

## About image_gen

Generate images for iOS and Android from a master SVG

**Note to author:** Add a more detailed description about this plugin here. If your plugin contains multiple actions, make sure to mention them here.

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

**Note to author:** Please set up a sample project to make it easy for users to explore what your plugin does. Provide everything that is necessary to try out the plugin in this project (including a sample Xcode/Android project if necessary)

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Publishing a new release

This fork is not published to RubyGems. It's distributed via this GitHub repo, so consuming projects reference it directly in their `Gemfile`, e.g.:

```ruby
gem 'fastlane-plugin-image_gen', git: 'https://github.com/soerenBoisen/fastlane-plugin-image-gen.git', tag: 'v1.1.0'
```

To publish a new release:

1. Bump `VERSION` in `lib/fastlane/plugin/image_gen/version.rb` (this should already be done as part of the fix/feature commit — see the versioning convention below).
2. Run `rake` to make sure tests and rubocop pass.
3. Commit and push to `main`.
4. Tag the release and push the tag:
   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```
5. In any consuming project that pins a `tag:`, bump it to the new tag and run `bundle update fastlane-plugin-image_gen`. Projects pinned to a `branch:` instead of a `tag:` pick up the change on their next `bundle install`/`bundle update` automatically.

This repo follows [semantic versioning](https://semver.org): bump the patch version for fixes, minor for backwards-compatible features, and major for breaking changes.

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).

# Credits
Example icon made from [svg icons](https://www.onlinewebfonts.com/icon) is licensed by CC BY 4.0
