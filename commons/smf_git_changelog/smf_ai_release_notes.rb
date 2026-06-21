# AI-generated release notes for Firebase App Distribution and TestFlight
# CBENEFIOS-1886, CBENEFIOS-1887
#
# Provider: afmcli (Apple Foundation Models, on-device, macOS 26+).
# The previous Anthropic/OpenAI HTTP paths are gone — afmcli wraps
# Apple's FoundationModels framework and runs on the Mac agent itself,
# so no API key or network round-trip is required.
#
# Translation continues to live in Groovy/DeepL inside the Jenkins
# pipelines (set-testflight-notes.groovy, prepare-app-store-release.groovy)
# — this file no longer participates in translation.
#
# Install on each Mac agent:
#   brew install rudivice/tools/afmcli
#
# Config.json example:
# {
#   "ai_release_notes": {
#     "enabled": true,
#     "alpha_mode": "comparison",
#     "beta_mode": "ai_only"
#   }
# }

require 'open3'
require 'json'
require 'set'

def smf_ai_release_notes_enabled?
  config = @smf_fastlane_config[:ai_release_notes]
  return false if config.nil?

  enabled = config[:enabled] || config['enabled']
  return false unless enabled

  unless system('command -v afmcli > /dev/null 2>&1')
    UI.message('AI release notes disabled: afmcli not installed on this agent (brew install rudivice/tools/afmcli)')
    return false
  end

  true
end

def smf_get_ai_release_notes_config
  config = @smf_fastlane_config[:ai_release_notes] || {}
  # Compatibility note (CBENEFIOS-2504):
  #   provider / api_key_env / model are no longer used by this gem after the
  #   afmcli migration, but a few external callers still read them (informational
  #   logs in smf_upload_to_firebase.rb, and the to-be-removed
  #   ai_filter_testflight_relevant in CorporateBenefits-MP/Fastfile, which is
  #   migrated in PR 2). We keep the keys with safe defaults so:
  #     - ENV[config[:api_key_env]] returns nil (NOT a TypeError)
  #     - the caller's existing 'if api_key.nil? — fail-open' branch triggers
  #     - logging shows meaningful strings instead of empty interpolations
  #   These keys can be dropped after PR 2 + bake-out are merged.
  {
    enabled: config[:enabled] || config['enabled'] || false,
    provider: 'apple-on-device',
    api_key_env: 'AFMCLI_NO_KEY_NEEDED',
    model: 'on-device',
    alpha_mode: (config[:alpha_mode] || config['alpha_mode'] || 'comparison').to_sym,
    beta_mode: (config[:beta_mode] || config['beta_mode'] || 'ai_only').to_sym
  }
end

# Main entry point for generating AI release notes
# @param tickets [Hash] Ticket data from smf_generate_tickets_from_tags
# @param options [Hash] Options hash
#   - build_variant [String] e.g., 'germany_alpha', 'austria_beta'
#   - language [String] Target language code (default: 'en')
#   - max_length [Integer] Maximum character length (default: 700 for Firebase)
#   - ticket_commits [Hash] Map of ticket tag to commit messages (optional)
# @return [String, nil] Generated release notes or nil if disabled/failed
def smf_generate_ai_release_notes(tickets, options = {})
  return nil unless smf_ai_release_notes_enabled?

  config = smf_get_ai_release_notes_config
  build_variant = options[:build_variant] || ''
  ticket_commits = options[:ticket_commits] || {}

  # Determine mode based on build variant
  is_alpha = build_variant.downcase.include?('alpha')
  mode = if is_alpha
           config[:alpha_mode]
         else
           config[:beta_mode]
         end

  include_jira_links = (mode == :comparison)
  language = options[:language] || 'en'
  max_length = options[:max_length] || 700

  UI.message("Generating AI release notes (afmcli, mode: #{mode}, links: #{include_jira_links})")

  # Deduplicate tickets
  unique_tickets = _smf_deduplicate_tickets(tickets)

  # Get DevOps tickets (CBENEFIOS-2079) — only for alpha builds in comparison mode
  devops_tickets = []
  if is_alpha && mode == :comparison
    devops_tickets = tickets[:devops] || []
    if devops_tickets.empty? && defined?(smf_read_devops_tickets)
      devops_tickets = smf_read_devops_tickets
    end
    UI.message("DevOps tickets found: #{devops_tickets.length}")
  end

  if unique_tickets.empty? && devops_tickets.empty?
    UI.message('No tickets found for AI release notes generation')
    return nil
  end

  UI.message("Processing #{unique_tickets.length} app tickets + #{devops_tickets.length} devops tickets")

  # Prepare ticket summaries for AI (including commit messages if available)
  # Only include app tickets in AI summary, not DevOps tickets
  ticket_summaries = unique_tickets.map do |ticket|
    tag = ticket[:tag]
    title = ticket[:title]
    commits = ticket_commits[tag] || []

    if commits.any?
      commit_info = commits.take(3).join('; ') # Limit to 3 commits per ticket
      "#{tag}: #{title}\n  Commits: #{commit_info}"
    else
      "#{tag}: #{title}"
    end
  end

  # Generate AI release notes via afmcli
  ai_notes = if ticket_summaries.any?
               _smf_call_afmcli_shorten(ticket_summaries, language, max_length, mode)
             else
               'Infrastructure and DevOps updates.'
             end

  return nil if ai_notes.nil?

  # Format based on mode
  UI.message("🔧 Formatting mode: #{mode.inspect} (class: #{mode.class})")
  UI.message("   Unique tickets for list: #{unique_tickets.length}")
  UI.message("   DevOps tickets for list: #{devops_tickets.length}")

  result = case mode
           when :comparison
             UI.message('   → Using comparison mode (with ticket list)')
             _smf_format_comparison_notes(unique_tickets, ai_notes, include_jira_links, devops_tickets)
           when :ai_only
             UI.message('   → Using ai_only mode (no ticket list)')
             ai_notes
           else
             UI.message("   → Using fallback mode: #{mode}")
             ai_notes
           end

  UI.message("📋 Final result length: #{result&.length || 0} chars")
  result
end

# Deduplicate tickets by merging normal and linked tickets
# @param tickets [Hash] Ticket data with :normal and :linked arrays
# @return [Array<Hash>] Array of unique tickets
def _smf_deduplicate_tickets(tickets)
  return [] if tickets.nil?

  seen_tags = Set.new
  unique_tickets = []

  # Process normal tickets first (they have more info)
  (tickets[:normal] || []).each do |ticket|
    next if seen_tags.include?(ticket[:tag])

    seen_tags.add(ticket[:tag])
    unique_tickets << ticket
  end

  # Add linked tickets that weren't in normal
  (tickets[:linked] || []).each do |ticket|
    next if seen_tags.include?(ticket[:tag])

    seen_tags.add(ticket[:tag])
    unique_tickets << ticket
  end

  unique_tickets
end

# Shell out to `afmcli shorten` to produce user-facing release notes.
# The tool is installed on every Mac agent via `brew install rudivice/tools/afmcli`
# and uses the on-device Apple Foundation Model on macOS 26+.
#
# If the model is unavailable on the agent (Apple Intelligence off, older OS),
# afmcli still exits 0 with `ok: false` and a `fallback-truncate` engine — we
# treat that as a soft failure: we log it and pass the (truncated) output back
# so the pipeline keeps moving.
#
# @param ticket_summaries [Array<String>] Pre-built ticket-summary lines
# @param language [String] ISO 639-1 code, e.g. 'en' or 'de'
# @param max_length [Integer] Hard character budget for the output
# @param mode [Symbol] :comparison or :ai_only — passed through to afmcli's prompt selection
# @return [String, nil] The generated notes, or nil on hard failure
def _smf_call_afmcli_shorten(ticket_summaries, language, max_length, mode)
  body = ticket_summaries.join("\n")
  afmcli_mode = mode == :comparison ? 'comparison' : 'ai-only'
  cmd = [
    'afmcli', 'shorten',
    '--max-chars', max_length.to_s,
    '--language', language,
    '--mode', afmcli_mode,
    '--style', 'release-notes'
  ]

  UI.message("🔌 afmcli shorten (--mode #{afmcli_mode} --max-chars #{max_length} --language #{language})")
  UI.message("   Input length: #{body.length} chars (#{ticket_summaries.length} tickets)")

  stdout, stderr, status = Open3.capture3(*cmd, stdin_data: body)

  unless status.success?
    UI.error("❌ afmcli exited #{status.exitstatus}")
    UI.error("   stderr: #{stderr[0..500]}")
    return nil
  end

  begin
    result = JSON.parse(stdout)
  rescue JSON::ParserError => e
    UI.error("❌ afmcli returned non-JSON output: #{e.message}")
    UI.error("   stdout: #{stdout[0..500]}")
    return nil
  end

  engine = result['engine'] || 'unknown'
  ok = result['ok']
  truncated = result['truncated']
  output = result['output']

  if ok
    UI.success("✅ afmcli success (engine: #{engine}, truncated: #{truncated}, chars: #{result['char_count']})")
  else
    reason = result.dig('error', 'reason') || 'unknown'
    UI.important("⚠️ afmcli fallback path engaged (engine: #{engine}, reason: #{reason}) — release notes are not LLM-polished")
  end

  output&.strip
rescue StandardError => e
  UI.error("❌ Failed to invoke afmcli: #{e.message}")
  UI.error("   #{e.backtrace.first(3).join("\n   ")}")
  nil
end

# Format comparison notes (technical list + AI notes + DevOps section for alpha)
# @param tickets [Array<Hash>] Unique tickets
# @param ai_notes [String] AI-generated notes
# @param include_links [Boolean] Whether to include Jira links
# @param devops_tickets [Array<Hash>] DevOps tickets (optional, for alpha builds)
# @return [String] Formatted comparison notes
def _smf_format_comparison_notes(tickets, ai_notes, include_links, devops_tickets = nil)
  technical_section = ''

  # App tickets section
  if tickets && !tickets.empty?
    technical_section += "Tickets:\n"
    tickets.each do |ticket|
      technical_section += if include_links && ticket[:link]
                             "- #{ticket[:tag]}: #{ticket[:title]}\n  #{ticket[:link]}\n"
                           else
                             "- #{ticket[:tag]}: #{ticket[:title]}\n"
                           end
    end
  end

  # DevOps tickets section (CBENEFIOS-2079)
  if devops_tickets && !devops_tickets.empty?
    technical_section += "\nDevOps/Config:\n"
    devops_tickets.each do |ticket|
      technical_section += if include_links && ticket[:link]
                             "- #{ticket[:tag]}: #{ticket[:title]}\n  #{ticket[:link]}\n"
                           else
                             "- #{ticket[:tag]}: #{ticket[:title]}\n"
                           end
    end
  end

  return ai_notes if technical_section.empty?

  <<~NOTES
    #{ai_notes}

    ---
    #{technical_section}
  NOTES
end
