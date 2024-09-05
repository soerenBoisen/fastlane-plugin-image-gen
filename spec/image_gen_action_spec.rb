describe Fastlane::Actions::ImageGenAction do
  describe '#platform_name' do
    it 'gets the platform' do
      platform = Fastlane::Actions::ImageGenAction.platform_name
      puts "Found platform: '#{platform}'"
    end
  end
end
