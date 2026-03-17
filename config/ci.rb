# Run using bin/ci
# Options: bin/ci --fail-fast, bin/ci --signoff

signoff = ARGV.include?("--signoff") || ARGV.include?("-s")
fail_fast = ARGV.include?("--fail-fast") || ARGV.include?("-f")

ci = CI.run("Continuous Integration", "Running checks...", fail_fast: fail_fast) do
  step "Rubocop", "bundle", "exec", "rubocop", "-A"
  # step "Prettier", "yarn", "prettier", "--config", ".prettierrc.json", "app/packs", "app/components", "--write"
  step "Brakeman", "bundle", "exec", "brakeman", "--quiet", "--no-pager", "--except=EOLRails"
  step "Minitest", "bundle", "exec", "rails", "test"
  step "Undercover", "bundle", "exec", "undercover", "--lcov", "coverage/lcov/app.lcov", "--compare", "origin/main"
end

if ci.success?
  if signoff
    puts "\nRunning gh signoff..."
    system("gh", "signoff") || warn("gh signoff failed - is gh-signoff installed?")
  end
  exit 0
else
  exit 1
end
