import { expect, Page } from '@playwright/test'

export interface LoginCredentials {
  userNum: string
  password: string
}

export async function loginAsAdmin(page: Page) {
  await loginAsUser(page, {
    userNum: 'admin',
    password: '1'
  })
}

export async function loginAsUser(page: Page, credentials: LoginCredentials) {
  await page.addInitScript(() => localStorage.setItem('language', 'en'))
  await page.goto('/#/login')
  await page.getByLabel(/UserName|用户名|用戶名/i).fill(credentials.userNum)
  await page.locator('input[type="password"]').fill(credentials.password)
  await page.getByRole('button', { name: /Login|登录|登入/i }).click()
  await expect(page).not.toHaveURL(/#\/login/)
}
