import * as Sentry from "@sentry/browser"

// Reports browser errors to Sentry. The sentry-* meta tags only exist where the
// server reports too (see SentryHelper), so elsewhere this does nothing.
const meta = (name) => document.querySelector(`meta[name="sentry-${name}"]`)?.content

// A broken render loop throws on every animation frame; a handful is plenty.
const MAX_EVENTS_PER_PAGE_LOAD = 20
let sent = 0

const dsn = meta("dsn")
if (dsn) {
  Sentry.init({
    dsn,
    environment: meta("environment"),
    release: meta("release"),
    // Only our own bundles, not browser extensions or third-party trackers.
    allowUrls: [window.location.origin],
    beforeSend(event) {
      if (++sent > MAX_EVENTS_PER_PAGE_LOAD) return null

      // Turbo swaps the meta tags on every visit, so read them per event.
      const userId = meta("user-id")
      if (userId) event.user = { id: userId }
      event.tags = { ...event.tags, organization_id: meta("organization-id") }
      return event
    }
  })
}
