#!/usr/bin/ruby

def smf_send_meta_report(project_data, type)
  UI.header("📊 Project Meta Analysis Report")
  
  # Basic project info
  UI.message("📱 Project: #{project_data[:repo] || 'Unknown'}")
  UI.message("🌿 Branch: #{project_data[:branch] || 'Unknown'}")
  UI.message("📅 Date: #{project_data[:date] || Date.today}")
  UI.message("🔧 Platform: #{project_data[:platform] || 'Unknown'}")
  
  case type
  when :APPLE_META_REPORTING
    _display_ios_meta_report(project_data)
  when :ANDROID_META_REPORTING
    _display_android_meta_report(project_data)
  else
    UI.message("ℹ️  Unknown report type: #{type}")
  end
  
  UI.success("✅ Meta analysis complete")
end

def _display_ios_meta_report(data)
  UI.message("\n🍎 iOS/macOS Project Analysis:")
  
  # Development environment
  UI.message("• Xcode Version: #{data[:xcode_version] || 'Not specified'}")
  UI.message("• Swift Version: #{data[:swift_version] || 'Not detected'}")
  UI.message("• Deployment Target: #{data[:deployment_target] || 'Not detected'}")
  UI.message("• Build Number: #{data[:build_number] || 'Not detected'}")
  
  # Code quality
  if data[:swiftlint_warnings]
    if data[:swiftlint_warnings].to_i > 0
      UI.important("⚠️  SwiftLint Warnings: #{data[:swiftlint_warnings]}")
    else
      UI.message("✅ SwiftLint Warnings: 0")
    end
  end
  
  # Security & compliance
  UI.message("\n🔒 Security & Compliance:")
  idfa_status = data[:idfa] || 'unknown'
  case idfa_status
  when 'disabled'
    UI.message("✅ IDFA Usage: Not detected")
  when 'custom'
    UI.important("⚠️  IDFA Usage: Custom implementation found")
  else
    UI.message("ℹ️  IDFA Usage: #{idfa_status}")
  end
  
  ats_status = data[:ats] || 'unknown'
  if ats_status == 'disabled' || ats_status.nil?
    UI.message("✅ ATS Exceptions: None detected")
  else
    UI.important("⚠️  ATS Exceptions: #{ats_status}")
  end
  
  # Build configuration
  UI.message("\n⚙️  Build Configuration:")
  bitcode_status = data[:bitcode] || 'unknown'
  UI.message("• Bitcode: #{bitcode_status}")
  
  # Dependencies
  UI.message("\n📦 Dependencies:")
  sentry_version = data[:sentry]
  if sentry_version
    UI.message("• Sentry: #{sentry_version}")
  end
  
  qakit_version = data[:qakit]
  if qakit_version
    UI.message("• QAKit: #{qakit_version}")
  end
  
  debug_menu_version = data[:debug_menu]
  if debug_menu_version
    UI.message("• SMF Debug Menu: #{debug_menu_version}")
  end
  
  if !sentry_version && !qakit_version && !debug_menu_version
    UI.message("• No tracked development dependencies found")
  end
end

def _display_android_meta_report(data)
  UI.message("\n🤖 Android Project Analysis:")
  
  # Development environment
  UI.message("• Kotlin Version: #{data[:kotlin_version] || 'Not detected'}")
  UI.message("• Gradle Version: #{data[:gradle_version] || 'Not detected'}")
  
  # SDK versions
  UI.message("\n📱 SDK Configuration:")
  UI.message("• Target SDK: #{data[:target_sdk_version] || 'Not specified'}")
  UI.message("• Minimum SDK: #{data[:min_sdk_version] || 'Not specified'}")
  
  # Check for potential issues
  min_sdk = data[:min_sdk_version].to_i
  target_sdk = data[:target_sdk_version].to_i
  
  if min_sdk > 0 && min_sdk < 21
    UI.important("⚠️  Minimum SDK #{min_sdk} is quite low - consider updating for better security")
  end
  
  if target_sdk > 0 && target_sdk < 33
    UI.important("⚠️  Target SDK #{target_sdk} - consider updating to latest for Play Store requirements")
  end
end
