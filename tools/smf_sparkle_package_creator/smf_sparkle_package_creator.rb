
lane :smf_create_sparkle_package do |options|
  UI.message("Starting sparkle package creator...")
=begin
  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant.to_sym]
  sparkle_config = build_variant_config[:sparkle]

  smf_upload_with_sparkle(
    build_variant: build_variant,
    scheme: build_variant_config[:scheme],
    sparkle_dmg_path: sparkle_config[:dmg_path],
    sparkle_version: sparkle_config[:sparkle_version],
    sparkle_signing_team: sparkle_config[:sparkle_signing_team],
    sparkle_private_key: sparkle_config[:signing_key]
  )
=end
end



# "CONSTANTS"
def _smf_spc_template_path
  File.join(smf_workspace_dir,"#{@fastlane_commons_dir_path}/commons/smf_generate_jenkins_file/Jenkinsfile_Sparkle_Package_Creator.template)")
end

def _smf_spc_jenkinsfile_path
  File.join(smf_workspace_dir,'Sparkle-Package-Creator/Sparkle-Package-Creator-Jenkinsfile')
end