import { Locator, Page } from '@playwright/test'
import { PermissionMenuPath } from './permission-bootstrap'

type SelectorScope = Page | Locator

export function sidebarMenu(page: Page, menuPath: PermissionMenuPath | string) {
  return page.locator(`[data-menu-path="${menuPath}"]`)
}

export function topButton(scope: SelectorScope, authCode: string) {
  return scope.locator(`button[data-auth-code="${authCode}"]:visible`).first()
}

export function tabByLabel(scope: SelectorScope, label: string | RegExp) {
  return scope.getByRole('tab', { name: label })
}

export function rowButton(row: Locator, label: string) {
  return row.locator(`button[aria-label="${label}"]:visible`).first()
}

export function visibleButtonByLabel(scope: SelectorScope, label: string) {
  return scope.locator(`button[aria-label="${label}"]:visible`).first()
}

export function firstTableRow(scope: SelectorScope) {
  return scope.locator('.vxe-body--row').first()
}
