# frozen_string_literal: true

# Shared helpers for android/fastlane/Fastfile and ios/fastlane/Fastfile.
#
# One Flutter codebase, two apps. The `country:` lane option (usa | india) selects
# the package / bundle ID, the Flutter flavor, the entry point, the metadata folder
# and the per-country credentials (env vars suffixed _USA / _INDIA).

require "fileutils"
require "shellwords"

module IWant
  COUNTRIES = {
    "usa" => {
      name: "I Want USA",
      package: "com.calecute.iwant.usa",
      flavor: "usaProd",
      entry: "lib/main_usa.dart",
      suffix: "USA",
      play_locales: %w[en-US es-US],
      ios_locales: %w[en-US es-MX],
      ios_primary_locale: "en-US"
    },
    "india" => {
      name: "I Want India",
      package: "com.calecute.iwant.india",
      flavor: "indiaProd",
      entry: "lib/main_india.dart",
      suffix: "INDIA",
      play_locales: %w[en-IN hi-IN],
      ios_locales: %w[en-GB hi],
      ios_primary_locale: "en-GB"
    }
  }.freeze

  PLACEHOLDER = /\{\{\s*([A-Z0-9_]+)\s*\}\}/.freeze

  module_function

  def ui
    FastlaneCore::UI
  end

  # Repo root: the directory holding the Gemfile and fastlane/metadata.
  def root
    @root ||= begin
      if ENV["IWANT_REPO_ROOT"] && !ENV["IWANT_REPO_ROOT"].empty?
        File.expand_path(ENV["IWANT_REPO_ROOT"])
      else
        dir = File.expand_path(__dir__)
        dir = File.dirname(dir) until File.exist?(File.join(dir, "Gemfile")) || dir == File.dirname(dir)
        dir
      end
    end
  end

  def country!(options)
    value = (options && options[:country]) || ENV["IWANT_COUNTRY"]
    ui.user_error!("Missing country. Pass country:usa or country:india (or set IWANT_COUNTRY).") if value.nil? || value.to_s.empty?
    value = value.to_s.downcase.strip
    ui.user_error!("Unknown country '#{value}'. Use usa or india.") unless COUNTRIES.key?(value)
    ENV["IWANT_COUNTRY"] = value
    value
  end

  def cfg(country)
    COUNTRIES.fetch(country)
  end

  # Per-country env lookup: NAME_USA / NAME_INDIA first, then NAME.
  def env(name, country, required: true, default: nil)
    suffix = cfg(country)[:suffix]
    value = ENV["#{name}_#{suffix}"]
    value = ENV[name] if value.nil? || value.empty?
    value = default if value.nil? || value.empty?
    if required && (value.nil? || value.to_s.empty?)
      ui.user_error!("Missing env var #{name}_#{suffix} (or #{name}). See fastlane/README.md.")
    end
    value
  end

  # ---------- pubspec.yaml version ----------

  def pubspec_path
    File.join(root, "pubspec.yaml")
  end

  # Returns [version_name, build_number] from `version: 1.2.3+45`.
  def version
    ui.user_error!("pubspec.yaml not found at #{pubspec_path}") unless File.exist?(pubspec_path)
    line = File.read(pubspec_path)[/^version:\s*([^\s#]+)/, 1]
    ui.user_error!("pubspec.yaml has no `version:` line") unless line
    name, build = line.split("+", 2)
    ui.user_error!("pubspec.yaml version must look like 1.2.3+45 (got #{line})") unless name =~ /\A\d+\.\d+\.\d+\z/ && build =~ /\A\d+\z/
    [name, build.to_i]
  end

  def version_name
    version[0]
  end

  def build_number
    version[1]
  end

  # Writes a new build number (and optionally version name) into pubspec.yaml.
  def write_version!(build:, name: nil)
    current_name, = version
    name ||= current_name
    ui.user_error!("Version name must look like 1.2.3") unless name =~ /\A\d+\.\d+\.\d+\z/
    text = File.read(pubspec_path)
    File.write(pubspec_path, text.sub(/^version:\s*[^\s#]+/, "version: #{name}+#{build}"))
    ui.success("pubspec.yaml version is now #{name}+#{build}")
    [name, build]
  end

  # ---------- Flutter ----------

  # Runs a shell command (streaming output) and fails the lane if it fails.
  def run(command, dir: root)
    ui.command(command)
    ok = Dir.chdir(dir) { system(command) }
    ui.user_error!("Command failed (exit #{$?&.exitstatus}): #{command}") unless ok
    true
  end

  def flutter(args)
    run("flutter #{args}")
  end

  def dart_define_args(country)
    file = env("DART_DEFINE_FILE", country, required: false)
    return "" unless file
    path = File.expand_path(file, root)
    ui.user_error!("DART_DEFINE_FILE #{path} not found") unless File.exist?(path)
    "--dart-define-from-file=#{path.shellescape}"
  end

  def flutter_build_args(country, platform)
    c = cfg(country)
    [
      "--release",
      "--flavor #{c[:flavor]}",
      "-t #{c[:entry]}",
      "--build-name=#{version_name}",
      "--build-number=#{build_number}",
      "--obfuscate",
      "--split-debug-info=build/symbols/#{country}/#{platform}",
      dart_define_args(country)
    ].reject(&:empty?).join(" ")
  end

  # ---------- Android ----------

  def play_json_key(country)
    data = env("PLAY_JSON_KEY_DATA", country, required: false)
    return { json_key_data: data } if data
    { json_key: File.expand_path(env("PLAY_JSON_KEY_PATH", country), root) }
  end

  # Gradle contract: android/app/build.gradle.kts reads ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD,
  # ANDROID_KEY_ALIAS and ANDROID_KEY_PASSWORD (android/key.properties wins when present).
  # Copy the per-country values (_USA / _INDIA) into those names for this build.
  def export_android_signing_env(country)
    path = env("ANDROID_KEYSTORE_PATH", country, required: false)
    return ui.important("ANDROID_KEYSTORE_PATH_#{cfg(country)[:suffix]} not set; Gradle uses android/key.properties (or debug keys)") unless path
    ENV["ANDROID_KEYSTORE_PATH"] = File.expand_path(path, root)
    ENV["ANDROID_KEYSTORE_PASSWORD"] = env("ANDROID_KEYSTORE_PASSWORD", country)
    ENV["ANDROID_KEY_ALIAS"] = env("ANDROID_KEY_ALIAS", country)
    ENV["ANDROID_KEY_PASSWORD"] = env("ANDROID_KEY_PASSWORD", country)
    maps = env("MAPS_API_KEY_ANDROID", country, required: false)
    ENV["MAPS_API_KEY_ANDROID"] = maps if maps
  end

  def find_aab(country)
    flavor = cfg(country)[:flavor]
    dir = File.join(root, "build", "app", "outputs", "bundle", "#{flavor}Release")
    aab = Dir[File.join(dir, "*.aab")].max_by { |f| File.mtime(f) }
    ui.user_error!("No .aab found in #{dir}") unless aab
    aab
  end

  def find_mapping(country)
    path = File.join(root, "build", "app", "outputs", "mapping", "#{cfg(country)[:flavor]}Release", "mapping.txt")
    File.exist?(path) ? path : nil
  end

  # ---------- Metadata ----------

  def metadata_source(platform, country)
    File.join(root, "fastlane", "metadata", platform, country)
  end

  def screenshots_path(country)
    path = File.join(root, "fastlane", "screenshots", "ios", country)
    Dir[File.join(path, "**", "*.{png,jpg,jpeg}")].empty? ? nil : path
  end

  # Copies fastlane/metadata/<platform>/<country> to build/fastlane/metadata/<platform>/<country>,
  # replacing {{NAME}} in every .txt with ENV NAME_<COUNTRY> (or NAME). Fails on any missing value,
  # so domains and review credentials never ship as literal placeholders and never live in git.
  def render_metadata(platform, country)
    src = metadata_source(platform, country)
    ui.user_error!("Metadata folder #{src} not found") unless File.directory?(src)
    check_metadata(platform, country)
    dest = File.join(root, "build", "fastlane", "metadata", platform, country)
    FileUtils.rm_rf(dest)
    FileUtils.mkdir_p(File.dirname(dest))
    FileUtils.cp_r(src, dest)
    missing = []
    Dir[File.join(dest, "**", "*.txt")].each do |file|
      text = File.read(file)
      next unless text =~ PLACEHOLDER
      File.write(file, text.gsub(PLACEHOLDER) do
        name = Regexp.last_match(1)
        value = env(name, country, required: false)
        missing << "#{name}_#{cfg(country)[:suffix]}" unless value
        value || "{{#{name}}}"
      end)
    end
    ui.user_error!("Set these env vars before uploading metadata: #{missing.uniq.sort.join(', ')}") unless missing.empty?
    dest
  end

  def check_metadata(platform, country)
    script = File.join(root, "fastlane", "check_metadata.py")
    run("python3 #{script.shellescape} --platform #{platform} --country #{country}")
  end

  def release_notes(country)
    file = File.join(metadata_source("ios", country), cfg(country)[:ios_primary_locale], "release_notes.txt")
    File.exist?(file) ? File.read(file).strip : "Bug fixes and improvements."
  end
end
