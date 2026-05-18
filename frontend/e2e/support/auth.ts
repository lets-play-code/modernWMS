import { expect, Page } from '@playwright/test'

export async function loginAsAdmin(page: Page) {
  await page.addInitScript(() => localStorage.setItem('language', 'en'))
  await page.goto('/#/login')
  await page.getByLabel(/UserName|用户名|用戶名/i).fill('admin')
  await page.locator('input[type="password"]').fill('1')
  await page.getByRole('button', { name: /Login|登录|登入/i }).click()
  await expect(page).not.toHaveURL(/#\/login/)
}
