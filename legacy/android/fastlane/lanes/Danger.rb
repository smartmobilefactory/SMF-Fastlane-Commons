###########################
### smf_danger_build_pr ###
###########################
# options: 
#   gradle_build_task (String, optional)
#   gradle_lint_task (String, optional)
#   jira_key (String, optional)
#   module_basepath (String, optional; needed for reports folder; defaults to "app")
#   run_ktlint (Boolean, optional; defaults to true)
#   run_detekt (Boolean, optional; defaults to true)
#   junit_task (String, optional)
###########################

fastlane_require 'fileutils'
fastlane_require 'json'

desc "Run checks, build project and report with Danger"
private_lane :smf_danger_build_pr do |options|

  UI.important("Danger PR Report")
  UI.user_error!("android-commons not present! Can't start danger") if !File.exist?("../android-commons")

  # Clear gradle_error file from previous runs
  pathToGradleError = "#{smf_workspace_dir}/.idea/gradle_errors"
  if File.exists?(pathToGradleError)
    FileUtils.rm_rf(pathToGradleError)
  end
  Dir.mkdir(pathToGradleError)

  moduleOptions = _readDangerModuleConfig(options)

  ktlintPaths = []
  detektPaths = []
  lintPaths = []
  junitResultPaths = []
  gradleErrorFiles = []

  moduleOptions.each do |item|
    module_name = item["module_name"]
    module_basepath = module_name
    if item["run_ktlint"] != false
      begin
        gradle(task: "#{module_name}:ktlint")
        ktlintPaths.append("#{module_basepath}/build/reports/ktlint/ktlint.xml")
      rescue => ex
        # noop, don't fail build if lint task fails
        gradleErrorFiles.append(_captureGradleError("#{module_name}:ktlint", ex))
      end
    end

    if item["run_detekt"] != false
      begin
        gradle(task: "#{module_name}:detekt")
        detektPaths.append("#{module_basepath}/build/reports/detekt/detekt.xml")
      rescue => ex
        # noop, don't fail build if lint task fails
        gradleErrorFiles.append(_captureGradleError("#{module_name}:detekt", ex))
      end
    end

    gradle_lint_task = item["gradle_lint_task"]
    if !(gradle_lint_task.nil?)
      begin
        gradle(task: "#{module_name}:#{gradle_lint_task}")
      rescue => ex
        # noop, don't fail build if lint task fails
      end
      lintPaths.append("#{module_basepath}/build/reports/lint/lint-result.xml")
    end

    junit_task = item["junit_task"]
    if !(junit_task.nil?)
      begin
        gradle(task: "#{module_name}:#{junit_task}")
        junitResultPaths.append("#{module_basepath}/build/test-results/#{junit_task}")
      rescue => ex
        gradleErrorFiles.append(_captureGradleError("#{module_name}:#{junit_task}", ex))
      end
    end

    # Build project and write any errors to a file for danger; don't fail on build error, danger will fail and post the error to the PR
    gradle_build_task = item["gradle_build_task"]
    if !(gradle_build_task.nil?)
      begin
        gradle(task: "#{module_name}:#{gradle_build_task}")
      rescue => ex
        gradleErrorFiles.append(_captureGradleError("#{module_name}:#{gradle_build_task}", ex))
      end
    end
  end

  ENV["DANGER_JIRA_KEYS"] = JSON.dump(_dangerJiraKeyParameter(options[:jira_key]))
  ENV["DANGER_KTLINT_PATHS"] = JSON.dump(ktlintPaths)
  ENV["DANGER_DETEKT_PATHS"] = JSON.dump(detektPaths)
  ENV["DANGER_LINT_PATHS"] = JSON.dump(lintPaths)
  ENV["DANGER_JUNIT_PATHS"] = JSON.dump(junitResultPaths)
  ENV["DANGER_GRADLE_ERROR_OUTPUT_FILES"] = JSON.dump(gradleErrorFiles)
  ENV["DANGER_CHECKSTYLE_PATHS"] = JSON.dump([])

  danger(
      github_api_token: ENV["DANGER_GITHUB_API_TOKEN"],
      dangerfile: "#{@fastlane_commons_dir_path}/danger/Dangerfile",
      verbose: true
  )
end

def _dangerJiraKeyParameter(jira_keys)
   # Set environment variables for danger if options parameter are present
  if !jira_keys.kind_of?(Array)
    jira_keys = [jira_keys]
  end
  
  keys = []
  jira_keys.each do |key|
    if key.is_a?(String)
      if !(key.nil?) && key != ""
        keys.append({
          "key" => key,
          "url" => "https://smartmobilefactory.atlassian.net/browse"
        })
      end
    else
      if !(key.nil?) && !(key["key"].nil?) && !(key["url"].nil?)
        keys.append(key)
      end
    end
  end
  keys
end

def _captureGradleError(task, ex)
  fileName = "#{smf_workspace_dir}/.idea/gradle_errors/#{task}.txt"
  fileContent = "**#{task}\n**LAST 3000 CHARACTERS OF GRADLE OUTPUT:**\n[...]\n" + ex.to_s.split(//).last(3000).join
  File.write(fileName, fileContent)
  fileName
end

def _readDangerModuleConfig(options)
  gradle_lint_task = options[:gradle_lint_task]
  gradle_build_task = options[:gradle_build_task]
  module_basepath = options[:module_basepath] || "app"
  run_detekt = options.fetch(:run_detekt, true)
  run_ktlint = options.fetch(:run_ktlint, true)
  junit_task = options[:junit_task]

  moduleOptions = options[:modules] || []
  if moduleOptions.length == 0
    moduleOptions.push({
      "gradle_lint_task" => gradle_lint_task,
      "gradle_build_task" => gradle_build_task,
      "module_name" => module_basepath,
      "run_detekt" => run_detekt,
      "run_ktlint" => run_ktlint,
      "junit_task" => junit_task
    })
  end

  moduleOptions
end

