require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # System tests drive a real browser, so running one per core mostly buys
  # flakiness. Keep them serial.
  parallelize(workers: 1)

  driven_by :selenium, using: ENV["HEADFUL"].present? ? :chrome : :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    # Keep the browser console so a failure can be diagnosed from CI artifacts.
    options.add_option("goog:loggingPrefs", { browser: "ALL" })
    # Google Chrome on CI runners takes part in Google's field trials, so it
    # can behave differently from the Chromium on a developer machine. Turn
    # them off so both run the same browser.
    options.add_argument("--disable-field-trial-config")
  end

  # CI runners are slower than a laptop; the default 2 seconds makes
  # Turbo navigations look like failures.
  Capybara.default_max_wait_time = 5

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
  # Next to the failure screenshot, write what the browser knew: its console,
  # whether Turbo and Stimulus initialised, and the URL it was actually on.
  def after_teardown
    dump_browser_state if failed? && page.driver.respond_to?(:browser)
  ensure
    super
  end

  def dump_browser_state
    dir = Rails.root.join("tmp/screenshots")
    FileUtils.mkdir_p(dir)
    state = page.evaluate_script(<<~JS)
      ({
        url: location.href,
        readyState: document.readyState,
        turbo: typeof window.Turbo,
        stimulus: typeof window.Stimulus,
        stimulusControllers: window.Stimulus ? window.Stimulus.router.modulesByIdentifier.size : null,
        hasFocus: document.hasFocus(),
        visibility: document.visibilityState,
        serviceWorkerController: navigator.serviceWorker && navigator.serviceWorker.controller ? navigator.serviceWorker.controller.state : null,
        navigations: performance.getEntriesByType("navigation").map(n => ({ type: n.type, start: n.startTime, domContentLoaded: n.domContentLoadedEventEnd, load: n.loadEventEnd })),
        now: performance.now(),
        trace: window.__trace || null,
        scripts: Array.from(document.scripts).map(s => s.src || "(inline)")
      })
    JS
    console = page.driver.browser.logs.get(:browser).map { |e| "#{e.level} #{e.message}" }
    File.write(dir.join("#{method_name}.browser.txt"), [ JSON.pretty_generate(state), *console ].join("\n"))
  rescue => e
    warn "Could not dump browser state: #{e.class}: #{e.message}"
  end

  def sign_in_as(user, password: "password", keep_flash: false)
    visit new_user_session_path
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: password
    click_button I18n.t("login_page.sign_in")
    assert_no_current_path new_user_session_path, wait: 5
    # Turbo pushes the new URL before it has rendered the response. Navigating
    # again at that point races the in-flight visit: the browser can hand the
    # test the old document, and everything typed or clicked there is lost when
    # the new one lands. Let Turbo settle first.
    wait_for_turbo
    reload_page unless keep_flash
  end

  # Navigating to the URL the browser is already on is a reload, and Selenium
  # returns from it before the new document has finished loading. Anything the
  # test types or clicks in the meantime is lost: Chrome restores the old
  # document's (empty) form state at the end of parsing, and the deferred
  # application script has not attached Turbo or Stimulus yet. Mark the current
  # document, reload, and wait until the new document is complete.
  def reload_page
    execute_script("document.documentElement.setAttribute('data-stale-document', '')")
    visit current_path
    assert_no_selector "html[data-stale-document]", wait: 10
    page.document.synchronize(10) do
      unless evaluate_script("document.readyState === 'complete' && typeof window.Turbo === 'object'")
        raise Capybara::ElementNotFound, "the reloaded page has not finished loading"
      end
    end
    # Input sent before the new document has produced a frame was seen to be
    # dropped by the browser without any error. Wait for two rendered frames.
    evaluate_async_script("const done = arguments[0]; requestAnimationFrame(() => requestAnimationFrame(() => done(true)))")
    start_browser_trace
  end

  # Records what happens in the page after the test takes over: focus moves,
  # input, form resets, Turbo lifecycle events and body-level DOM replacement.
  # Dumped with the browser state on failure.
  def start_browser_trace
    execute_script(<<~JS)
      window.__trace = [];
      const log = (kind, detail) => window.__trace.push([Math.round(performance.now()), kind, detail]);
      const describe = (el) => el && el.tagName ? `${el.tagName}#${el.id}[name=${el.getAttribute && el.getAttribute("name")}]` : String(el);
      ["focusin", "focusout", "input", "change", "reset", "submit", "click"].forEach(type =>
        document.addEventListener(type, e => log(type, describe(e.target) + (type === "input" ? ` value=${JSON.stringify(e.target.value)}` : "")), true));
      ["turbo:visit", "turbo:before-render", "turbo:render", "turbo:load", "turbo:before-cache", "turbo:before-fetch-request", "turbo:frame-render", "turbo:morph", "popstate", "pageshow", "pagehide", "visibilitychange"].forEach(type =>
        (type.startsWith("turbo") || type === "popstate" ? document : window).addEventListener(type, e => log(type, e.detail && e.detail.url ? e.detail.url : "")));
      new MutationObserver(records => records.forEach(r => {
        if (r.target === document.documentElement || r.target === document.body || r.target.tagName === "FORM") {
          log("mutation", `${describe(r.target)} +${[...r.addedNodes].map(describe)} -${[...r.removedNodes].map(describe)}`);
        }
      })).observe(document.documentElement, { childList: true, subtree: true });
      log("trace-start", location.href);
    JS
  end

  # Turbo marks <html> (visits) and the submitted <form> (submissions) with
  # aria-busy for as long as it is fetching and rendering.
  def wait_for_turbo
    assert_no_selector "html[aria-busy], form[aria-busy]", wait: 5
  end
end
