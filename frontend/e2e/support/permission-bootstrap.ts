import {
  MenuRecord,
  ModernWmsApiClient,
  RoleMenuDetailPayload,
  RoleMenuPayload,
  UserRecord,
  UserRoleRecord
} from './api-client'
import { LoginCredentials } from './auth'

export const APPROVED_MENU_ACTIONS = {
  companySetting: ['save', 'delete', 'export'],
  userRoleSetting: ['save', 'delete', 'export'],
  roleMenu: [],
  userManagement: ['save', 'delete', 'import', 'export', 'resetPwd', 'exportAll'],
  print: ['save', 'delete', 'export', 'exportAll'],
  commodityCategorySetting: ['save', 'delete', 'export'],
  commodityManagement: ['save', 'delete', 'export', 'saftyStock', 'printQrCode', 'printBarCode', 'import', 'exportAll'],
  supplier: ['save', 'delete', 'import', 'export', 'exportAll'],
  warehouseSetting: [
    'warehouse-save',
    'warehouse-delete',
    'warehouse-import',
    'warehouse-export',
    'warehouse-exportAll',
    'area-save',
    'area-delete',
    'area-export',
    'area-exportAll',
    'location-save',
    'location-delete',
    'location-export',
    'location-exportAll',
    'location-printBarCode',
    'location-printQrCode'
  ],
  ownerOfCargo: ['save', 'delete', 'import', 'export', 'exportAll'],
  freightSetting: ['save', 'delete', 'import', 'export', 'exportAll'],
  customer: ['save', 'delete', 'import', 'export', 'exportAll'],
  stockAsn: [
    'notice-save',
    'notice-delete',
    'notice-export',
    'notice-exportAll',
    'delivered-confirm',
    'delivered-export',
    'delivered-exportAll',
    'unloaded-confirm',
    'unloaded-delete',
    'unloaded-export',
    'unloaded-exportAll',
    'sorted-editCount',
    'sorted-confirm',
    'sorted-delete',
    'sorted-export',
    'sorted-exportAll',
    'putOnTheShelf-editArrival',
    'putOnTheShelf-delete',
    'putOnTheShelf-export',
    'putOnTheShelf-exportAll',
    'putOnTheShelf-printQrCode',
    'detail-export',
    'detail-exportAll'
  ],
  stockManagement: ['area-export', 'area-exportAll', 'stock-export', 'stock-exportAll'],
  saftyStock: ['export', 'exportAll'],
  asnStatistic: ['export', 'exportAll'],
  deliveryStatistic: ['exportAll'],
  stockageStatistic: ['export', 'exportAll'],
  warehouseProcessing: ['split', 'group', 'confirmOpeartion', 'confirmAdjust', 'delete', 'export', 'exportAll'],
  warehouseMove: ['save', 'delete', 'export', 'confirm', 'exportAll'],
  warehouseFreeze: ['freeze', 'unfreeze', 'export', 'exportAll'],
  warehouseAdjust: ['export', 'exportAll'],
  warehouseTaking: ['save', 'delete', 'export', 'confirmOpeartion', 'confirmAdjust', 'exportAll'],
  deliveryManagement: [
    'invoice-save',
    'invoice-confirm',
    'invoice-revoke',
    'invoice-delete',
    'invoice-export',
    'invoice-exportAll',
    'invoice-printQrCode',
    'picked-confirm',
    'picked-revoke',
    'picked-export',
    'picked-exportAll',
    'packaged-package',
    'packaged-export',
    'packaged-exportAll',
    'packaged-revoke',
    'weighed-weigh',
    'weighed-export',
    'weighed-exportAll',
    'weighed-revoke',
    'delivered-delivery',
    'delivered-setCarrier',
    'delivered-signIn',
    'delivered-export',
    'delivered-exportAll',
    'signedIn-export',
    'signedIn-exportAll'
  ]
} as const

export type PermissionMenuPath = keyof typeof APPROVED_MENU_ACTIONS
export type PermissionRoleKey =
  | 'systemAdmin'
  | 'masterDataAdmin'
  | 'inboundOperator'
  | 'stockAnalyst'
  | 'internalOperator'
  | 'outboundOperator'
  | 'auditor'

type RoleActions = Partial<Record<PermissionMenuPath, string[]>>

interface PermissionRoleDefinition {
  key: PermissionRoleKey
  roleName: string
  userNum: string
  userName: string
  menuActions: RoleActions
}

export interface PermissionBootstrap {
  credentialsByRole: Record<PermissionRoleKey, LoginCredentials>
  roleDefinitions: PermissionRoleDefinition[]
}

const ALL_MENU_PATHS = Object.keys(APPROVED_MENU_ACTIONS) as PermissionMenuPath[]
const AUDITOR_MENU_ACTIONS = Object.fromEntries(ALL_MENU_PATHS.map((menuPath) => [menuPath, []])) as RoleActions
const ROLE_DEFINITIONS: PermissionRoleDefinition[] = [
  createRoleDefinition('systemAdmin', 'E2E-PERM-SYSTEM-ADMIN', 'e2e_perm_system_admin', 'E2E Permission System Admin', [
    'companySetting',
    'userRoleSetting',
    'roleMenu',
    'userManagement',
    'print'
  ]),
  createRoleDefinition('masterDataAdmin', 'E2E-PERM-MASTER-DATA-ADMIN', 'e2e_perm_master_data_admin', 'E2E Permission Master Data Admin', [
    'commodityCategorySetting',
    'commodityManagement',
    'supplier',
    'warehouseSetting',
    'ownerOfCargo',
    'freightSetting',
    'customer'
  ]),
  createRoleDefinition('inboundOperator', 'E2E-PERM-INBOUND-OPERATOR', 'e2e_perm_inbound_operator', 'E2E Permission Inbound Operator', ['stockAsn']),
  createRoleDefinition(
    'stockAnalyst',
    'E2E-PERM-STOCK-ANALYST',
    'e2e_perm_stock_analyst',
    'E2E Permission Stock Analyst',
    ['stockManagement', 'saftyStock', 'asnStatistic', 'deliveryStatistic', 'stockageStatistic']
  ),
  createRoleDefinition(
    'internalOperator',
    'E2E-PERM-INTERNAL-OPERATOR',
    'e2e_perm_internal_operator',
    'E2E Permission Internal Operator',
    ['warehouseProcessing', 'warehouseMove', 'warehouseFreeze', 'warehouseAdjust', 'warehouseTaking']
  ),
  createRoleDefinition(
    'outboundOperator',
    'E2E-PERM-OUTBOUND-OPERATOR',
    'e2e_perm_outbound_operator',
    'E2E Permission Outbound Operator',
    ['deliveryManagement']
  ),
  {
    key: 'auditor',
    roleName: 'E2E-PERM-AUDITOR',
    userNum: 'e2e_perm_auditor',
    userName: 'E2E Permission Auditor',
    menuActions: AUDITOR_MENU_ACTIONS
  }
]

const bootstrapCache = new Map<string, Promise<PermissionBootstrap>>()

export function ensurePermissionBootstrap(roleKeys: PermissionRoleKey[] = ROLE_DEFINITIONS.map((definition) => definition.key)) {
  const cacheKey = [...roleKeys].sort().join(',')
  if (!bootstrapCache.has(cacheKey)) {
    bootstrapCache.set(cacheKey, bootstrapPermissions(roleKeys))
  }
  return bootstrapCache.get(cacheKey) as Promise<PermissionBootstrap>
}

async function bootstrapPermissions(roleKeys: PermissionRoleKey[]) {
  const definitions = ROLE_DEFINITIONS.filter((definition) => roleKeys.includes(definition.key))
  const api = await ModernWmsApiClient.asAdmin()
  const menusByPath = await loadMenusByPath(api)
  const rolesByName = await loadRolesByName(api)
  const usersByNum = await loadUsersByNum(api)
  const credentialsByRole = {} as Record<PermissionRoleKey, LoginCredentials>

  for (const definition of definitions) {
    const role = await ensureRole(api, rolesByName, definition)
    await replaceRoleMenu(api, menusByPath, role.id, definition)
    credentialsByRole[definition.key] = await ensureUser(api, usersByNum, definition, role.role_name)
  }

  return {
    credentialsByRole,
    roleDefinitions: definitions
  }
}

async function loadMenusByPath(api: ModernWmsApiClient) {
  const menus = await api.getMenus()
  return new Map(menus.map((menu) => [menu.vue_path as PermissionMenuPath, menu]))
}

async function loadRolesByName(api: ModernWmsApiClient) {
  const roles = await api.getRoles()
  return new Map(roles.map((role) => [role.role_name, role]))
}

async function loadUsersByNum(api: ModernWmsApiClient) {
  const users = await api.getUsers()
  return new Map(users.map((user) => [user.user_num, user]))
}

async function ensureRole(api: ModernWmsApiClient, rolesByName: Map<string, UserRoleRecord>, definition: PermissionRoleDefinition) {
  const existing = rolesByName.get(definition.roleName)
  if (!existing) {
    const created = await api.addRole({ id: 0, role_name: definition.roleName, is_valid: true })
    if (!created.isSuccess || !created.data) {
      throw new Error(created.errorMessage || `Failed to create role ${definition.roleName}`)
    }
    const role = { id: created.data, role_name: definition.roleName, is_valid: true }
    rolesByName.set(role.role_name, role)
    return role
  }

  if (!existing.is_valid) {
    const updated = await api.updateRole({ ...existing, is_valid: true })
    if (!updated.isSuccess) {
      throw new Error(updated.errorMessage || `Failed to enable role ${definition.roleName}`)
    }
    existing.is_valid = true
  }

  return existing
}

async function replaceRoleMenu(
  api: ModernWmsApiClient,
  menusByPath: Map<PermissionMenuPath, MenuRecord>,
  roleId: number,
  definition: PermissionRoleDefinition
) {
  const detailList = createRoleMenuDetails(menusByPath, definition.menuActions)
  const response = await api.replaceRoleMenu({
    userrole_id: roleId,
    role_name: definition.roleName,
    detailList
  })

  if (!response.isSuccess) {
    throw new Error(response.errorMessage || `Failed to align menus for role ${definition.roleName}`)
  }
}

function createRoleMenuDetails(menusByPath: Map<PermissionMenuPath, MenuRecord>, menuActions: RoleActions) {
  return Object.entries(menuActions).map(([menuPath, actions]) => {
    const menu = menusByPath.get(menuPath as PermissionMenuPath)
    if (!menu) {
      throw new Error(`Missing menu definition for ${menuPath}`)
    }
    return createRoleMenuDetail(menu, actions ?? [])
  })
}

function createRoleMenuDetail(menu: MenuRecord, actions: string[]): RoleMenuDetailPayload {
  return {
    id: 0,
    menu_id: menu.id,
    menu_name: menu.menu_name,
    authority: 1,
    menu_actions_authority: [...actions]
  }
}

async function ensureUser(
  api: ModernWmsApiClient,
  usersByNum: Map<string, UserRecord>,
  definition: PermissionRoleDefinition,
  roleName: string
) {
  const existing = usersByNum.get(definition.userNum)
  if (!existing) {
    return createUser(api, usersByNum, definition, roleName)
  }

  await updateUserIfNeeded(api, existing, definition, roleName)
  const password = await api.resetUserPassword(existing.id)
  return { userNum: definition.userNum, password }
}

async function createUser(
  api: ModernWmsApiClient,
  usersByNum: Map<string, UserRecord>,
  definition: PermissionRoleDefinition,
  roleName: string
) {
  const response = await api.addUser(createUserPayload(0, definition, roleName))
  if (!response.isSuccess || !response.data) {
    throw new Error(response.errorMessage || `Failed to create user ${definition.userNum}`)
  }

  usersByNum.set(definition.userNum, createUserPayload(response.data, definition, roleName))
  return {
    userNum: definition.userNum,
    password: response.errorMessage
  }
}

async function updateUserIfNeeded(api: ModernWmsApiClient, existing: UserRecord, definition: PermissionRoleDefinition, roleName: string) {
  const expected = createUserPayload(existing.id, definition, roleName)
  const shouldUpdate =
    existing.user_name !== expected.user_name || existing.user_role !== expected.user_role || !existing.is_valid || existing.sex !== expected.sex

  if (!shouldUpdate) {
    return
  }

  const response = await api.updateUser(expected)
  if (!response.isSuccess) {
    throw new Error(response.errorMessage || `Failed to update user ${definition.userNum}`)
  }
}

function createUserPayload(id: number, definition: PermissionRoleDefinition, roleName: string): UserRecord {
  return {
    id,
    user_num: definition.userNum,
    user_name: definition.userName,
    contact_tel: '10086',
    user_role: roleName,
    sex: 'M',
    is_valid: true
  }
}

function createRoleDefinition(
  key: PermissionRoleKey,
  roleName: string,
  userNum: string,
  userName: string,
  menuPaths: PermissionMenuPath[]
): PermissionRoleDefinition {
  return {
    key,
    roleName,
    userNum,
    userName,
    menuActions: pickMenuActions(menuPaths)
  }
}

function pickMenuActions(menuPaths: PermissionMenuPath[]) {
  return Object.fromEntries(menuPaths.map((menuPath) => [menuPath, [...APPROVED_MENU_ACTIONS[menuPath]]])) as RoleActions
}
