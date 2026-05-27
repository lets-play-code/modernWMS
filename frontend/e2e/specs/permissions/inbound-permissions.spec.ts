import { test } from '@playwright/test'
import { loginAsUser } from '../../support/auth'
import { ensureBusinessBundle } from '../../support/business-bundles'
import { expectControlDisabled, expectControlEnabled } from '../../support/permission-assertions'
import { ensurePermissionBootstrap, PermissionBootstrap } from '../../support/permission-bootstrap'
import { tabByLabel, topButton, visibleButtonByLabel } from '../../support/selectors'

interface TabConfig {
  tabLabel: RegExp
  topButtons: string[]
  rowButtons: string[]
}

const TAB_CONFIGS: TabConfig[] = [
  {
    tabLabel: /Notice Of Arrival/i,
    topButtons: ['notice-save', 'notice-export', 'notice-exportAll'],
    rowButtons: ['Delete']
  },
  {
    tabLabel: /To Be Delivered/i,
    topButtons: ['delivered-confirm', 'delivered-export', 'delivered-exportAll'],
    rowButtons: []
  },
  {
    tabLabel: /To Be Unloaded/i,
    topButtons: ['unloaded-confirm', 'unloaded-delete', 'unloaded-export', 'unloaded-exportAll'],
    rowButtons: []
  },
  {
    tabLabel: /To Be Sorted/i,
    topButtons: ['sorted-delete', 'sorted-export', 'sorted-exportAll'],
    rowButtons: ['Sorting', 'Confirm']
  },
  {
    tabLabel: /To Be Put On The Shelf/i,
    topButtons: ['putOnTheShelf-delete', 'putOnTheShelf-export', 'putOnTheShelf-exportAll', 'putOnTheShelf-printQrCode'],
    rowButtons: ['grounding']
  },
  {
    tabLabel: /Receipt Details/i,
    topButtons: ['detail-export', 'detail-exportAll'],
    rowButtons: []
  }
]

test.describe.configure({ mode: 'serial' })

test.describe('inbound permissions', () => {
  let bootstrap: PermissionBootstrap

  test.beforeAll(async () => {
    await ensureBusinessBundle('asn-workbench-bundle')
    bootstrap = await ensurePermissionBootstrap(['inboundOperator', 'auditor'])
  })

  test('inbound operator can use the approved inbound controls', async ({ page }) => {
    await loginAsUser(page, bootstrap.credentialsByRole.inboundOperator)
    await assertInboundPermissions(page, 'enabled')
  })

  test('auditor can see inbound controls but cannot use them', async ({ page }) => {
    await loginAsUser(page, bootstrap.credentialsByRole.auditor)
    await assertInboundPermissions(page, 'disabled')
  })
})

async function assertInboundPermissions(page, state: 'enabled' | 'disabled') {
  await page.goto('/#/stockAsn')
  for (const config of TAB_CONFIGS) {
    await tabByLabel(page, config.tabLabel).click()
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
