require 'date'

private_lane :smf_android_monitor_unit_tests do |options|

  test_count = 0

  # Change directory to search for test result files
  Dir.chdir(smf_workspace_dir) do
    test_results = Dir.glob('**/build/test-results/**/TEST-*.xml')
    if test_results.empty?
      UI.message("No test result files found in #{smf_workspace_dir}")
    end
    test_results.each do |test_result|
      File.open(test_result,"r") do |file|
        text = file.read
        if test_result_match = text.match("tests=\"([0-9]+)\"")
          test_count += test_result_match.captures[0].to_i
        end
      end
    end
  end

  # Display unit test results in build log instead of external reporting
  UI.header("📊 Android Unit Test Analysis")
  UI.message("📱 Project: #{options[:project_name] || 'Unknown'}")
  UI.message("🌿 Branch: #{options[:branch] || 'Unknown'}")
  UI.message("🔧 Platform: #{options[:platform] || 'Android'}")
  UI.message("📦 Build Variant: #{options[:build_variant] || 'Unknown'}")
  
  if test_count > 0
    UI.success("✅ Unit Tests: #{test_count} tests executed")
  else
    UI.important("⚠️  Unit Tests: No tests found or executed")
  end
end
