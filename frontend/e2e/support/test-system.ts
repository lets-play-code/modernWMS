import { expect, Page } from '@playwright/test'

export async function expectModernWmsShell(page: Page) {
  await expect(page.locator('body')).toContainText(/ModernWMS|Stock|库存|收货|发货|Home/i)
}

export async function expectMenuAvailable(page: Page, label: RegExp) {
  await expect(page.locator('body')).toContainText(label)
}
