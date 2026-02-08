# AI-generated release notes for Firebase App Distribution and TestFlight
# CBENEFIOS-1886, CBENEFIOS-1887
#
# Supported providers: OpenAI, Anthropic
#
# Config.json example:
# {
#   "ai_release_notes": {
#     "enabled": true,
#     "provider": "openai",           # or "anthropic"
#     "api_key_env": "OPENAI_API_KEY", # or "ANTHROPIC_API_KEY"
#     "model": "gpt-4o-mini",          # or "claude-3-haiku-20240307"
#     "alpha_mode": "comparison",
#     "beta_mode": "ai_only"
#   }
# }

require 'net/http'
require 'uri'
require 'json'
require 'set'

# Default models per provider
AI_DEFAULT_MODELS = {
  'openai' => 'gpt-4o-mini',
  'anthropic' => 'claude-3-haiku-20240307'
}.freeze

# Default API key environment variable names per provider
# Note: Jenkins credentials use hyphens (ANTHROPIC-API-KEY), but env vars use underscores
AI_DEFAULT_API_KEY_ENV = {
  'openai' => 'OPENAI_API_KEY',
  'anthropic' => 'ANTHROPIC_API_KEY'
}.freeze

def smf_ai_release_notes_enabled?
  config = @smf_fastlane_config[:ai_release_notes]
  return false if config.nil?

  enabled = config[:enabled] || config['enabled']
  return false unless enabled

  provider = (config[:provider] || config['provider'] || 'openai').to_s.downcase
  default_env = AI_DEFAULT_API_KEY_ENV[provider] || 'OPENAI_API_KEY'
  api_key_env = config[:api_key_env] || config['api_key_env'] || default_env
  api_key = ENV[api_key_env]

  if api_key.nil? || api_key.empty?
    UI.message("AI release notes disabled: #{api_key_env} not set")
    return false
  end

  true
end

def smf_get_ai_release_notes_config
  config = @smf_fastlane_config[:ai_release_notes] || {}
  provider = (config[:provider] || config['provider'] || 'openai').to_s.downcase

  default_model = AI_DEFAULT_MODELS[provider] || 'gpt-4o-mini'
  default_env = AI_DEFAULT_API_KEY_ENV[provider] || 'OPENAI_API_KEY'

  {
    enabled: config[:enabled] || config['enabled'] || false,
    provider: provider,
    api_key_env: config[:api_key_env] || config['api_key_env'] || default_env,
    model: config[:model] || config['model'] || default_model,
    alpha_mode: (config[:alpha_mode] || config['alpha_mode'] || 'comparison').to_sym,
    beta_mode: (config[:beta_mode] || config['beta_mode'] || 'ai_only').to_sym
  }
end

# Main entry point for generating AI release notes
# @param tickets [Hash] Ticket data from smf_generate_tickets_from_tags
# @param options [Hash] Options hash
#   - build_variant [String] e.g., 'germany_alpha', 'austria_beta'
#   - language [String] Target language code (default: 'en')
#   - max_length [Integer] Maximum character length (default: 500 for Firebase)
#   - ticket_commits [Hash] Map of ticket tag to commit messages (optional)
# @return [String, nil] Generated release notes or nil if disabled/failed
def smf_generate_ai_release_notes(tickets, options = {})
  return nil unless smf_ai_release_notes_enabled?

  config = smf_get_ai_release_notes_config
  build_variant = options[:build_variant] || ''
  ticket_commits = options[:ticket_commits] || {}

  # Determine mode based on build variant
  mode = if build_variant.downcase.include?('alpha')
           config[:alpha_mode]
         else
           config[:beta_mode]
         end

  include_jira_links = (mode == :comparison)
  language = options[:language] || 'en'
  max_length = options[:max_length] || 500

  UI.message("Generating AI release notes (provider: #{config[:provider]}, mode: #{mode}, links: #{include_jira_links})")

  # Deduplicate tickets
  unique_tickets = _smf_deduplicate_tickets(tickets)

  if unique_tickets.empty?
    UI.message("No tickets found for AI release notes generation")
    return nil
  end

  UI.message("Processing #{unique_tickets.length} unique tickets for AI generation")

  # Prepare ticket summaries for AI (including commit messages if available)
  ticket_summaries = unique_tickets.map do |ticket|
    tag = ticket[:tag]
    title = ticket[:title]
    commits = ticket_commits[tag] || []

    if commits.any?
      # Include commit messages for better context
      commit_info = commits.take(3).join('; ')  # Limit to 3 commits per ticket
      "#{tag}: #{title}\n  Commits: #{commit_info}"
    else
      "#{tag}: #{title}"
    end
  end

  # Generate AI release notes using configured provider
  ai_notes = _smf_call_ai_api(ticket_summaries, language, max_length, config)

  return nil if ai_notes.nil?

  # Format based on mode
  case mode
  when :comparison
    _smf_format_comparison_notes(unique_tickets, ai_notes, include_jira_links)
  when :ai_only
    ai_notes
  else
    ai_notes
  end
end

# Generate localized release notes for TestFlight
# @param tickets [Hash] Ticket data from smf_generate_tickets_from_tags
# @param options [Hash] Options hash
#   - base_language [String] Base language for generation (default: 'en')
#   - target_languages [Array<String>] Languages to translate to
#   - max_length [Integer] Maximum character length per language
# @return [Hash<String, String>] Hash of language code to release notes
def smf_generate_localized_release_notes(tickets, options = {})
  return {} unless smf_ai_release_notes_enabled?

  config = smf_get_ai_release_notes_config
  base_language = options[:base_language] || 'en'
  target_languages = options[:target_languages] || ['de', 'es', 'fr', 'it', 'nl', 'pl', 'pt', 'tr']
  max_length = options[:max_length] || 4000 # TestFlight allows longer notes

  # Generate base English notes first
  base_notes = smf_generate_ai_release_notes(tickets, {
    build_variant: 'release', # Use ai_only mode for TestFlight
    language: base_language,
    max_length: max_length
  })

  return {} if base_notes.nil?

  localized_notes = { base_language => base_notes }

  # Translate to each target language
  target_languages.each do |lang|
    next if lang == base_language

    UI.message("Translating release notes to #{lang}...")
    translated = _smf_translate_with_ai(base_notes, base_language, lang, config)

    if translated
      localized_notes[lang] = translated
    else
      UI.important("Failed to translate to #{lang}, using base language")
      localized_notes[lang] = base_notes
    end
  end

  localized_notes
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

# Route AI API call to the appropriate provider
# @param ticket_summaries [Array<String>] List of ticket summaries
# @param language [String] Target language
# @param max_length [Integer] Maximum output length
# @param config [Hash] AI configuration
# @return [String, nil] Generated notes or nil on failure
def _smf_call_ai_api(ticket_summaries, language, max_length, config)
  case config[:provider]
  when 'anthropic'
    _smf_call_anthropic_api(ticket_summaries, language, max_length, config)
  when 'openai'
    _smf_call_openai_api(ticket_summaries, language, max_length, config)
  else
    UI.error("Unknown AI provider: #{config[:provider]}")
    nil
  end
end

# Call OpenAI API to generate release notes
# @param ticket_summaries [Array<String>] List of ticket summaries
# @param language [String] Target language
# @param max_length [Integer] Maximum output length
# @param config [Hash] AI configuration
# @return [String, nil] Generated notes or nil on failure
def _smf_call_openai_api(ticket_summaries, language, max_length, config)
  api_key = ENV[config[:api_key_env]]
  model = config[:model]

  prompt = _smf_build_release_notes_prompt(ticket_summaries, language, max_length)

  begin
    uri = URI.parse('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{api_key}"

    request.body = {
      model: model,
      messages: [
        { role: 'user', content: prompt }
      ],
      max_tokens: 500,
      temperature: 0.7
    }.to_json

    response = http.request(request)

    if response.code == '200'
      result = JSON.parse(response.body)
      notes = result.dig('choices', 0, 'message', 'content')
      UI.success("AI release notes generated successfully (OpenAI #{model})")
      notes&.strip
    else
      UI.error("OpenAI API error: #{response.code} - #{response.body}")
      nil
    end
  rescue StandardError => e
    UI.error("Failed to call OpenAI API: #{e.message}")
    nil
  end
end

# Call Anthropic API to generate release notes
# @param ticket_summaries [Array<String>] List of ticket summaries
# @param language [String] Target language
# @param max_length [Integer] Maximum output length
# @param config [Hash] AI configuration
# @return [String, nil] Generated notes or nil on failure
def _smf_call_anthropic_api(ticket_summaries, language, max_length, config)
  api_key = ENV[config[:api_key_env]]
  model = config[:model]

  prompt = _smf_build_release_notes_prompt(ticket_summaries, language, max_length)

  begin
    uri = URI.parse('https://api.anthropic.com/v1/messages')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['x-api-key'] = api_key
    request['anthropic-version'] = '2023-06-01'

    request.body = {
      model: model,
      max_tokens: 500,
      messages: [
        { role: 'user', content: prompt }
      ]
    }.to_json

    response = http.request(request)

    if response.code == '200'
      result = JSON.parse(response.body)
      notes = result.dig('content', 0, 'text')
      UI.success("AI release notes generated successfully (Anthropic #{model})")
      notes&.strip
    else
      UI.error("Anthropic API error: #{response.code} - #{response.body}")
      nil
    end
  rescue StandardError => e
    UI.error("Failed to call Anthropic API: #{e.message}")
    nil
  end
end

# Build the prompt for release notes generation
# @param ticket_summaries [Array<String>] List of ticket summaries
# @param language [String] Target language
# @param max_length [Integer] Maximum output length
# @return [String] The prompt
def _smf_build_release_notes_prompt(ticket_summaries, language, max_length)
  language_name = _smf_language_name(language)

  <<~PROMPT
    You are a mobile app release notes writer. Transform these technical Jira ticket titles into user-friendly release notes.

    Guidelines:
    - Focus on benefits and improvements for end users
    - Use simple, non-technical language
    - Group into categories if appropriate (New Features, Improvements, Bug Fixes)
    - Use emoji sparingly for visual appeal
    - Maximum length: #{max_length} characters
    - Language: #{language_name}
    - Tone: Professional but friendly, encourage feedback

    Tickets:
    #{ticket_summaries.join("\n")}

    Generate concise, user-friendly release notes:
  PROMPT
end

# Translate text using the configured AI provider
# @param text [String] Text to translate
# @param from_lang [String] Source language code
# @param to_lang [String] Target language code
# @param config [Hash] AI configuration
# @return [String, nil] Translated text or nil on failure
def _smf_translate_with_ai(text, from_lang, to_lang, config)
  case config[:provider]
  when 'anthropic'
    _smf_translate_with_anthropic(text, from_lang, to_lang, config)
  when 'openai'
    _smf_translate_with_openai(text, from_lang, to_lang, config)
  else
    UI.error("Unknown AI provider for translation: #{config[:provider]}")
    nil
  end
end

# Translate using OpenAI
def _smf_translate_with_openai(text, from_lang, to_lang, config)
  api_key = ENV[config[:api_key_env]]
  model = config[:model]
  prompt = _smf_build_translation_prompt(text, from_lang, to_lang)

  begin
    uri = URI.parse('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{api_key}"

    request.body = {
      model: model,
      messages: [
        { role: 'user', content: prompt }
      ],
      max_tokens: 600,
      temperature: 0.3
    }.to_json

    response = http.request(request)

    if response.code == '200'
      result = JSON.parse(response.body)
      translation = result.dig('choices', 0, 'message', 'content')
      UI.success("Translated to #{_smf_language_name(to_lang)} successfully (OpenAI)")
      translation&.strip
    else
      UI.error("Translation API error: #{response.code}")
      nil
    end
  rescue StandardError => e
    UI.error("Failed to translate with OpenAI: #{e.message}")
    nil
  end
end

# Translate using Anthropic
def _smf_translate_with_anthropic(text, from_lang, to_lang, config)
  api_key = ENV[config[:api_key_env]]
  model = config[:model]
  prompt = _smf_build_translation_prompt(text, from_lang, to_lang)

  begin
    uri = URI.parse('https://api.anthropic.com/v1/messages')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['x-api-key'] = api_key
    request['anthropic-version'] = '2023-06-01'

    request.body = {
      model: model,
      max_tokens: 600,
      messages: [
        { role: 'user', content: prompt }
      ]
    }.to_json

    response = http.request(request)

    if response.code == '200'
      result = JSON.parse(response.body)
      translation = result.dig('content', 0, 'text')
      UI.success("Translated to #{_smf_language_name(to_lang)} successfully (Anthropic)")
      translation&.strip
    else
      UI.error("Translation API error: #{response.code}")
      nil
    end
  rescue StandardError => e
    UI.error("Failed to translate with Anthropic: #{e.message}")
    nil
  end
end

# Build the prompt for translation
def _smf_build_translation_prompt(text, from_lang, to_lang)
  from_name = _smf_language_name(from_lang)
  to_name = _smf_language_name(to_lang)

  <<~PROMPT
    Translate the following mobile app release notes from #{from_name} to #{to_name}.

    Guidelines:
    - Maintain the same tone and style
    - Keep emoji and formatting
    - Preserve technical terms that shouldn't be translated (app names, etc.)
    - Natural, native-sounding translation

    Text to translate:
    #{text}

    #{to_name} translation:
  PROMPT
end

# Get human-readable language name
def _smf_language_name(lang_code)
  {
    'en' => 'English',
    'de' => 'German',
    'es' => 'Spanish',
    'fr' => 'French',
    'it' => 'Italian',
    'nl' => 'Dutch',
    'pl' => 'Polish',
    'pt' => 'Portuguese',
    'tr' => 'Turkish'
  }[lang_code] || 'English'
end

# Format comparison notes (technical list + AI notes)
# @param tickets [Array<Hash>] Unique tickets
# @param ai_notes [String] AI-generated notes
# @param include_links [Boolean] Whether to include Jira links
# @return [String] Formatted comparison notes
def _smf_format_comparison_notes(tickets, ai_notes, include_links)
  technical_section = "Tickets:\n"

  tickets.each do |ticket|
    if include_links && ticket[:link]
      technical_section += "- #{ticket[:tag]}: #{ticket[:title]}\n  #{ticket[:link]}\n"
    else
      technical_section += "- #{ticket[:tag]}: #{ticket[:title]}\n"
    end
  end

  <<~NOTES
    #{ai_notes}

    ---
    #{technical_section}
  NOTES
end
