import { test } from '@playwright/test'
import { loginAsUser } from '../../support/auth'
import { ensureBusinessBundle } from '../../support/business-bundles'
import { expectControlDisabled, expectControlEnabled } from '../../support/permission-assertions'
import { ensurePermissionBootstrap, PermissionBootstrap } from '../../support/permission-bootstrap'
import { topButton } from '../../support/selectors'

interface PageConfig {
  menuPath: 'warehouseProcessing' | 'warehouseMove' | 'warehouseFreeze' | 'warehouseAdjust' | 'warehouseTaking'
  topButtons: string[]
  rowButtons: string[]
}

const PAGE_CONFIGS: PageConfig[] = [
  {
    menuPath: 'warehouseProcessing',
    topButtons: ['split', 'group', 'export', 'exportAll'],
    rowButtons: ['Confirm Process', 'Confirm Adjust', 'Delete']
  },
  {
    menuPath: 'warehouseMove',
    topButtons: ['save', 'export', 'exportAll'],
    rowButtons: ['Confirm Move', 'Delete']
  },
  {
    menuPath: 'warehouseFreeze',
    topButtons: ['freeze', 'unfreeze', 'export', 'exportAll'],
    rowButtons: []
  },
  {
    menuPath: 'warehouseAdjust',
    topButtons: ['export', 'exportAll'],
    rowButtons: []
  },
  {
    menuPath: 'warehouseTaking',
    topButtons: ['save', 'export', 'exportAll'],
    rowButtons: ['Confirm Taking', 'Confirm Adjust', 'Delete']
  }
]

test.describe.configure({ mode: 'serial' })

test.describe('internal operations permissions', () => {
  let bootstrap: PermissionBootstrap

  test.beforeAll(async () => {
    await ensureBusinessBundle('internal-operations-bundle')
    bootstrap = await ensurePermissionBootstrap(['internalOperator', 'auditor'])
  })

  for (const config of PAGE_CONFIGS) {
    test(`internal operator can use controls on ${config.menuPath}`, async ({ page }) => {
      await loginAsUser(page, bootstrap.credentialsByRole.internalOperator)
      await openInternalOperationsPage(page, config.menuPath)
      await assertTopButtons(page, config.topButtons, 'enabled')
      await assertRowButtons(page, config.rowButtons, 'enabled')
    })

    test(`auditor sees disabled controls on ${config.menuPath}`, async ({ page }) => {
      await loginAsUser(page, bootstrap.credentialsByRole.auditor)
      await openInternalOperationsPage(page, config.menuPath)
      await assertTopButtons(page, config.topButtons, 'disabled')
      await assertRowButtons(page, config.rowButtons, 'disabled')
    })
  }
})

async function openInternalOperationsPage(page, menuPath: PageConfig['menuPath']) {
  await page.goto(`/#/${menuPath}`)
  await page.locator('button[aria-label="Refresh"]:visible').first().click({ force: true })
  await page.waitForTimeout(800)
}

async function assertTopButtons(page, authCodes: string[], state: 'enabled' | 'disabled') {
  for (const authCode of authCodes) {
    const control = topButton(page, authCode)
    if (state === 'enabled') {
      await expectControlEnabled(control)
      continue
    }
    await expectControlDisabled(control)
  }
}

async function assertRowButtons(page, labels: string[], state: 'enabled' | 'disabled') {
  for (const label of labels) {
    const control =
      state === 'enabled'
        ? page.locator(`button[aria-label="${label}"]:visible:not([disabled])`).first()
        : page.locator(`button[aria-label="${label}"]:visible[disabled]`).first()

    if (state === 'enabled') {
      await expectControlEnabled(control)
      continue
    }
    await expectControlDisabled(control)
  }
}
