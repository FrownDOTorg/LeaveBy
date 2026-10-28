require 'yaml'
require 'json'
project = YAML.load_file('project.yml')
project['settings']['base']['DEVELOPMENT_TEAM'] = 'WCL29SZ993'
project['settings']['base']['MARKETING_VERSION'] = '1.0'
# A new run or rerun must use a new build number.
project['settings']['base']['CURRENT_PROJECT_VERSION'] = (ENV.fetch('GITHUB_RUN_NUMBER').to_i * 100 + ENV.fetch('GITHUB_RUN_ATTEMPT').to_i).to_s
profiles = JSON.parse(File.read('build/profiles.json'))
project['targets'].each_value do |target|
  settings = target['settings']['base']
  settings['CODE_SIGN_STYLE'] = 'Manual'
  settings['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
  settings['PROVISIONING_PROFILE_SPECIFIER'] = profiles.fetch(settings['PRODUCT_BUNDLE_IDENTIFIER'])
end
# XcodeGen resolves paths relative to its spec; write the temporary spec at the repo root.

File.write('project-release.json', JSON.pretty_generate(project))
