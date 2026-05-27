import { ModernWmsApiClient } from './api-client'
import { loadPracticeSeed } from './test-system'

export type BusinessBundleName =
  | 'system-and-masterdata-baseline'
  | 'asn-workbench-bundle'
  | 'stock-and-statistics-bundle'
  | 'internal-operations-bundle'
  | 'dispatch-workbench-bundle'

const bundleCache = new Map<BusinessBundleName, Promise<void>>()

export function ensureBusinessBundle(bundleName: BusinessBundleName) {
  if (!bundleCache.has(bundleName)) {
    bundleCache.set(bundleName, setupBusinessBundle(bundleName))
  }
  return bundleCache.get(bundleName) as Promise<void>
}

async function setupBusinessBundle(bundleName: BusinessBundleName) {
  await loadPracticeSeed()

  if (bundleName === 'system-and-masterdata-baseline') {
    await ensureSystemAndMasterdataBaseline()
  }
}

async function ensureSystemAndMasterdataBaseline() {
  const api = await ModernWmsApiClient.asAdmin()
  await ensureCompanyExists(api)
  await ensurePrintSolutionExists(api)
  await ensureFreightFeeExists(api)
}

async function ensureCompanyExists(api: ModernWmsApiClient) {
  const companies = await api.getCompanies()
  if (companies.length > 0) {
    return
  }

  const response = await api.addCompany({
    id: 0,
    company_name: 'E2E Permission Company',
    city: 'Shanghai',
    address: 'E2E Permission Road 1',
    manager: 'E2E Manager',
    contact_tel: '10086'
  })

  if (!response.isSuccess) {
    throw new Error(response.errorMessage || 'Failed to create baseline company')
  }
}

async function ensurePrintSolutionExists(api: ModernWmsApiClient) {
  const solutions = await api.getPrintSolutions()
  const existing = solutions.find((solution) => solution.solution_name === 'E2E Permission Print Solution')
  if (existing) {
    return
  }

  const response = await api.addPrintSolution({
    id: 0,
    vue_path: 'stockAsn',
    tab_page: 'tabNotice',
    solution_name: 'E2E Permission Print Solution',
    config_json: '{"panels":[]}',
    report_length: 210,
    report_width: 297,
    report_direction: 'A4'
  })

  if (!response.isSuccess) {
    throw new Error(response.errorMessage || 'Failed to create baseline print solution')
  }
}

async function ensureFreightFeeExists(api: ModernWmsApiClient) {
  const freightFees = await api.getFreightFees()
  if (freightFees.length > 0) {
    return
  }

  const response = await api.addFreightFee({
    id: 0,
    carrier: 'E2E Carrier',
    departure_city: 'Shanghai',
    arrival_city: 'Suzhou',
    price_per_weight: 12,
    price_per_volume: 8,
    min_payment: 20,
    is_valid: true
  })

  if (!response.isSuccess) {
    throw new Error(response.errorMessage || 'Failed to create baseline freight fee')
  }
}
