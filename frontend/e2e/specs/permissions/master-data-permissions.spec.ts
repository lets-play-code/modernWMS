import { Page, test } from '@playwright/test'
import { loginAsUser } from '../../support/auth'
import { ensureBusinessBundle } from '../../support/business-bundles'
import { expectControlDisabled, expectControlEnabled } from '../../support/permission-assertions'
import { ensurePermissionBootstrap, PermissionBootstrap } from '../../support/permission-bootstrap'
import { tabByLabel, topButton, visibleButtonByLabel } from '../../support/selectors'

interface PageConfig {
  menuPath:
    | 'commodityCategorySetting'
    | 'commodityManagement'
    | 'supplier'
    | 'warehouseSetting'
    | 'ownerOfCargo'
    | 'freightSetting'
    | 'customer'
  tabLabel?: RegExp
  topButtons: string[]
  rowButtons: string[]
  beforeAssert?: (page: Page) => Promise<void>
}

const PAGE_CONFIGS: PageConfig[] = [
  {
    menuPath: 'commodityCategorySetting',
    topButtons: ['save', 'export'],
    rowButtons: ['Delete']
  },
  {
    menuPath: 'commodityManagement',
    topButtons: ['save', 'export', 'printQrCode', 'printBarCode', 'import', 'exportAll'],
    rowButtons: ['Delete', 'Safety stock'],
    beforeAssert: async (page) => {
      await page.locator('.vxe-tree--btn-wrapper').first().click()
    }
  },
  {
    menuPath: 'supplier',
    topButtons: ['save', 'import', 'export', 'exportAll'],
    rowButtons: ['Delete']
  },
  {
    menuPath: 'warehouseSetting',
    tabLabel: /Warehouse Setting/i,
    topButtons: ['warehouse-save', 'warehouse-import', 'warehouse-export', 'warehouse-exportAll'],
    rowButtons: ['Delete']
  },
  {
    menuPath: 'warehouseSetting',
    tabLabel: /Reservoir Setting/i,
    topButtons: ['area-save', 'area-export', 'area-exportAll'],
    rowButtons: ['Delete']
  },
  {
    menuPath: 'warehouseSetting',
    tabLabel: /Location Setting/i,
    topButtons: ['location-save', 'location-export', 'location-exportAll', 'location-printQrCode', 'location-printBarCode'],
    rowButtons: ['Delete']
  },
  {
    menuPath: 'ownerOfCargo',
    topButtons: ['save', 'import', 'export', 'exportAll'],
    rowButtons: ['Delete']
  },
  {
    menuPath: 'freightSetting',
    topButtons: ['save', 'import', 'export', 'exportAll'],
    rowButtons: ['Delete']
  },
  {
    menuPath: 'customer',
    topButtons: ['save', 'import', 'export', 'exportAll'],
    rowButtons: ['Delete']
  }
]

test.describe.configure({ mode: 'serial' })

test.describe('master data permissions', () => {
  let bootstrap: PermissionBootstrap

  test.beforeAll(async () => {
    await ensureBusinessBundle('system-and-masterdata-baseline')
    bootstrap = await ensurePermissionBootstrap(['masterDataAdmin', 'auditor'])
  })

  test('master data admin can use the approved master-data controls', async ({ page }) => {
    await loginAsUser(page, bootstrap.credentialsByRole.masterDataAdmin)
    await assertPagePermissions(page, 'enabled')
  })

  test('auditor can see master-data controls but cannot use them', async ({ page }) => {
    await loginAsUser(page, bootstrap.credentialsByRole.auditor)
    await assertPagePermissions(page, 'disabled')
  })
})

async function assertPagePermissions(page, state: 'enabled' | 'disabled') {
  for (const config of PAGE_CONFIGS) {
    await page.goto(`/#/${config.menuPath}`)
    await openTabIfNeeded(page, config.tabLabel)
    if (config.beforeAssert) {
      await config.beforeAssert(page)
    }
    await assertTopButtons(page, config.topButtons, state)
    await assertRowButtons(page, config.rowButtons, state)
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
