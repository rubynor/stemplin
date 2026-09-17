require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # System tests drive a real browser, so running one per core mostly buys
  # flakiness. Keep them serial.
  parallelize(workers: 1)

  driven_by :selenium, using: ENV["HEADFUL"].present? ? :chrome : :headless_chrome, screen_size: [ 1400, 1400 ]

  # Linux distributions ship Chromium rather than Chrome. Selenium looks for
  # Chrome by default, so point it at whatever browser is actually installed.
  if (browser = ENV["CHROME_BIN"] || %w[/usr/bin/chromium /usr/bin/chromium-browser].find { |path| File.executable?(path) })
    Selenium::WebDriver::Chrome.path = browser
  end

  # Signs in through the form, the way a user does, so the session cookie and
  # Warden are exercised rather than stubbed.
  # `keep_flash: true` leaves the "Signed in successfully" snackbar on screen.
  # It is dismissed by default because it floats over the top-right buttons and
  # swallows clicks meant for them.
  def sign_in_as(user, password: "password", keep_flash: false)
    visit new_user_session_path
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: password
    click_button I18n.t("login_page.sign_in")
    assert_no_current_path new_user_session_path, wait: 5
    visit current_path unless keep_flash
  end
end
