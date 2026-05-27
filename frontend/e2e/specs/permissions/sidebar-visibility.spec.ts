import { expect, test } from '@playwright/test'
import { loginAsUser } from '../../support/auth'
import { expectSidebarMenuAbsent, expectSidebarMenuPresent } from '../../support/permission-assertions'
import { ensurePermissionBootstrap, PermissionBootstrap, PermissionRoleKey } from '../../support/permission-bootstrap'
import { APPROVED_PERMISSION_TOTALS, PERMISSION_MANIFEST, uniqueMenuPathsByRole } from '../../support/permission-manifest'

test.describe.configure({ mode: 'serial' })

test.describe('sidebar visibility permissions', () => {
  let bootstrap: PermissionBootstrap

  const positiveRoles: PermissionRoleKey[] = [
    'systemAdmin',
    'masterDataAdmin',
    'inboundOperator',
    'stockAnalyst',
    'internalOperator',
    'outboundOperator'
  ]
  const absentRoles: PermissionRoleKey[] = ['masterDataAdmin', 'systemAdmin', 'stockAnalyst', 'inboundOperator']

  test.beforeAll(async () => {
    bootstrap = await ensurePermissionBootstrap()
  })

  test('permission manifest keeps the approved menu and action counts', async () => {
    expect(PERMISSION_MANIFEST.totals).toEqual(APPROVED_PERMISSION_TOTALS)
  })

  for (const roleKey of positiveRoles) {
    test(`${roleKey} sees its approved sidebar menus`, async ({ page }) => {
      await loginAsUser(page, bootstrap.credentialsByRole[roleKey])
      for (const menuPath of uniqueMenuPathsByRole(roleKey, 'positiveRole')) {
        await expectSidebarMenuPresent(page, menuPath)
      }
    })
  }

  test('auditor can see all approved sidebar menus as a read-only role', async ({ page }) => {
    await loginAsUser(page, bootstrap.credentialsByRole.auditor)
    for (const menuPath of uniqueMenuPathsByRole('auditor', 'visibleNegativeRole')) {
      await expectSidebarMenuPresent(page, menuPath)
    }
  })

  for (const roleKey of absentRoles) {
    test(`${roleKey} does not see sidebar menus outside its approved scope`, async ({ page }) => {
      await loginAsUser(page, bootstrap.credentialsByRole[roleKey])
      for (const menuPath of uniqueMenuPathsByRole(roleKey, 'absentRole')) {
        await expectSidebarMenuAbsent(page, menuPath)
      }
    })
  }
})
