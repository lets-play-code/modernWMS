import { expect, type Page, test } from '@playwright/test'
import { loginAsAdmin } from '../support/auth'

async function confirmDialog(page: Page) {
  const activeDialog = page.locator('.v-overlay[role="dialog"]').last()
  const confirmButton = activeDialog.getByRole('button', { name: /Agree|Confirm|同意|确认|確認/i })
  await expect(confirmButton).toBeVisible()
  await confirmButton.click()
}

test('dispatch picking sheet flow works from goods to be picked tab', async ({ page }) => {
  await loginAsAdmin(page)

  await page.getByText(/Delivery Management|发货管理|發貨管理/i).first().click()
  await page.getByRole('tab', { name: /To Be Picked|待拣货|待揀貨/i }).click()

  const selectionCheckboxes = page.locator('[data-testid^="goods-to-be-picked-select-"]:visible')
  await expect(selectionCheckboxes.first()).toBeVisible()
  const checkboxCount = await selectionCheckboxes.count()
  await selectionCheckboxes.nth(0).click()
  if (checkboxCount > 1) {
    await selectionCheckboxes.nth(1).click()
  }

  const pickingSheetResponse = page.waitForResponse(
    (response) => response.url().includes('/dispatchlist/picking-sheet') && response.request().method() === 'POST'
  )
  await page.getByTestId('open-picking-sheet-button').click()
  await expect((await pickingSheetResponse).ok()).toBeTruthy()

  await expect(page.getByTestId('picking-sheet-dialog')).toBeVisible()
  await expect(page.getByTestId('picking-sheet-lines-table')).toBeVisible()
  await expect(page.getByTestId('picking-sheet-print-root')).toBeVisible()

  await page.getByTestId('picking-sheet-related-dispatches-button').first().click()
  await expect(page.getByTestId('picking-sheet-related-dispatches-dialog')).toBeVisible()
  await page.getByTestId('picking-sheet-related-dispatches-close-button').click()

  const confirmResponse = page.waitForResponse(
    (response) => response.url().includes('/dispatchlist/confirm-pick-items') && response.request().method() === 'PUT'
  )
  await page.getByTestId('picking-sheet-confirm-item-button').first().click()
  await confirmDialog(page)
  await expect((await confirmResponse).ok()).toBeTruthy()

  const revokeResponse = page.waitForResponse(
    (response) => response.url().includes('/dispatchlist/revoke-pick-items') && response.request().method() === 'PUT'
  )
  await page.getByTestId('picking-sheet-revoke-item-button').first().click()
  await confirmDialog(page)
  await expect((await revokeResponse).ok()).toBeTruthy()
})
