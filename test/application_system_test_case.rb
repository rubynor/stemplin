require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Browser tests share a session and run serially.
  parallelize(workers: 1)

  driven_by :selenium, using: ENV["HEADFUL"].present? ? :chrome : :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    options.add_option("goog:loggingPrefs", { browser: "ALL" })
    # Disable optional browser prompts during automated sign-in.
    options.add_argument("--disable-notifications")
    options.add_preference(:credentials_enable_service, false)
    options.add_preference("profile.password_manager_enabled", false)
    options.add_preference("profile.password_manager_leak_detection", false)
  end

  Capybara.default_max_wait_time = 5
  Capybara.enable_aria_label = true

  # Linux distributions often ship Chromium rather than Google Chrome.
  if (browser = ENV["CHROME_BIN"] || %w[/usr/bin/chromium /usr/bin/chromium-browser].find { |path| File.executable?(path) })
    Selenium::WebDriver::Chrome.path = browser
  end

  # Exercise the real sign-in form and dismiss the notice that covers the menu.
  # Keep the document returned by Turbo so setup cannot race another navigation.
  def sign_in_as(user, password: "password", keep_flash: false)
    visit new_user_session_path
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: password
    click_button I18n.t("login_page.sign_in")

    assert_no_current_path new_user_session_path
    assert_text I18n.t("devise.sessions.signed_in")
    return if keep_flash

    find("#flash [data-action='snackbar#close']").click
    assert_no_selector "#flash [data-controller='snackbar']", visible: :all
  end

  def after_teardown
    dump_browser_console if failed?
  ensure
    super
  end

  private

  # Keep diagnostics on failures without instrumenting every page interaction.
  def dump_browser_console
    dir = Rails.root.join("tmp/screenshots")
    FileUtils.mkdir_p(dir)
    console = page.driver.browser.logs.get(:browser).map { |entry| "#{entry.level} #{entry.message}" }
    File.write(dir.join("#{method_name}.browser.txt"), [ "URL: #{page.current_url}", *console ].join("\n"))
  rescue => error
    warn "Could not dump browser console: #{error.class}: #{error.message}"
  end
end
