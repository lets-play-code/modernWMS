import { test } from '@playwright/test'
import { loginAsUser } from '../../support/auth'
import { ensureBusinessBundle } from '../../support/business-bundles'
import { expectControlDisabled, expectControlEnabled } from '../../support/permission-assertions'
import { ensurePermissionBootstrap, PermissionBootstrap } from '../../support/permission-bootstrap'
import { tabByLabel, topButton } from '../../support/selectors'

interface PageConfig {
  menuPath: 'stockManagement' | 'saftyStock' | 'asnStatistic' | 'deliveryStatistic' | 'stockageStatistic'
  tabLabel?: RegExp
  topButtons: string[]
}

const PAGE_CONFIGS: PageConfig[] = [
  {
    menuPath: 'stockManagement',
    tabLabel: /Stock Location/i,
    topButtons: ['stock-export', 'stock-exportAll']
  },
  {
    menuPath: 'stockManagement',
    tabLabel: /^Stock$/i,
    topButtons: ['area-export', 'area-exportAll']
  },
  {
    menuPath: 'saftyStock',
    topButtons: ['export', 'exportAll']
  },
  {
    menuPath: 'asnStatistic',
    topButtons: ['export', 'exportAll']
  },
  {
    menuPath: 'deliveryStatistic',
    topButtons: ['exportAll']
  },
  {
    menuPath: 'stockageStatistic',
    topButtons: ['export', 'exportAll']
  }
]

test.describe.configure({ mode: 'serial' })

test.describe('inventory and statistics permissions', () => {
  let bootstrap: PermissionBootstrap

  test.beforeAll(async () => {
    await ensureBusinessBundle('stock-and-statistics-bundle')
    bootstrap = await ensurePermissionBootstrap(['stockAnalyst', 'auditor'])
  })

  test('stock analyst can use the approved inventory and statistics controls', async ({ page }) => {
    await loginAsUser(page, bootstrap.credentialsByRole.stockAnalyst)
    await assertPagePermissions(page, 'enabled')
  })

  test('auditor can see inventory and statistics controls but cannot use them', async ({ page }) => {
    await loginAsUser(page, bootstrap.credentialsByRole.auditor)
    await assertPagePermissions(page, 'disabled')
  })
})

async function assertPagePermissions(page, state: 'enabled' | 'disabled') {
  for (const config of PAGE_CONFIGS) {
    await page.goto(`/#/${config.menuPath}`)
    await openTabIfNeeded(page, config.tabLabel)
    await assertTopButtons(page, config.topButtons, state)
  }
}

async function openTabIfNeeded(page, tabLabel?: RegExp) {
  if (!tabLabel) {
    return
  }

  await tabByLabel(page, tabLabel).click()
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
