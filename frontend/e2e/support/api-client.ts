import { MODERNWMS_BACKEND_URL } from './test-system'

type QueryValue = string | number | boolean | null | undefined

interface ResultModel<T> {
  isSuccess: boolean
  code: number
  errorMessage: string
  data: T
}

export interface LoginResult {
  access_token: string
  refresh_token: string
  expire: string
  user_id: number
  user_name: string
  user_num: string
  user_role: string
  userrole_id: number
  tenant_id: number
}

export interface MenuRecord {
  id: number
  menu_name: string
  module: string
  vue_path: string
  vue_path_detail: string
  vue_directory: string
  sort: number
  menu_actions: string[]
}

export interface UserRoleRecord {
  id: number
  role_name: string
  is_valid: boolean
}

export interface UserRecord {
  id: number
  user_num: string
  user_name: string
  contact_tel: string
  user_role: string
  sex: string
  is_valid: boolean
}

export interface CompanyRecord {
  id: number
  company_name: string
  city: string
  address: string
  manager: string
  contact_tel: string
}

export interface PrintSolutionRecord {
  id: number
  vue_path: string
  tab_page: string
  solution_name: string
  config_json: string
  report_length: number
  report_width: number
  report_direction: string
}

export interface FreightFeeRecord {
  id: number
  carrier: string
  departure_city: string
  arrival_city: string
  price_per_weight: number
  price_per_volume: number
  min_payment: number
  is_valid: boolean
}

export interface RoleMenuDetailPayload {
  id: number
  menu_id: number
  menu_name: string
  authority: number
  menu_actions_authority: string[]
}

export interface RoleMenuPayload {
  userrole_id: number
  role_name: string
  detailList: RoleMenuDetailPayload[]
}

interface RequestOptions {
  query?: Record<string, QueryValue>
  body?: unknown
}

export class ModernWmsApiClient {
  constructor(private readonly baseUrl = MODERNWMS_BACKEND_URL, private readonly token?: string) {}

  static async asAdmin() {
    const login = await loginToModernWms('admin', '1')
    return new ModernWmsApiClient(MODERNWMS_BACKEND_URL, login.access_token)
  }

  async getMenus() {
    return this.requestData<MenuRecord[]>('GET', '/rolemenu/menus')
  }

  async getRoles() {
    return this.requestData<UserRoleRecord[]>('GET', '/userrole/all')
  }

  async getUsers() {
    return this.requestData<UserRecord[]>('GET', '/user/all')
  }

  async getCompanies() {
    return this.requestData<CompanyRecord[]>('GET', '/company/all')
  }

  async getPrintSolutions() {
    return this.requestData<PrintSolutionRecord[]>('GET', '/PrintSolution/all')
  }

  async getFreightFees() {
    return this.requestData<FreightFeeRecord[]>('GET', '/freightfee/all')
  }

  async getRoleMenu(userrole_id: number) {
    const response = await this.request<RoleMenuPayload>('GET', '/rolemenu', {
      query: { userrole_id }
    })
    return response.isSuccess ? response.data : null
  }

  async addCompany(viewModel: CompanyRecord) {
    return this.request<number>('POST', '/company', { body: viewModel })
  }

  async addPrintSolution(viewModel: PrintSolutionRecord) {
    return this.request<number>('POST', '/PrintSolution', { body: viewModel })
  }

  async addFreightFee(viewModel: FreightFeeRecord) {
    return this.request<number>('POST', '/freightfee', { body: viewModel })
  }

  async addRole(viewModel: UserRoleRecord) {
    return this.request<number>('POST', '/userrole', { body: viewModel })
  }

  async updateRole(viewModel: UserRoleRecord) {
    return this.request<boolean>('PUT', '/userrole', { body: viewModel })
  }

  async addUser(viewModel: UserRecord) {
    return this.request<number>('POST', '/user', { body: viewModel })
  }

  async updateUser(viewModel: UserRecord) {
    return this.request<boolean>('PUT', '/user', { body: viewModel })
  }

  async replaceRoleMenu(viewModel: RoleMenuPayload) {
    const existing = await this.getRoleMenu(viewModel.userrole_id)
    if (existing) {
      await this.request<string>('DELETE', '/rolemenu', {
        query: { userrole_id: viewModel.userrole_id }
      })
    }
    return this.request<number>('POST', '/rolemenu', { body: viewModel })
  }

  async resetUserPassword(userId: number) {
    const response = await this.request<string>('POST', '/user/reset-pwd', {
      body: { id_list: [userId] }
    })
    if (!response.isSuccess) {
      throw new Error(response.errorMessage || `Failed to reset password for user ${userId}`)
    }
    return response.data
  }

  async requestData<T>(method: string, path: string, options: RequestOptions = {}) {
    const response = await this.request<T>(method, path, options)
    if (!response.isSuccess) {
      throw new Error(response.errorMessage || `${method} ${path} failed`)
    }
    return response.data
  }

  async request<T>(method: string, path: string, options: RequestOptions = {}) {
    const response = await fetch(buildUrl(this.baseUrl, path, options.query), {
      method,
      headers: buildHeaders(this.token),
      body: toBody(options.body)
    })

    const json = (await response.json()) as ResultModel<T>
    if (response.ok) {
      return json
    }

    if (json && typeof json === 'object') {
      return json
    }

    throw new Error(`${method} ${path} returned HTTP ${response.status}`)
  }
}

export async function loginToModernWms(user_name: string, password: string) {
  const client = new ModernWmsApiClient(MODERNWMS_BACKEND_URL)
  return client.requestData<LoginResult>('POST', '/login', {
    body: { user_name, password }
  })
}

function buildUrl(baseUrl: string, path: string, query: Record<string, QueryValue> = {}) {
  const url = new URL(path, baseUrl)
  url.searchParams.set('culture', 'en-us')
  Object.entries(query).forEach(([key, value]) => {
    if (value !== undefined && value !== null) {
      url.searchParams.set(key, String(value))
    }
  })
  return url.toString()
}

function buildHeaders(token?: string) {
  const headers: Record<string, string> = {
    Accept: 'application/json',
    'Content-Type': 'application/json'
  }

  if (token) {
    headers.Authorization = `Bearer ${token}`
  }

  return headers
}

function toBody(body?: unknown) {
  return body === undefined ? undefined : JSON.stringify(body)
}
