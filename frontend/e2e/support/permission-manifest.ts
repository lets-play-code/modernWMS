import { APPROVED_MENU_ACTIONS, PermissionMenuPath, PermissionRoleKey } from './permission-bootstrap'

export interface SidebarVisibilityEntry {
  context: PermissionContext
  menuPath: PermissionMenuPath
  positiveRole: PermissionRoleKey
  visibleNegativeRole: PermissionRoleKey
  absentRole: PermissionRoleKey
  specFile: string
}

export interface ActionCoverageGroup {
  context: PermissionContext
  menuPath: PermissionMenuPath
  approvedActions: string[]
  specFile: string
}

export type PermissionContext =
  | 'system-management'
  | 'master-data'
  | 'inbound-execution'
  | 'inventory-and-statistics'
  | 'internal-operations'
  | 'outbound-fulfillment'

export const APPROVED_PERMISSION_TOTALS = {
  menus: 24,
  actions: 146
}

export const SIDEBAR_VISIBILITY_MANIFEST: SidebarVisibilityEntry[] = [
  createSidebarEntry('system-management', 'companySetting', 'systemAdmin', 'auditor', 'masterDataAdmin'),
  createSidebarEntry('system-management', 'userRoleSetting', 'systemAdmin', 'auditor', 'masterDataAdmin'),
  createSidebarEntry('system-management', 'roleMenu', 'systemAdmin', 'auditor', 'masterDataAdmin'),
  createSidebarEntry('system-management', 'userManagement', 'systemAdmin', 'auditor', 'masterDataAdmin'),
  createSidebarEntry('system-management', 'print', 'systemAdmin', 'auditor', 'masterDataAdmin'),
  createSidebarEntry('master-data', 'commodityCategorySetting', 'masterDataAdmin', 'auditor', 'systemAdmin'),
  createSidebarEntry('master-data', 'commodityManagement', 'masterDataAdmin', 'auditor', 'systemAdmin'),
  createSidebarEntry('master-data', 'supplier', 'masterDataAdmin', 'auditor', 'systemAdmin'),
  createSidebarEntry('master-data', 'warehouseSetting', 'masterDataAdmin', 'auditor', 'systemAdmin'),
  createSidebarEntry('master-data', 'ownerOfCargo', 'masterDataAdmin', 'auditor', 'systemAdmin'),
  createSidebarEntry('master-data', 'freightSetting', 'masterDataAdmin', 'auditor', 'systemAdmin'),
  createSidebarEntry('master-data', 'customer', 'masterDataAdmin', 'auditor', 'systemAdmin'),
  createSidebarEntry('inbound-execution', 'stockAsn', 'inboundOperator', 'auditor', 'stockAnalyst'),
  createSidebarEntry('inventory-and-statistics', 'stockManagement', 'stockAnalyst', 'auditor', 'inboundOperator'),
  createSidebarEntry('inventory-and-statistics', 'saftyStock', 'stockAnalyst', 'auditor', 'inboundOperator'),
  createSidebarEntry('inventory-and-statistics', 'asnStatistic', 'stockAnalyst', 'auditor', 'inboundOperator'),
  createSidebarEntry('inventory-and-statistics', 'deliveryStatistic', 'stockAnalyst', 'auditor', 'inboundOperator'),
  createSidebarEntry('inventory-and-statistics', 'stockageStatistic', 'stockAnalyst', 'auditor', 'inboundOperator'),
  createSidebarEntry('internal-operations', 'warehouseProcessing', 'internalOperator', 'auditor', 'inboundOperator'),
  createSidebarEntry('internal-operations', 'warehouseMove', 'internalOperator', 'auditor', 'inboundOperator'),
  createSidebarEntry('internal-operations', 'warehouseFreeze', 'internalOperator', 'auditor', 'inboundOperator'),
  createSidebarEntry('internal-operations', 'warehouseAdjust', 'internalOperator', 'auditor', 'inboundOperator'),
  createSidebarEntry('internal-operations', 'warehouseTaking', 'internalOperator', 'auditor', 'inboundOperator'),
  createSidebarEntry('outbound-fulfillment', 'deliveryManagement', 'outboundOperator', 'auditor', 'inboundOperator')
]

export const ACTION_COVERAGE_GROUPS: ActionCoverageGroup[] = SIDEBAR_VISIBILITY_MANIFEST.map((entry) => ({
  context: entry.context,
  menuPath: entry.menuPath,
  approvedActions: [...APPROVED_MENU_ACTIONS[entry.menuPath]],
  specFile: entry.specFile
}))

export const PERMISSION_MANIFEST = {
  totals: {
    menus: SIDEBAR_VISIBILITY_MANIFEST.length,
    actions: ACTION_COVERAGE_GROUPS.reduce((sum, entry) => sum + entry.approvedActions.length, 0)
  },
  sidebar: SIDEBAR_VISIBILITY_MANIFEST,
  actionGroups: ACTION_COVERAGE_GROUPS
}

export function uniqueMenuPathsByRole(roleKey: PermissionRoleKey, key: 'positiveRole' | 'visibleNegativeRole' | 'absentRole') {
  const menuPaths = SIDEBAR_VISIBILITY_MANIFEST.filter((entry) => entry[key] === roleKey).map((entry) => entry.menuPath)
  return [...new Set(menuPaths)]
}

function createSidebarEntry(
  context: PermissionContext,
  menuPath: PermissionMenuPath,
  positiveRole: PermissionRoleKey,
  visibleNegativeRole: PermissionRoleKey,
  absentRole: PermissionRoleKey
): SidebarVisibilityEntry {
  return {
    context,
    menuPath,
    positiveRole,
    visibleNegativeRole,
    absentRole,
    specFile: specFileForContext(context)
  }
}

function specFileForContext(context: PermissionContext) {
  switch (context) {
    case 'system-management':
      return 'permissions/system-management-permissions.spec.ts'
    case 'master-data':
      return 'permissions/master-data-permissions.spec.ts'
    case 'inbound-execution':
      return 'permissions/inbound-permissions.spec.ts'
    case 'inventory-and-statistics':
      return 'permissions/inventory-and-statistics-permissions.spec.ts'
    case 'internal-operations':
      return 'permissions/internal-operations-permissions.spec.ts'
    case 'outbound-fulfillment':
      return 'permissions/outbound-fulfillment-permissions.spec.ts'
  }
}
