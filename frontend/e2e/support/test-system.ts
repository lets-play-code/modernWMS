import { execFile } from 'node:child_process'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { promisify } from 'node:util'
import { expect, Page } from '@playwright/test'

const execFileAsync = promisify(execFile)
const SUPPORT_DIR = path.dirname(fileURLToPath(import.meta.url))
const E2E_DIR = path.resolve(SUPPORT_DIR, '..')
const FRONTEND_DIR = path.resolve(E2E_DIR, '..')
export const REPO_ROOT = path.resolve(FRONTEND_DIR, '..')
export const MODERNWMS_FRONTEND_URL = process.env.MODERNWMS_FRONTEND_URL ?? 'http://127.0.0.1:5173'
export const MODERNWMS_BACKEND_URL = process.env.MODERNWMS_BACKEND_URL ?? 'http://127.0.0.1:20011'

export async function expectModernWmsShell(page: Page) {
  await expect(page.locator('body')).toContainText(/ModernWMS|Stock|库存|收货|发货|Home/i)
}

export async function expectMenuAvailable(page: Page, label: RegExp) {
  await expect(page.locator('body')).toContainText(label)
}

export async function loadPracticeSeed() {
  await runRepoCommand('./scripts/load-picking-practice-seed.sh load')
}

export async function runRepoCommand(command: string) {
  await execFileAsync(
    'zsh',
    ['-lc', `source "$HOME/.zshrc" && ${command}`],
    {
      cwd: REPO_ROOT,
      env: process.env,
      maxBuffer: 1024 * 1024 * 10
    }
  )
}
