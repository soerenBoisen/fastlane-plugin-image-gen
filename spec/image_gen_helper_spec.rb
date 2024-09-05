require 'pathname'
require 'fileutils'

describe Fastlane::Helper::ImageGenHelper do
  describe '#load_xml_file' do
    it 'loads an XML file' do
      test_xml_file = File.expand_path("./spec/test.xml")
      xml_doc = Fastlane::Helper::ImageGenHelper.load_xml_file(test_xml_file)
      puts xml_doc.to_xml
    end
  end

  describe '#find_android_icons' do
    it 'finds android icons' do
      test_xml_file = File.expand_path("./spec/test_config.xml")
      xml_doc = Fastlane::Helper::ImageGenHelper.load_xml_file(test_xml_file)
      icon_nodes = Fastlane::Helper::ImageGenHelper.find_android_icons(xml_doc)
      puts "Found nodes: #{icon_nodes}"
    end
  end

  describe '#is_in_basedir?' do
    it 'returns true for path inside base dir' do
      actual = Fastlane::Helper::ImageGenHelper.is_in_basedir?("lib/fastlane")
      expect(actual).to be true
    end
    it 'returns false for path outside base dir' do
      actual = Fastlane::Helper::ImageGenHelper.is_in_basedir?("~/.ssh")
      expect(actual).to be false
    end
    it 'returns false for path using .. to exit base dir' do
      actual = Fastlane::Helper::ImageGenHelper.is_in_basedir?("../../.ssh")
      expect(actual).to be false
    end
  end

  describe '#remove_dir' do
    it 'errors for a path outside base dir' do
      Dir.chdir("..") do
        Dir.mkdir("_test_remove_dir") unless File.exist?("_test_remove_dir")
      end
      expect { Fastlane::Helper::ImageGenHelper.remove_dir("../_test_remove_dir") }.to raise_error(/Refusing/)
    end
    it 'removes empty directory' do
      Dir.mkdir("_test_remove_dir") unless File.exist?("_test_remove_dir")
      Fastlane::Helper::ImageGenHelper.remove_dir("_test_remove_dir")
      expect(File.exist?("_test_remove_dir")).to be false
    end
    it 'removes directory with files and subdirs inside' do
      FileUtils.mkdir_p("_test_remove_dir/a/b/c")
      FileUtils.touch("_test_remove_dir/a/b/c/myfile")
      Fastlane::Helper::ImageGenHelper.remove_dir("_test_remove_dir")
      expect(File.exist?("_test_remove_dir")).to be false
    end
  end

  describe '#replace_nodes' do
    it 'replaces nodes with given nodes' do
      test_xml_file = File.expand_path("./spec/test_config.xml")
      xml_doc = Fastlane::Helper::ImageGenHelper.load_xml_file(test_xml_file)
      icon_nodes = Fastlane::Helper::ImageGenHelper.find_android_icons(xml_doc)

      new_nodes = []
      new_nodes.unshift(xml_doc.create_element('icon', { "src" => "https://example.com/1" }))
      new_nodes.unshift(xml_doc.create_element('icon', { "src" => "https://example.com/2" }))

      Fastlane::Helper::ImageGenHelper.replace_nodes(icon_nodes, new_nodes)

      puts "Result XML:"
      puts xml_doc.to_xml
    end
  end

  describe 'Hmm' do
    it 'does something magixal' do
      test_path_str = File.expand_path("../image_gen/actions/image_gen_action.rb")
      base_path_str = File.expand_path("../image_gen")

      test_path = Pathname.new(test_path_str)
      result_path = test_path.relative_path_from(base_path_str)
      puts result_path
    end
  end
end
