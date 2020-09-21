require_relative './project_analysers/analysers/branch_name_analyser.rb'

def smf_meta_report_ios(options)

	############### SETUP ######################
	src_root = smf_workspace_dir

	############### ANALYSIS ###################
	analysis_data = [IOSProjectAnalyser::analyse(src_root)]
  analysis_data.compact!

  ############### UPLOAD #####################

  GoogleSpreadSheetUploader::report_to_google_sheets(
    analysis_data,
    options
  )

end