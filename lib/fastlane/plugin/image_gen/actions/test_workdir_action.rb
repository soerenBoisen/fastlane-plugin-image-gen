require 'fileutils'
require 'json'
require 'fastlane/action'
require_relative '../helper/image_gen_helper'

module Fastlane
  module Actions
    class TestWorkdirAction < Action
      def self.run(params)
        UI.message("Current work dir: #{Dir.getwd}")
      end

      def self.description
        "Generate images for iOS and Android from a master SVG"
      end

      def self.authors
        ["Søren Boisen"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        ""
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :inkscape_cmd,
                                       env_name: "FL_IMAGE_GEN_INKSCAPE_CMD",
                                       description: "Command to run Inkscape",
                                       default_value: "inkscape")
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
