require 'date'

private_lane :smf_ios_monitor_unit_tests do |options|

  project_name = @smf_fastlane_config.dig(:project, :project_name)
  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config
  branch = !options[:branch_name].nil? ? options[:branch_name] : smf_workspace_dir_git_branch
  platform = smf_meta_report_platform_friendly_name

  sheet_entries = []

  xcresult_dir = File.join(smf_workspace_dir, $XCRESULT_DIR)

  unless Dir.exist?(xcresult_dir)
    UI.messsage("The test result dir: #{xcresult_dir}, does not exist")
    raise 'Missing test result directory'
  end

  xcresult_file_names = Dir.entries(xcresult_dir).select do |file|
    file.to_s.end_with?('.xcresult')
  end

  if xcresult_file_names.empty?
    UI.message("No .xcresult files found in #{xcresult_dir}")
    next
  end

  # Only use one test coverage report
  filename = xcresult_file_names.first
  json_result_string = `xcrun xccov view --report --json #{File.join(xcresult_dir, filename)}`
  result_parsed = JSON.parse(json_result_string)

  # Gather unit-tests count
  json_result_string = `xcrun xcresulttool get --path #{File.join(xcresult_dir, filename)} --format json`
  tests_results = JSON.parse(json_result_string)
  tests_count = tests_results.dig('metrics', 'testsCount', '_value')

  # set test_count to 0 if is is nil
  tests_count ||= 0

  entry_data = {
    :project_name => project_name,
    :branch => branch,
    :platform => platform.to_s,
    :build_variant => build_variant.to_s,
    :test_coverage => result_parsed.dig('lineCoverage'),
    :covered_lines => result_parsed.dig('coveredLines'),
    :unit_test_count => tests_count
  }

  # Display unit test results in build log instead of external reporting
  UI.header("📊 iOS Unit Test Analysis")
  UI.message("📱 Project: #{project_name}")
  UI.message("🌿 Branch: #{branch}")
  UI.message("🔧 Platform: #{platform}")
  UI.message("📦 Build Variant: #{build_variant}")
  
  if entry_data[:unit_test_count] && entry_data[:unit_test_count] > 0
    UI.success("✅ Unit Tests: #{entry_data[:unit_test_count]} tests executed")
  else
    UI.important("⚠️  Unit Tests: No tests found or executed")
  end
  
  if entry_data[:test_coverage]
    coverage_percent = (entry_data[:test_coverage] * 100).round(1)
    if coverage_percent >= 80
      UI.success("✅ Test Coverage: #{coverage_percent}% (#{entry_data[:covered_lines]} lines)")
    elsif coverage_percent >= 60
      UI.important("⚠️  Test Coverage: #{coverage_percent}% (#{entry_data[:covered_lines]} lines) - Consider improving")
    else
      UI.error("❌ Test Coverage: #{coverage_percent}% (#{entry_data[:covered_lines]} lines) - Low coverage detected")
    end
  else
    UI.message("ℹ️  Test Coverage: Not available")
  end
end
