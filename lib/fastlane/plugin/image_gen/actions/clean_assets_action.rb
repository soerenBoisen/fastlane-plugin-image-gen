require 'fastlane/action'
require_relative '../helper/image_gen_helper'

module Fastlane
  module Actions
    class CleanAssetsAction < Action
      def self.run(params)
        asset_dist_dir = params[:asset_dist_dir]
        UI.message("Clean assets dist dir: #{asset_dist_dir}")
        if File.exist?(asset_dist_dir)
          Helper::ImageGenHelper.remove_dir(asset_dist_dir)
        else
          UI.message("Directory not found, nothing to do")
        end
      end

      def self.description
        "Clean assets for iOS and Android"
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
          FastlaneCore::ConfigItem.new(key: :asset_dist_dir,
                                       env_name: "FL_ASSET_DIST_DIR",
                                       description: "Relative path to the directory for generated assets",
                                       default_value: "assets/dist")
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
