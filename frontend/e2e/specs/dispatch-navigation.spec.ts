import { test } from '@playwright/test'
import { loginAsAdmin } from '../support/auth'
import { expectMenuAvailable, expectModernWmsShell } from '../support/test-system'

test('dispatch menu is reachable after login', async ({ page }) => {
  await loginAsAdmin(page)
  await expectMenuAvailable(page, /Delivery Management|发货管理|發貨管理/i)
  await expectModernWmsShell(page)
})
