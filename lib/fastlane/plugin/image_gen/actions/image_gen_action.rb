require 'fileutils'
require 'json'
require 'fastlane/action'
require_relative '../helper/image_gen_helper'

module Fastlane
  module Actions
    class ImageGenAction < Action
      def self.run(params)
        UI.message("-== image_gen - Generate images for your app ==-")

        inkscape_cmd = get_inkscape_cmd(params)
        icon_spec = load_json(params)
        source_image = locate_source_image(params)
        target_dir = ensure_target_dir(params)

        generate_icons(inkscape_cmd, icon_spec, source_image, target_dir)
      end

      def self.platform_name
        return Actions.lane_context[SharedValues::PLATFORM_NAME]
      end

      def self.get_inkscape_cmd(params)
        return params[:inkscape_cmd]
      end

      def self.load_json(params)
        spec_file = File.expand_path(params[:spec_file])
        UI.message("Loading JSON icon spec file: #{spec_file}")

        if File.exist?(spec_file)
          json = File.read(spec_file)
          icon_spec = JSON.parse(json)
          return icon_spec
        else
          UI.user_error!('Icon spec file not found.')
        end
      end

      def self.locate_source_image(params)
        source_image = File.expand_path(params[:source_image])
        UI.message("Locating source image: #{source_image}")

        if File.exist?(source_image)
          return source_image
        else
          UI.user_error!("Source SVG image not found.")
        end
      end

      def self.ensure_target_dir(params)
        target_dir = File.expand_path(params[:target_dir])
        UI.message("Ensuring target folders: #{target_dir}")
        Helper::ImageGenHelper.ensure_dirs(target_dir)
        return target_dir
      end

      def self.generate_icons(inkscape_cmd, icon_spec, source_image, target_dir)
        platform = platform_name
        icon_paths = []
        icon_config = { adaptive: false }

        icon_spec.each do |type, type_options|
          UI.message("Generating icons for: #{type} [hash: #{type_options.kind_of?(Hash)}, array: #{type_options.kind_of?(Array)}]")
          if type_options.kind_of?(Hash)
            icon_config = type_options[:config]
            icons = type_options[:icons]
          else
            icons = type_options
          end

          icons.each do |icon|
            filename = icon[:filename]
            width = icon[:width]
            height = icon[:height]

            target_path = File.expand_path(filename, target_dir)
            Helper::ImageGenHelper.ensure_dirs(target_path)

            relative_path = Helper::ImageGenHelper.relativize_to_basedir(target_path)
            icon_paths << relative_path if type != "play-store"

            generate_image(inkscape_cmd, source_image, target_path, width, height) unless File.exist?(target_path)
          end
        end

        case platform
        when :android
          Helper::ImageGenHelper.cordova_insert_android_icons(icon_paths, icon_config)
        when :ios
        else
          UI.user_error!("Unknown platform: #{platform}")
        end
      end

      def self.generate_image(inkscape_cmd, source_image, target_path, width, height)
        FastlaneCore::CommandExecutor.execute(command: "#{inkscape_cmd} #{source_image} --export-width \"#{width}\" --export-height \"#{height}\" --export-filename \"#{target_path}\"",
                                              print_all: true,
                                              print_command: true)
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
          FastlaneCore::ConfigItem.new(key: :spec_file,
                                       env_name: "FL_IMAGE_GEN_SPEC_FILE",
                                       description: "Location of the JSON file for generating icons"),
          FastlaneCore::ConfigItem.new(key: :source_image,
                                       env_name: "FL_IMAGE_GEN_SOURCE_IMAGE",
                                       description: "Path to the source SVG image used for generating icons"),
          FastlaneCore::ConfigItem.new(key: :target_dir,
                                       env_name: "FL_IMAGE_GEN_TARGET_DIR",
                                       description: "Location of the output folder to put generated icons"),
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
