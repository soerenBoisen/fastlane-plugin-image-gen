describe Fastlane::Actions::ImageGenAction do
  describe '#platform_name' do
    it 'gets the platform' do
      platform = Fastlane::Actions::ImageGenAction.platform_name({})
      puts "Found platform: '#{platform}'"
    end
  end

  describe '#build_convert_command' do
    it 'builds an inkscape command without a background color' do
      cmd = Fastlane::Actions::ImageGenAction.build_convert_command("inkscape", "inkscape", "logo.svg", "out.png", 32, 32, "")
      expect(cmd).to eq('inkscape logo.svg --export-width="32" --export-height="32" --export-filename="out.png"')
    end

    it 'builds an inkscape command with a background color' do
      cmd = Fastlane::Actions::ImageGenAction.build_convert_command("inkscape", "inkscape", "logo.svg", "out.png", 32, 32, "#ffffff")
      expect(cmd).to eq('inkscape logo.svg --export-width="32" --export-height="32" --export-filename="out.png" --export-background="#ffffff"')
    end

    it 'builds an rsvg-convert command without a background color' do
      cmd = Fastlane::Actions::ImageGenAction.build_convert_command("rsvg-convert", "rsvg-convert", "logo.svg", "out.png", 32, 32, "")
      expect(cmd).to eq('rsvg-convert logo.svg --width="32" --height="32" --output="out.png"')
    end

    it 'builds an rsvg-convert command with a background color' do
      cmd = Fastlane::Actions::ImageGenAction.build_convert_command("rsvg-convert", "rsvg-convert", "logo.svg", "out.png", 32, 32, "#ffffff")
      expect(cmd).to eq('rsvg-convert logo.svg --width="32" --height="32" --output="out.png" --background-color="#ffffff"')
    end

    it 'raises for an unsupported converter' do
      expect do
        Fastlane::Actions::ImageGenAction.build_convert_command("potrace", "potrace", "logo.svg", "out.png", 32, 32, "")
      end.to raise_error(FastlaneCore::Interface::FastlaneError)
    end
  end

  describe '#get_converter_cmd' do
    let(:params) do
      {
        converter_tool: "inkscape",
        inkscape_cmd_linux: "inkscape",
        inkscape_cmd_macos: "/Applications/Inkscape.app/Contents/MacOS/inkscape",
        rsvg_cmd_linux: "rsvg-convert",
        rsvg_cmd_macos: "rsvg-convert"
      }
    end

    it 'returns the inkscape command on macOS' do
      allow(FastlaneCore::Helper).to receive(:operating_system).and_return("macOS")
      cmd = Fastlane::Actions::ImageGenAction.get_converter_cmd(params)
      expect(cmd).to eq(params[:inkscape_cmd_macos])
    end

    it 'returns the inkscape command on Linux' do
      allow(FastlaneCore::Helper).to receive(:operating_system).and_return("Linux")
      cmd = Fastlane::Actions::ImageGenAction.get_converter_cmd(params)
      expect(cmd).to eq(params[:inkscape_cmd_linux])
    end

    it 'returns the rsvg-convert command on macOS' do
      allow(FastlaneCore::Helper).to receive(:operating_system).and_return("macOS")
      cmd = Fastlane::Actions::ImageGenAction.get_converter_cmd(params.merge(converter_tool: "rsvg-convert"))
      expect(cmd).to eq(params[:rsvg_cmd_macos])
    end

    it 'returns the rsvg-convert command on Linux' do
      allow(FastlaneCore::Helper).to receive(:operating_system).and_return("Linux")
      cmd = Fastlane::Actions::ImageGenAction.get_converter_cmd(params.merge(converter_tool: "rsvg-convert"))
      expect(cmd).to eq(params[:rsvg_cmd_linux])
    end

    it 'raises for an unsupported operating system' do
      allow(FastlaneCore::Helper).to receive(:operating_system).and_return("windows")
      expect do
        Fastlane::Actions::ImageGenAction.get_converter_cmd(params)
      end.to raise_error(FastlaneCore::Interface::FastlaneError)
    end
  end

  describe ':converter_tool config item' do
    let(:converter_tool_item) do
      Fastlane::Actions::ImageGenAction.available_options.find { |option| option.key == :converter_tool }
    end

    it 'accepts inkscape and rsvg-convert' do
      expect { converter_tool_item.verify!("inkscape") }.not_to raise_error
      expect { converter_tool_item.verify!("rsvg-convert") }.not_to raise_error
    end

    it 'rejects unsupported values' do
      expect { converter_tool_item.verify!("potrace") }.to raise_error(FastlaneCore::Interface::FastlaneError)
    end
  end
end
