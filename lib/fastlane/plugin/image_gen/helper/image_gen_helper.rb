require 'fastlane_core/ui/ui'
require 'pathname'
require 'nokogiri'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class ImageGenHelper
      # class methods that you define here become available in your action
      # as `Helper::ImageGenHelper.your_method`
      #
      def self.base_dir
        return File.realpath(Dir.getwd)
      end

      def self.relativize_to_basedir(path)
        abs_path = Pathname.new(path).expand_path.realdirpath
        base_path_str = base_dir

        return abs_path.relative_path_from(base_path_str)
      end

      def self.is_in_basedir?(path)
        relative_path = relativize_to_basedir(path)
        return false if relative_path.to_s.start_with?("..")

        return true
      end

      def self.ensure_dirs(path)
        directory = path
        directory = File.dirname(path) unless File.directory?(path)

        if File.exist?(directory) then return directory end

        UI.message("Ensuring folders exist: #{directory}")

        FastlaneCore::CommandExecutor.execute(command: "mkdir -p #{directory}",
                                              print_all: true,
                                              print_command: true)
      end

      def self.remove_dir(path)
        UI.user_error!("Refusing to touch dir outside base dir") unless is_in_basedir?(path)
        UI.user_error!("Not a directory") unless File.directory?(path)

        FastlaneCore::CommandExecutor.execute(command: "rm -rf #{path}",
                                              print_all: true,
                                              print_command: true)
      end

      def self.load_xml_file(path)
        UI.message("Load XML file from: #{path}")

        UI.user_error!("File not found: #{path}") unless File.exist?(path)

        xml = File.read(path)
        doc = Nokogiri::XML(xml)

        return doc
      end

      def self.write_xml_file(path, xml_doc)
        UI.message("Save XML to file: #{path}")

        File.write(path, xml_doc.to_xml)
      end

      def self.find_android_section(xml_doc)
        return xml_doc.xpath("/w:widget/w:platform[@name='android']", { "w" => "http://www.w3.org/ns/widgets" })
                      .first
      end

      def self.find_android_icons(xml_doc)
        return xml_doc.xpath("/w:widget/w:platform[@name='android']/w:icon", { "w" => "http://www.w3.org/ns/widgets" })
      end

      def self.find_android_splash_prefs(xml_doc)
        return xml_doc.xpath("/w:widget/w:platform[@name='android']/w:preference[@name='AndroidWindowSplashScreenAnimatedIcon' or @name='AndroidWindowSplashScreenIconBackgroundColor' or @name='AndroidWindowSplashScreenBackground']", { "w" => "http://www.w3.org/ns/widgets" })
      end

      def self.find_android_colors_xml(xml_doc)
        return xml_doc.xpath("/w:widget/w:platform[@name='android']/w:resource-file[@target~'colors.xml']", { w: "http://www.w3.org/ns/widgets" })
      end

      def self.create_android_icon_node(xml_doc, icon_path, icon_config)
        density = Pathname.new(icon_path).parent.basename
        if icon_config[:adaptive]
          xml_doc.create_element('icon', { "density" => density, "foreground" => icon_path, "monochrome" => icon_path, "background" => "@color/ic_gopay_icon_background" })
        else
          xml_doc.create_element('icon', { "density" => density, "src" => icon_path })
        end
      end

      def self.create_android_splash_pref_nodes(xml_doc, icon_path, icon_config)
        prefs = []
        prefs << xml_doc.create_element("preference", { "name" => "AndroidWindowSplashScreenAnimatedIcon", "value" => icon_path })
        prefs << xml_doc.create_element("preference", { "name" => "AndroidWindowSplashScreenBackground", "value" => icon_config[:bgColor] })

        if icon_config[:iconBgColor]
          prefs << xml_doc.create_element("preference", { "name" => "AndroidWindowSplashScreenIconBackgroundColor", "value" => icon_config[:iconBgColor] })
        end

        return prefs
      end

      def self.append_nodes(android_section, new_nodes)
        new_nodes.each do |node|
          android_section.add_child(node)
        end
      end

      def self.replace_nodes(old_nodes, new_nodes)
        first_old = old_nodes[0]

        new_nodes.each do |node|
          first_old.add_previous_sibling(node)
        end

        old_nodes.unlink
      end

      def self.cordova_insert_android_icons(icon_paths, icon_config)
        xml_doc = load_xml_file("./config.xml")
        android_section = find_android_section(xml_doc)
        old_icon_nodes = find_android_icons(xml_doc)
        old_pref_nodes = find_android_splash_prefs(xml_doc)

        if icon_config[:splash]
          new_pref_nodes = create_android_splash_pref_nodes(xml_doc, icon_paths.first, icon_config)

          if old_pref_nodes.nil? || old_pref_nodes.empty?
            append_nodes(android_section, new_pref_nodes)
          else
            replace_nodes(old_pref_nodes, new_pref_nodes)
          end
        else
          new_icon_nodes = icon_paths.map { |path| create_android_icon_node(xml_doc, path, icon_config) }

          if old_icon_nodes.nil? || old_icon_nodes.empty?
            append_nodes(android_section, new_icon_nodes)
          else
            replace_nodes(old_icon_nodes, new_icon_nodes)
          end
        end

        write_xml_file("./config.xml", xml_doc)
      end
    end
  end
end
