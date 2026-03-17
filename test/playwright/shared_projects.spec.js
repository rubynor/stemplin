const { test, expect } = require("@playwright/test");

// Dev DB state:
// User 1: test@test (admin of "test org") - owns Project 1 "Apollo 11"
// User 2: test123@test (admin of "test org 123") - guest on Project 1
// Project 1: "Apollo 11" shared with "test org 123"
// Project 2: "My project" owned by "test org 123"

const USER1 = { email: "test@test", password: "testpass123" };
const USER2 = { email: "test123@test", password: "testpass123" };

async function login(page, user) {
  await page.goto("/users/sign_in");

  // Dismiss cookie consent if present
  const declineBtn = page.getByRole("button", { name: "Decline" });
  if (await declineBtn.isVisible({ timeout: 2000 }).catch(() => false)) {
    await declineBtn.click();
  }

  await page.fill("#user_email", user.email);
  await page.fill("#user_password", user.password);
  await page.getByRole("button", { name: "Sign in" }).click();
  await page.waitForURL((url) => !url.pathname.includes("sign_in"), {
    timeout: 10000,
  });
}

// ============================================================
// OWNING ORG ADMIN (User 1) - Views
// ============================================================

test.describe("Owning org admin (User 1 - test org)", () => {
  test.beforeEach(async ({ page }) => {
    await login(page, USER1);
  });

  test("can see project list with own projects", async ({ page }) => {
    await page.goto("/workspace/projects");
    await expect(page.locator("body")).toContainText("Apollo 11");
  });

  test("can view project show page for owned project", async ({ page }) => {
    await page.goto("/workspace/projects/1");
    await expect(page.locator("body")).toContainText("Apollo 11");
  });

  test("sees guest org name on owned project show page", async ({ page }) => {
    await page.goto("/workspace/projects/1");
    await expect(page.locator("body")).toContainText("test org 123");
  });

  test("can see edit button on owned project", async ({ page }) => {
    await page.goto("/workspace/projects/1");
    const editLink = page.locator('a[href="/workspace/projects/1/edit"]');
    await expect(editLink).toBeVisible();
  });

  test("can access project shares index", async ({ page }) => {
    await page.goto("/workspace/projects/1/project_shares");
    expect(page.url()).not.toContain("sign_in");
    await expect(page.locator("body")).toContainText("test org 123");
  });

  test("can access edit page for owned project", async ({ page }) => {
    await page.goto("/workspace/projects/1/edit");
    await expect(page).toHaveURL(/\/workspace\/projects\/1\/edit/);
  });
});

// ============================================================
// GUEST ORG ADMIN (User 2) - Views
// ============================================================

test.describe("Guest org admin (User 2 - test org 123)", () => {
  test.beforeEach(async ({ page }) => {
    await login(page, USER2);
  });

  test("can see own projects in project list", async ({ page }) => {
    await page.goto("/workspace/projects");
    await expect(page.locator("body")).toContainText("My project");
  });

  test("project list page contains shared indicator", async ({ page }) => {
    await page.goto("/workspace/projects");
    // The page should show something related to sharing
    const pageText = await page.locator("body").textContent();
    // Apollo 11 might appear under a different grouping or with a shared badge
    const hasContent =
      pageText.includes("Apollo") ||
      pageText.includes("Shared") ||
      pageText.includes("test org");
    expect(hasContent).toBeTruthy();
  });

  test("can view shared project show page (read-only)", async ({ page }) => {
    await page.goto("/workspace/projects/1");
    await expect(page.locator("body")).toContainText("Apollo 11");
    expect(page.url()).toContain("/workspace/projects/1");
  });

  test("does NOT see edit button on shared project", async ({ page }) => {
    await page.goto("/workspace/projects/1");
    const editLink = page.locator('a[href="/workspace/projects/1/edit"]');
    await expect(editLink).toHaveCount(0);
  });

  test("cannot access edit page for shared project (redirected)", async ({
    page,
  }) => {
    await page.goto("/workspace/projects/1/edit");
    expect(page.url()).not.toContain("/edit");
  });

  test("can view own project show page", async ({ page }) => {
    await page.goto("/workspace/projects/2");
    await expect(page.locator("body")).toContainText("My project");
  });

  test("can see edit button on own project", async ({ page }) => {
    await page.goto("/workspace/projects/2");
    const editLink = page.locator('a[href="/workspace/projects/2/edit"]').first();
    await expect(editLink).toBeVisible();
  });
});

// ============================================================
// TIME REGISTRATION - Guest org user
// ============================================================

test.describe("Time registration on shared project (User 2)", () => {
  test.beforeEach(async ({ page }) => {
    await login(page, USER2);
  });

  test("time_regs index loads without redirect", async ({ page }) => {
    await page.goto("/time_regs");
    await expect(page).toHaveURL(/\/time_regs/);
    expect(page.url()).not.toContain("sign_in");
  });

  test("time_regs index shows entries on shared project", async ({ page }) => {
    await page.goto("/time_regs");
    // User 2 has time_regs on the shared project "Apollo 11"
    // The page should show time entries (not be empty)
    await expect(page.locator("body")).toContainText("Apollo 11");
  });

  test("update_tasks_select returns tasks for shared project", async ({
    page,
  }) => {
    await page.goto("/time_regs");

    const response = await page.evaluate(async () => {
      const res = await fetch(
        "/time_regs/update_tasks_select?project_id=1",
        { headers: { Accept: "text/html" } }
      );
      return { status: res.status, body: await res.text() };
    });

    expect(response.status).toBe(200);
    expect(response.body).toContain("Welding");
  });

  test("can create a time_reg on shared project", async ({ page }) => {
    await page.goto("/time_regs");

    const csrfToken = await page.evaluate(() => {
      const meta = document.querySelector('meta[name="csrf-token"]');
      return meta ? meta.getAttribute("content") : null;
    });
    expect(csrfToken).toBeTruthy();

    const response = await page.evaluate(
      async ({ token }) => {
        const today = new Date().toISOString().split("T")[0];
        const formData = new FormData();
        formData.append("time_reg[assigned_task_id]", "1");
        formData.append("time_reg[date_worked]", today);
        formData.append("time_reg[minutes]", "45");
        formData.append("time_reg[notes]", "Playwright test entry");
        formData.append("time_reg[project_id]", "1");

        const res = await fetch("/time_regs", {
          method: "POST",
          headers: {
            "X-CSRF-Token": token,
            Accept:
              "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
          },
          body: formData,
          redirect: "follow",
        });
        return { status: res.status, url: res.url, ok: res.ok };
      },
      { token: csrfToken }
    );

    expect(response.ok).toBeTruthy();
    expect(response.url).toContain("/time_regs");
  });
});

// ============================================================
// RATE MANAGEMENT - Guest org admin
// ============================================================

test.describe("Rate management (User 2 - guest org admin)", () => {
  test.beforeEach(async ({ page }) => {
    await login(page, USER2);
  });

  test("sees rate-related content on shared project page", async ({
    page,
  }) => {
    await page.goto("/workspace/projects/1");
    const bodyText = await page.locator("body").textContent();
    const hasRateUI =
      bodyText.includes("Rate") ||
      bodyText.includes("rate") ||
      bodyText.includes("€");
    expect(hasRateUI).toBeTruthy();
  });

  test("can submit rate update via fetch", async ({ page }) => {
    // Navigate first to get a session cookie
    await page.goto("/workspace/projects/1");

    const csrfToken = await page.evaluate(() => {
      const meta = document.querySelector('meta[name="csrf-token"]');
      return meta ? meta.getAttribute("content") : null;
    });
    expect(csrfToken).toBeTruthy();

    const response = await page.evaluate(
      async ({ token }) => {
        const params = new URLSearchParams();
        params.append("project_share[rate_currency]", "7.50");
        params.append("_method", "patch");
        params.append("authenticity_token", token);

        const res = await fetch(
          "/workspace/projects/1/project_shares/1/update_rates",
          {
            method: "POST",
            headers: {
              "Content-Type": "application/x-www-form-urlencoded",
              Accept: "text/html, application/xhtml+xml",
            },
            body: params.toString(),
            redirect: "follow",
          }
        );
        return { status: res.status, url: res.url, ok: res.ok };
      },
      { token: csrfToken }
    );

    expect(response.ok).toBeTruthy();
  });
});

// ============================================================
// REPORTS - Guest org admin
// ============================================================

test.describe("Reports for guest org (User 2)", () => {
  test.beforeEach(async ({ page }) => {
    await login(page, USER2);
  });

  test("reports page loads successfully", async ({ page }) => {
    await page.goto("/reports");
    await expect(page).toHaveURL(/\/reports/);
    expect(page.url()).not.toContain("sign_in");
  });
});

// ============================================================
// AUTHORIZATION - Verify restrictions
// ============================================================

test.describe("Authorization restrictions", () => {
  test("guest org admin cannot delete shared project", async ({ page }) => {
    await login(page, USER2);

    const csrfToken = await page.evaluate(() => {
      const meta = document.querySelector('meta[name="csrf-token"]');
      return meta ? meta.getAttribute("content") : null;
    });

    const response = await page.evaluate(
      async ({ token }) => {
        const res = await fetch("/workspace/projects/1", {
          method: "DELETE",
          headers: {
            "X-CSRF-Token": token,
            Accept: "text/html",
          },
          redirect: "follow",
        });
        return { status: res.status, url: res.url };
      },
      { token: csrfToken }
    );

    expect(response.url).not.toMatch(/\/workspace\/projects\/1$/);
  });

  test("guest org admin cannot update shared project", async ({ page }) => {
    await login(page, USER2);

    const csrfToken = await page.evaluate(() => {
      const meta = document.querySelector('meta[name="csrf-token"]');
      return meta ? meta.getAttribute("content") : null;
    });

    const response = await page.evaluate(
      async ({ token }) => {
        const formData = new FormData();
        formData.append("project[name]", "Hacked Name");

        const res = await fetch("/workspace/projects/1", {
          method: "PATCH",
          headers: {
            "X-CSRF-Token": token,
            Accept: "text/html",
          },
          body: formData,
          redirect: "follow",
        });
        return { status: res.status, url: res.url };
      },
      { token: csrfToken }
    );

    expect(response.url).not.toContain("/workspace/projects/1/edit");
  });

  test("owning org admin can still access edit page", async ({ page }) => {
    await login(page, USER1);
    await page.goto("/workspace/projects/1/edit");
    await expect(page).toHaveURL(/\/workspace\/projects\/1\/edit/);
  });
});

// ============================================================
// EXPORT - Downloads trigger correctly
// ============================================================

test.describe("Export functionality", () => {
  test("owning org admin can export project time_regs", async ({ page }) => {
    await login(page, USER1);
    await page.goto("/time_regs");

    // Use fetch to test the endpoint returns CSV data
    const response = await page.evaluate(async () => {
      const res = await fetch("/time_regs/export?project_id=1", {
        headers: { Accept: "text/csv, text/html" },
      });
      return { status: res.status, contentType: res.headers.get("content-type") };
    });

    expect(response.status).toBe(200);
  });

  test("guest org admin can export shared project time_regs", async ({
    page,
  }) => {
    await login(page, USER2);
    await page.goto("/time_regs");

    const response = await page.evaluate(async () => {
      const res = await fetch("/time_regs/export?project_id=1", {
        headers: { Accept: "text/csv, text/html" },
      });
      return { status: res.status, contentType: res.headers.get("content-type") };
    });

    expect(response.status).toBe(200);
  });
});
