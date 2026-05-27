import { test } from '@playwright/test'
import { loginAsUser } from '../../support/auth'
import { ensureBusinessBundle } from '../../support/business-bundles'
import { expectControlDisabled, expectControlEnabled } from '../../support/permission-assertions'
import { ensurePermissionBootstrap, PermissionBootstrap } from '../../support/permission-bootstrap'
import { tabByLabel, topButton } from '../../support/selectors'

interface RowActionConfig {
  dispatchNo: string
  label: string
}

interface TabConfig {
  tabLabel: RegExp
  topButtons: string[]
  rowActions: RowActionConfig[]
}

const TAB_CONFIGS: TabConfig[] = [
  {
    tabLabel: /^Invoice$/i,
    topButtons: ['invoice-save', 'invoice-export', 'invoice-exportAll', 'invoice-printQrCode'],
    rowActions: [
      { dispatchNo: 'DP-E2E-001', label: 'Confirm Shipment Doc' },
      { dispatchNo: 'DP-TRAIN-001', label: 'Confirm Picking' },
      { dispatchNo: 'DP-TRAIN-001', label: 'Recall to previous process' },
      { dispatchNo: 'DP-DEMO-PICKED-001', label: 'Recall to previous process' },
      { dispatchNo: 'DP-E2E-001', label: 'Delete' }
    ]
  },
  {
    tabLabel: /Pre Shipment/i,
    topButtons: ['invoice-export', 'invoice-exportAll'],
    rowActions: []
  },
  {
    tabLabel: /New Shipment/i,
    topButtons: ['invoice-export', 'invoice-exportAll'],
    rowActions: []
  },
  {
    tabLabel: /To Be Picked/i,
    topButtons: ['picked-export', 'picked-exportAll'],
    rowActions: []
  },
  {
    tabLabel: /^Picked$/i,
    topButtons: ['picked-export', 'picked-exportAll'],
    rowActions: []
  },
  {
    tabLabel: /^Packaged$/i,
    topButtons: ['packaged-export', 'packaged-exportAll', 'packaged-package'],
    rowActions: [{ dispatchNo: 'DP-DEMO-PACKAGED-001', label: 'Recall to previous process' }]
  },
  {
    tabLabel: /^Weighed$/i,
    topButtons: ['weighed-export', 'weighed-exportAll', 'weighed-weigh'],
    rowActions: [{ dispatchNo: 'DP-DEMO-WEIGHED-001', label: 'Recall to previous process' }]
  },
  {
    tabLabel: /^Delivered$/i,
    topButtons: ['delivered-export', 'delivered-exportAll', 'delivered-delivery', 'delivered-setCarrier', 'delivered-signIn'],
    rowActions: []
  },
  {
    tabLabel: /^Signed In$/i,
    topButtons: ['signedIn-export', 'signedIn-exportAll'],
    rowActions: []
  }
]

test.describe.configure({ mode: 'serial' })

test.describe('outbound fulfillment permissions', () => {
  let bootstrap: PermissionBootstrap

  test.beforeAll(async () => {
    await ensureBusinessBundle('dispatch-workbench-bundle')
    bootstrap = await ensurePermissionBootstrap(['outboundOperator', 'auditor'])
  })

  for (const config of TAB_CONFIGS) {
    test(`outbound operator can use controls on ${config.tabLabel}`, async ({ page }) => {
      await loginAsUser(page, bootstrap.credentialsByRole.outboundOperator)
      await openOutboundTab(page, config.tabLabel)
      await assertTopButtons(page, config.topButtons, 'enabled')
      await assertRowActions(page, config.rowActions, 'enabled')
    })

    test(`auditor sees disabled controls on ${config.tabLabel}`, async ({ page }) => {
      await loginAsUser(page, bootstrap.credentialsByRole.auditor)
      await openOutboundTab(page, config.tabLabel)
      await assertTopButtons(page, config.topButtons, 'disabled')
      await assertRowActions(page, config.rowActions, 'disabled')
    })
  }
})

async function openOutboundTab(page, tabLabel: RegExp) {
  await page.goto('/#/deliveryManagement')
  await tabByLabel(page, tabLabel).click()
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

async function assertRowActions(page, rowActions: RowActionConfig[], state: 'enabled' | 'disabled') {
  for (const rowAction of rowActions) {
    const row = page.getByRole('row', { name: new RegExp(rowAction.dispatchNo) }).first()
    const control = row.getByRole('button', { name: rowAction.label }).first()

    if (state === 'enabled') {
      await expectControlEnabled(control)
      continue
    }
    await expectControlDisabled(control)
  }
}
