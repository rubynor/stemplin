import * as Sentry from "@sentry/browser"

// Reports browser errors to Sentry. The sentry-* meta tags only exist where the
// server reports too (see SentryHelper), so elsewhere this does nothing.
const meta = (name) => document.querySelector(`meta[name="sentry-${name}"]`)?.content

// A broken render loop throws on every animation frame; a handful is plenty.
const MAX_EVENTS_PER_PAGE_LOAD = 20
let sent = 0

// Only report errors thrown from our own bundles (application.js, plan.js). This
// drops extensions, third-party snippets and errors without a stack. The last
// frame is where it was thrown; earlier ones may be Sentry's own timer wrappers.
const fromOurBundles = (event) =>
  (event.exception?.values || []).some((exception) => {
    const frames = exception.stacktrace?.frames || []
    return frames[frames.length - 1]?.filename?.startsWith(`${window.location.origin}/assets/`)
  })

const dsn = meta("dsn")
if (dsn) {
  Sentry.init({
    dsn,
    environment: meta("environment"),
    release: meta("release"),
    // Flaky connections and requests cut short by navigating away; nothing to fix.
    ignoreErrors: [/^Failed to fetch/, /^NetworkError/, /^Load failed/, /aborted/i],
    beforeSend(event) {
      if (!fromOurBundles(event)) return null
      if (++sent > MAX_EVENTS_PER_PAGE_LOAD) return null

      // Turbo swaps the meta tags on every visit, so read them per event.
      const userId = meta("user-id")
      if (userId) event.user = { id: userId }
      event.tags = { ...event.tags, organization_id: meta("organization-id") }
      return event
    }
  })
}
