import { test } from '@playwright/test'
import { loginAsUser } from '../../support/auth'
import { ensureBusinessBundle } from '../../support/business-bundles'
import { expectControlDisabled, expectControlEnabled } from '../../support/permission-assertions'
import { ensurePermissionBootstrap, PermissionBootstrap } from '../../support/permission-bootstrap'
import { topButton, visibleButtonByLabel } from '../../support/selectors'

interface PageConfig {
  menuPath: 'companySetting' | 'userRoleSetting' | 'userManagement' | 'print'
  topButtons: string[]
  rowButtons: string[]
}

const PAGE_CONFIGS: PageConfig[] = [
  {
    menuPath: 'companySetting',
    topButtons: ['save', 'export'],
    rowButtons: ['Delete']
  },
  {
    menuPath: 'userRoleSetting',
    topButtons: ['save', 'export'],
    rowButtons: ['Delete']
  },
  {
    menuPath: 'userManagement',
    topButtons: ['save', 'import', 'export', 'exportAll', 'resetPwd'],
    rowButtons: ['Delete']
  },
  {
    menuPath: 'print',
    topButtons: ['save', 'export', 'exportAll'],
    rowButtons: ['Delete']
  }
]

test.describe.configure({ mode: 'serial' })

test.describe('system management permissions', () => {
  let bootstrap: PermissionBootstrap

  test.beforeAll(async () => {
    await ensureBusinessBundle('system-and-masterdata-baseline')
    bootstrap = await ensurePermissionBootstrap(['systemAdmin', 'auditor'])
  })

  test('system admin can use the approved system-management controls', async ({ page }) => {
    await loginAsUser(page, bootstrap.credentialsByRole.systemAdmin)
    await assertPagePermissions(page, 'enabled')
  })

  test('auditor can see system-management controls but cannot use them', async ({ page }) => {
    await loginAsUser(page, bootstrap.credentialsByRole.auditor)
    await assertPagePermissions(page, 'disabled')
  })
})

async function assertPagePermissions(page, state: 'enabled' | 'disabled') {
  for (const config of PAGE_CONFIGS) {
    await page.goto(`/#/${config.menuPath}`)
    await assertTopButtons(page, config.topButtons, state)
    await assertRowButtons(page, config.rowButtons, state)
  }
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
    const control = visibleButtonByLabel(page, label)
    if (state === 'enabled') {
      await expectControlEnabled(control)
      continue
    }
    await expectControlDisabled(control)
  }
}
