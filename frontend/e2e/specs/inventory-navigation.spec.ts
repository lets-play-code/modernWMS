import { test } from '@playwright/test'
import { loginAsAdmin } from '../support/auth'
import { expectMenuAvailable, expectModernWmsShell } from '../support/test-system'

test('inventory menu is reachable after login', async ({ page }) => {
  await loginAsAdmin(page)
  await expectMenuAvailable(page, /Stock Management|库存管理|庫存管理/i)
  await expectModernWmsShell(page)
})
