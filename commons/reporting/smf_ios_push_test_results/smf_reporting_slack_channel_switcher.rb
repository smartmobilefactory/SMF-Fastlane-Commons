def smf_switch_to_reporting_slack_channel
  # Safe old slack channel (so it can be restored later)
  # set slack channel to reporting channel
  @original_slack_channel =  @smf_fastlane_config[:project][:slack_channel]
  @smf_fastlane_config[:project][:slack_channel] = $REPORTING_SLACK_CHANNEL
end

def smf_switch_to_original_slack_channel
  # resets slackchannel to original one
  @smf_fastlane_config[:project][:slack_channel] = @original_slack_channel
end