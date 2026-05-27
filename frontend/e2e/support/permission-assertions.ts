import { expect, Locator, Page } from '@playwright/test'
import { PermissionMenuPath } from './permission-bootstrap'
import { sidebarMenu } from './selectors'

export async function expectSidebarMenuPresent(page: Page, menuPath: PermissionMenuPath | string) {
  await expect(sidebarMenu(page, menuPath)).toHaveCount(1)
}

export async function expectSidebarMenuAbsent(page: Page, menuPath: PermissionMenuPath | string) {
  await expect(sidebarMenu(page, menuPath)).toHaveCount(0)
}

export async function expectControlEnabled(control: Locator) {
  await expect(control).toBeVisible()
  await expect(control).toBeEnabled()
}

export async function expectControlDisabled(control: Locator) {
  await expect(control).toBeVisible()
  await expect(control).toBeDisabled()
}
