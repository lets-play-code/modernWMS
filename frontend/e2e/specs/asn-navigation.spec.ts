import { test } from '@playwright/test'
import { loginAsAdmin } from '../support/auth'
import { expectMenuAvailable, expectModernWmsShell } from '../support/test-system'

test('ASN menu is reachable after login', async ({ page }) => {
  await loginAsAdmin(page)
  await expectMenuAvailable(page, /Receiving Management|收货管理|收貨管理/i)
  await expectModernWmsShell(page)
})
