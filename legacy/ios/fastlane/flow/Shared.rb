####################
### smf_check_pr ###
####################

private_lane :smf_check_pr do |options|

  # If we're on a non-pipeline job we should skip this step. Remove this after all jobs are migrated to pipeline.
  if ENV["CHANGE_BRANCH"] != nil
    smf_update_generated_setup_file
  end

  smf_install_pods_if_project_contains_podfile

  # Use the current build variant if no array of build variants to check is provided
  if @smf_build_variants_array.nil? || @smf_build_variants_array.length == 0
    smf_set_build_variants_array([@smf_build_variant])
  else
    UI.important("Multiple build variants are declared. Checking the PR for #{@smf_build_variants_array}")
  end

  bulk_deploy_params = @smf_build_variants_array.length > 1 ? {index: 0, count: @smf_build_variants_array.length} : nil
  for build_variant in @smf_build_variants_array

    UI.important("Starting PR check for build variant \"#{build_variant}\"")

    # Cleanup
    ENV[$SMF_DID_RUN_UNIT_TESTS_ENV_KEY] = "false"

    smf_set_build_variant(build_variant, false)

    # Archive the IPA if the build variant didn't opt-out
    build_variant_config = @smf_fastlane_config[:build_variants][@smf_build_variant_sym]
    should_archive_ipa = (build_variant_config["pr.archive_ipa".to_sym].nil? ? (smf_is_build_variant_a_pod == false) : build_variant_config["pr.archive_ipa".to_sym])

    smf_generate_temporary_appfile

    if should_archive_ipa
      smf_archive_ipa_if_scheme_is_provided(
        skip_export: true,
        bulk_deploy_params: bulk_deploy_params
        )
    end
    
    should_run_danger = (build_variant_config["pr.run_danger".to_sym].nil? ? true : build_variant_config["pr.run_danger".to_sym])

    # Run the unit tests if the build variant didn't opt-out
    should_perform_unit_test = (build_variant_config["pr.perform_unit_tests".to_sym].nil? ? true : build_variant_config["pr.perform_unit_tests".to_sym])

    begin
      if should_perform_unit_test && smf_can_unit_tests_be_performed
        smf_perform_unit_tests
      end
    rescue => exception

      # Run Danger if the build variant didn't opt-out even if the unit tests failed
      if should_run_danger
        smf_run_danger
      end

      # Raise the exception as the build job should fail if the unit tests fail
      raise exception
    end

    # Run Danger if the build variant didn't opt-out
    if should_run_danger
      smf_run_danger
    end

    if bulk_deploy_params != nil
      bulk_deploy_params[:index] += 1
    end
  end

end
