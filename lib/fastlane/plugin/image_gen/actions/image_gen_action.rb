require 'fileutils'
require 'json'
require 'fastlane/action'
require_relative '../helper/image_gen_helper'

module Fastlane
  module Actions
    class ImageGenAction < Action
      def self.run(params)
        UI.message("-== image_gen - Generate images for your app ==-")

        platform = platform_name(params)
        converter = params[:converter_tool]
        converter_cmd = get_converter_cmd(params)
        icon_spec = load_json(params)
        source_image = locate_source_image(params)
        target_dir = ensure_target_dir(params)

        generate_icons(platform, converter, converter_cmd, icon_spec, source_image, target_dir)
      end

      def self.platform_name(params)
        platform = (params[:platform_name] || "").to_sym

        if platform.nil? || platform.empty?
          return Actions.lane_context[SharedValues::PLATFORM_NAME]
        end

        return platform
      end

      def self.get_converter_cmd(params)
        rsvg = params[:converter_tool].eql?("rsvg-convert")

        case FastlaneCore::Helper.operating_system.downcase
        when "macos"
          return rsvg ? params[:rsvg_cmd_macos] : params[:inkscape_cmd_macos]
        when "linux"
          return rsvg ? params[:rsvg_cmd_linux] : params[:inkscape_cmd_linux]
        else
          UI.user_error!("Operating system not supported: #{FastlaneCore::Helper.operating_system}")
        end
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

      APP_ICON_TYPES = ["launcher", "universal", "universal-legacy", "universal-notifications", "apple-watch"].freeze
      SPLASH_ICON_TYPES = ["splash-screen"].freeze

      def self.generate_icons(platform, converter, converter_cmd, icon_spec, source_image, target_dir)
        icons_to_insert = []
        splash_to_insert = []

        icon_spec.each do |type, type_options|
          UI.message("Generating icons for: #{type} [hash: #{type_options.kind_of?(Hash)}, array: #{type_options.kind_of?(Array)}]")
          icon_config, icons, export_bg_color = icon_group_config(type_options)

          icon_configs = icons.map do |icon|
            generate_icon(converter, converter_cmd, source_image, target_dir, icon_config, export_bg_color, icon)
          end

          icons_to_insert += icon_configs if APP_ICON_TYPES.include?(type)
          splash_to_insert += icon_configs if SPLASH_ICON_TYPES.include?(type)
        end

        insert_generated_icons(platform, icons_to_insert, splash_to_insert)
      end

      def self.icon_group_config(type_options)
        unless type_options.kind_of?(Hash)
          return [{ adaptive: false, splash: false }, type_options, ""]
        end

        icon_config = type_options["config"].transform_keys(&:to_sym)
        export_bg_color = icon_config[:exportBgColor] || ""
        icon_config.delete(:exportBgColor)
        UI.message("Export bg color: #{export_bg_color}")

        [icon_config, type_options["icons"], export_bg_color]
      end

      def self.generate_icon(converter, converter_cmd, source_image, target_dir, icon_config, export_bg_color, icon)
        filename = icon["filename"]
        width = icon["width"]
        height = icon["height"]

        target_path = File.expand_path(filename, target_dir)
        Helper::ImageGenHelper.ensure_dirs(target_path)

        relative_path = Helper::ImageGenHelper.relativize_to_basedir(target_path)

        generate_image(converter, converter_cmd, source_image, target_path, width, height, export_bg_color) unless File.exist?(target_path)

        icon_config.merge({ path: relative_path, width:, height: })
      end

      def self.insert_generated_icons(platform, icons_to_insert, splash_to_insert)
        case platform
        when :android
          Helper::ImageGenHelper.cordova_insert_android_icons(icons_to_insert, splash_to_insert)
        when :ios
          Helper::ImageGenHelper.cordova_insert_ios_icons(icons_to_insert)
        when :web
          # TODO: Insert favicons in index.html
        else
          UI.user_error!("Platform not supported: #{platform}")
        end
      end

      def self.build_convert_command(converter, converter_cmd, source_image, target_path, width, height, bg_color)
        case converter
        when "inkscape"
          cmd = "#{converter_cmd} #{source_image} --export-width=\"#{width}\" --export-height=\"#{height}\" --export-filename=\"#{target_path}\""
          cmd += " --export-background=\"#{bg_color}\"" unless bg_color.eql?("")
        when "rsvg-convert"
          cmd = "#{converter_cmd} #{source_image} --width=\"#{width}\" --height=\"#{height}\" --output=\"#{target_path}\""
          cmd += " --background-color=\"#{bg_color}\"" unless bg_color.eql?("")
        else
          UI.user_error!("Unsupported converter tool: #{converter}")
        end

        cmd
      end

      def self.generate_image(converter, converter_cmd, source_image, target_path, width, height, bg_color)
        cmd = build_convert_command(converter, converter_cmd, source_image, target_path, width, height, bg_color)

        FastlaneCore::CommandExecutor.execute(command: cmd,
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
          FastlaneCore::ConfigItem.new(key: :platform_name,
                                       env_name: "FL_IMAGE_GEN_PLATFORM",
                                       description: "Platform override",
                                       default_value: ""),
          FastlaneCore::ConfigItem.new(key: :spec_file,
                                       env_name: "FL_IMAGE_GEN_SPEC_FILE",
                                       description: "Location of the JSON file for generating icons"),
          FastlaneCore::ConfigItem.new(key: :source_image,
                                       env_name: "FL_IMAGE_GEN_SOURCE_IMAGE",
                                       description: "Path to the source SVG image used for generating icons"),
          FastlaneCore::ConfigItem.new(key: :target_dir,
                                       env_name: "FL_IMAGE_GEN_TARGET_DIR",
                                       description: "Location of the output folder to put generated icons"),
          FastlaneCore::ConfigItem.new(key: :converter_tool,
                                       env_name: "FL_IMAGE_GEN_CONVERTER_TOOL",
                                       description: "SVG to raster converter tool to use, either 'inkscape' or 'rsvg-convert'",
                                       default_value: "inkscape",
                                       verify_block: proc do |value|
                                         unless ["inkscape", "rsvg-convert"].include?(value)
                                           UI.user_error!("Unsupported converter_tool '#{value}', must be one of: inkscape, rsvg-convert")
                                         end
                                       end),
          FastlaneCore::ConfigItem.new(key: :inkscape_cmd_linux,
                                       env_name: "FL_IMAGE_GEN_INKSCAPE_CMD_LINUX",
                                       description: "Command to run Inkscape on Linux",
                                       default_value: "inkscape"),
          FastlaneCore::ConfigItem.new(key: :inkscape_cmd_macos,
                                       env_name: "FL_IMAGE_GEN_INKSCAPE_CMD_MACOS",
                                       description: "Command to run Inkscape on macOS",
                                       default_value: "/Applications/Inkscape.app/Contents/MacOS/inkscape"),
          FastlaneCore::ConfigItem.new(key: :rsvg_cmd_linux,
                                       env_name: "FL_IMAGE_GEN_RSVG_CMD_LINUX",
                                       description: "Command to run rsvg-convert on Linux",
                                       default_value: "rsvg-convert"),
          FastlaneCore::ConfigItem.new(key: :rsvg_cmd_macos,
                                       env_name: "FL_IMAGE_GEN_RSVG_CMD_MACOS",
                                       description: "Command to run rsvg-convert on macOS",
                                       default_value: "rsvg-convert")
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
