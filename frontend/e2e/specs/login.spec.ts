import { test } from '@playwright/test'
import { loginAsAdmin } from '../support/auth'
import { expectModernWmsShell } from '../support/test-system'

test('admin can login and load application shell', async ({ page }) => {
  await loginAsAdmin(page)
  await expectModernWmsShell(page)
})
