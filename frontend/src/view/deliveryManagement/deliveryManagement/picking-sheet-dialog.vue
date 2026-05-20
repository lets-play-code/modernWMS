<template>
  <v-dialog v-model="isShow" :width="'90%'" transition="dialog-top-transition" :persistent="true">
    <template #default>
      <v-card class="formCard" data-testid="picking-sheet-dialog">
        <v-toolbar color="white" :title="$t('wms.deliveryManagement.pickingSheet')">
          <template #append>
            <v-btn v-print="'#picking-sheet-print-root'" variant="text">{{ $t('system.page.print') }}</v-btn>
          </template>
        </v-toolbar>
        <v-card-text>
          <v-progress-linear v-if="data.loading" indeterminate color="primary" class="mb-4" />

          <v-row class="mb-4">
            <v-col cols="4">
              <div class="summaryCard">
                <div class="summaryTitle">{{ $t('wms.deliveryManagement.selectedDispatchCount') }}</div>
                <div class="summaryValue">{{ data.sheet.dispatch_nos.length }}</div>
              </div>
            </v-col>
            <v-col cols="4">
              <div class="summaryCard">
                <div class="summaryTitle">{{ $t('wms.deliveryManagement.pickingSheetLineCount') }}</div>
                <div class="summaryValue">{{ data.sheet.lines.length }}</div>
              </div>
            </v-col>
            <v-col cols="4">
              <div class="summaryCard">
                <div class="summaryTitle">{{ $t('wms.deliveryManagement.selectedDispatchNos') }}</div>
                <div class="summaryText">{{ data.sheet.dispatch_nos.join(', ') || '-' }}</div>
              </div>
            </v-col>
          </v-row>

          <v-row>
            <v-col cols="8">
              <div data-testid="picking-sheet-lines-table">
                <vxe-table :column-config="{ minWidth: '100px' }" :data="data.sheet.lines" :height="'420px'" align="center">
                  <template #empty>
                    {{ i18n.global.t('system.page.noData') }}
                  </template>
                  <vxe-column type="seq" width="60"></vxe-column>
                  <vxe-column field="sku_code" :title="$t('wms.deliveryManagement.sku_code')"></vxe-column>
                  <vxe-column field="spu_name" :title="$t('wms.deliveryManagement.spu_name')"></vxe-column>
                  <vxe-column field="goods_owner_name" :title="$t('base.ownerOfCargo.goods_owner_name')"></vxe-column>
                  <vxe-column field="warehouse_name" :title="$t('wms.stockLocation.warehouse_name')"></vxe-column>
                  <vxe-column field="warehouse_area_name" :title="$t('base.warehouseSetting.area_name')"></vxe-column>
                  <vxe-column field="location_name" :title="$t('base.warehouseSetting.location_name')"></vxe-column>
                  <vxe-column field="series_number" :title="$t('wms.stockLocation.series_number')"></vxe-column>
                  <vxe-column field="pick_qty" :title="$t('wms.deliveryManagement.pick_qty')"></vxe-column>
                  <vxe-column field="picked_qty" :title="$t('wms.deliveryManagement.picked_qty')"></vxe-column>
                  <vxe-column :title="$t('wms.deliveryManagement.relatedDispatchCount')">
                    <template #default="{ row }">
                      {{ row.related_dispatches.length }}
                    </template>
                  </vxe-column>
                  <vxe-column field="operate" :title="$t('system.page.operate')" width="280" :resizable="false" show-overflow>
                    <template #default="{ row }">
                      <div class="lineActionCell">
                        <v-btn data-testid="picking-sheet-related-dispatches-button" size="small" variant="text" @click="method.openRelatedDispatches(row)">
                          {{ $t('wms.deliveryManagement.relatedDispatches') }}
                        </v-btn>
                        <v-btn
                          data-testid="picking-sheet-confirm-item-button"
                          size="small"
                          variant="text"
                          color="primary"
                          :disabled="row.picked_qty >= row.pick_qty"
                          @click="method.confirmLine(row)"
                        >
                          {{ $t('wms.deliveryManagement.confirmPickItems') }}
                        </v-btn>
                        <v-btn
                          data-testid="picking-sheet-revoke-item-button"
                          size="small"
                          variant="text"
                          color="error"
                          :disabled="row.picked_qty <= 0"
                          @click="method.revokeLine(row)"
                        >
                          {{ $t('wms.deliveryManagement.revokePickItems') }}
                        </v-btn>
                      </div>
                    </template>
                  </vxe-column>
                </vxe-table>
              </div>
            </v-col>
            <v-col cols="4">
              <v-card variant="outlined" class="reviewCard">
                <v-card-title>{{ $t('wms.deliveryManagement.reviewDispatchList') }}</v-card-title>
                <v-card-text>
                  <vxe-table :column-config="{ minWidth: '100px' }" :data="data.reviewItems" :height="'420px'" align="center">
                    <template #empty>
                      {{ i18n.global.t('system.page.noData') }}
                    </template>
                    <vxe-column field="dispatch_no" :title="$t('wms.deliveryManagement.dispatch_no')"></vxe-column>
                    <vxe-column :title="$t('wms.deliveryManagement.pickProgress')">
                      <template #default="{ row }">
                        {{ `${row.picked_qty}/${row.pick_qty}` }}
                      </template>
                    </vxe-column>
                    <vxe-column field="pick_checker" :title="$t('wms.deliveryManagement.pickChecker')"></vxe-column>
                    <vxe-column field="operate" :title="$t('system.page.operate')" width="120" :resizable="false" show-overflow>
                      <template #default="{ row }">
                        <v-btn
                          data-testid="picking-sheet-review-dispatch-button"
                          size="small"
                          variant="text"
                          color="primary"
                          :disabled="row.pick_qty <= 0"
                          @click="method.reviewDispatch(row)"
                        >
                          {{ $t('wms.deliveryManagement.reviewPicking') }}
                        </v-btn>
                      </template>
                    </vxe-column>
                  </vxe-table>
                </v-card-text>
              </v-card>
            </v-col>
          </v-row>

          <v-card id="picking-sheet-print-root" data-testid="picking-sheet-print-root" variant="outlined" class="mt-4 pa-4 printCard">
            <div class="printTitle">{{ $t('wms.deliveryManagement.pickingSheet') }}</div>
            <div class="printMeta">{{ $t('wms.deliveryManagement.printTime') }}: {{ data.printTime }}</div>
            <div class="printMeta">{{ $t('wms.deliveryManagement.selectedDispatchNos') }}: {{ data.sheet.dispatch_nos.join(', ') || '-' }}</div>
            <table class="printTable">
              <thead>
                <tr>
                  <th>{{ $t('wms.deliveryManagement.sku_code') }}</th>
                  <th>{{ $t('wms.deliveryManagement.spu_name') }}</th>
                  <th>{{ $t('base.ownerOfCargo.goods_owner_name') }}</th>
                  <th>{{ $t('wms.deliveryManagement.pickLocation') }}</th>
                  <th>{{ $t('wms.deliveryManagement.pick_qty') }}</th>
                  <th>{{ $t('wms.deliveryManagement.relatedDispatches') }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="line in data.sheet.lines" :key="line.group_key">
                  <td>{{ line.sku_code }}</td>
                  <td>{{ line.spu_name }}</td>
                  <td>{{ line.goods_owner_name }}</td>
                  <td>{{ `${line.warehouse_name} / ${line.warehouse_area_name} / ${line.location_name}` }}</td>
                  <td>{{ line.pick_qty }}</td>
                  <td>{{ line.related_dispatches.map((item) => item.dispatch_no).join(', ') }}</td>
                </tr>
              </tbody>
            </table>
          </v-card>
        </v-card-text>
        <v-card-actions class="justify-end">
          <v-btn variant="text" @click="method.closeDialog">{{ $t('system.page.close') }}</v-btn>
        </v-card-actions>
      </v-card>
    </template>
  </v-dialog>

  <v-dialog v-model="data.showRelatedDispatchesDialog" width="40%" transition="dialog-top-transition">
    <template #default>
      <v-card data-testid="picking-sheet-related-dispatches-dialog">
        <v-toolbar color="white" :title="$t('wms.deliveryManagement.relatedDispatches')"></v-toolbar>
        <v-card-text>
          <vxe-table :column-config="{ minWidth: '100px' }" :data="data.relatedDispatches" :height="'300px'" align="center">
            <template #empty>
              {{ i18n.global.t('system.page.noData') }}
            </template>
            <vxe-column type="seq" width="60"></vxe-column>
            <vxe-column field="dispatch_no" :title="$t('wms.deliveryManagement.dispatch_no')"></vxe-column>
            <vxe-column field="dispatchlist_id" :title="$t('wms.deliveryManagement.dispatchlist_id')"></vxe-column>
            <vxe-column field="pick_qty" :title="$t('wms.deliveryManagement.pick_qty')"></vxe-column>
            <vxe-column field="picked_qty" :title="$t('wms.deliveryManagement.picked_qty')"></vxe-column>
          </vxe-table>
        </v-card-text>
        <v-card-actions class="justify-end">
          <v-btn data-testid="picking-sheet-related-dispatches-close-button" variant="text" @click="method.closeRelatedDispatchesDialog">
            {{ $t('system.page.close') }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </template>
  </v-dialog>
</template>

<script lang="ts" setup>
import { computed, reactive, watch } from 'vue'
import { hookComponent } from '@/components/system'
import {
  confirmPickItems,
  getPickingSheet,
  reviewPickingByDispatch,
  revokePickItems,
  viewDeliveryMainDetail
} from '@/api/wms/deliveryManagement'
import {
  PickingSheetDispatchRefVO,
  PickingSheetDispatchReviewVO,
  PickingSheetLineVO,
  PickingSheetVO
} from '@/types/DeliveryManagement/DeliveryManagement'
import i18n from '@/languages/i18n'
import { httpCodeJudge } from '@/utils/http/httpCodeJudge'

const emit = defineEmits(['close', 'updated'])

const props = defineProps<{
  showDialog: boolean
  dispatchlistIds: number[]
}>()

const isShow = computed(() => props.showDialog)

const data = reactive({
  loading: false,
  printTime: '',
  sheet: {
    dispatch_nos: [],
    lines: []
  } as PickingSheetVO,
  reviewItems: [] as PickingSheetDispatchReviewVO[],
  showRelatedDispatchesDialog: false,
  relatedDispatches: [] as PickingSheetDispatchRefVO[]
})

const buildReviewItems = async (sheet: PickingSheetVO): Promise<PickingSheetDispatchReviewVO[]> => {
  const reviewMap = new Map<string, PickingSheetDispatchReviewVO>()
  sheet.dispatch_nos.forEach((dispatchNo) => {
    reviewMap.set(dispatchNo, {
      dispatch_no: dispatchNo,
      pick_qty: 0,
      picked_qty: 0,
      pick_checker: ''
    })
  })

  sheet.lines.forEach((line) => {
    line.related_dispatches.forEach((dispatch) => {
      const item = reviewMap.get(dispatch.dispatch_no)
      if (!item) {
        return
      }
      item.pick_qty += dispatch.pick_qty
      item.picked_qty += dispatch.picked_qty
    })
  })

  const reviewItems = Array.from(reviewMap.values())
  const detailResponses = await Promise.all(reviewItems.map((item) => viewDeliveryMainDetail(item.dispatch_no)))
  detailResponses.forEach((response, index) => {
    if (response.data.isSuccess && response.data.data.length > 0) {
      reviewItems[index].pick_checker = response.data.data[0].pick_checker || ''
    }
  })
  return reviewItems
}

const method = reactive({
  closeDialog: () => {
    emit('close')
  },
  closeRelatedDispatchesDialog: () => {
    data.showRelatedDispatchesDialog = false
    data.relatedDispatches = []
  },
  openRelatedDispatches: (line: PickingSheetLineVO) => {
    data.relatedDispatches = line.related_dispatches
    data.showRelatedDispatchesDialog = true
  },
  loadPickingSheet: async () => {
    if (props.dispatchlistIds.length <= 0) {
      data.sheet = { dispatch_nos: [], lines: [] }
      data.reviewItems = []
      return
    }

    data.loading = true
    const { data: res } = await getPickingSheet({ dispatchlist_ids: props.dispatchlistIds })
    data.loading = false
    if (!res.isSuccess) {
      hookComponent.$message({
        type: 'error',
        content: res.errorMessage
      })
      return
    }
    data.sheet = res.data
    data.reviewItems = await buildReviewItems(res.data)
    data.printTime = new Date().toLocaleString()
  },
  handleMutationError: async (errorMessage: string) => {
    if (httpCodeJudge(errorMessage)) {
      emit('updated')
      await method.loadPickingSheet()
      return true
    }
    hookComponent.$message({
      type: 'error',
      content: errorMessage
    })
    return false
  },
  afterMutationSuccess: async (message: string) => {
    hookComponent.$message({
      type: 'success',
      content: message
    })
    emit('updated')
    await method.loadPickingSheet()
  },
  confirmLine: (line: PickingSheetLineVO) => {
    hookComponent.$dialog({
      content: `${i18n.global.t('wms.deliveryManagement.confirmPickItems')}?`,
      handleConfirm: async () => {
        const { data: res } = await confirmPickItems({ pick_detail_ids: line.pick_detail_ids })
        if (!res.isSuccess) {
          await method.handleMutationError(res.errorMessage)
          return
        }
        await method.afterMutationSuccess(res.data)
      }
    })
  },
  revokeLine: (line: PickingSheetLineVO) => {
    hookComponent.$dialog({
      content: `${i18n.global.t('wms.deliveryManagement.revokePickItems')}?`,
      handleConfirm: async () => {
        const { data: res } = await revokePickItems({ pick_detail_ids: line.pick_detail_ids })
        if (!res.isSuccess) {
          await method.handleMutationError(res.errorMessage)
          return
        }
        await method.afterMutationSuccess(res.data)
      }
    })
  },
  reviewDispatch: (item: PickingSheetDispatchReviewVO) => {
    hookComponent.$dialog({
      content: `${i18n.global.t('wms.deliveryManagement.reviewPicking')} ${item.dispatch_no}?`,
      handleConfirm: async () => {
        const { data: res } = await reviewPickingByDispatch(item.dispatch_no)
        if (!res.isSuccess) {
          await method.handleMutationError(res.errorMessage)
          return
        }
        await method.afterMutationSuccess(res.data)
      }
    })
  }
})

watch(
  () => [isShow.value, props.dispatchlistIds.join(',')],
  ([visible]) => {
    if (visible) {
      method.loadPickingSheet()
    }
  }
)
</script>

<style scoped lang="less">
.summaryCard {
  border: 1px solid #ebe7f2;
  border-radius: 10px;
  padding: 12px 16px;
  height: 100%;
  background: #faf8ff;
}

.summaryTitle {
  color: #666;
  font-size: 13px;
  margin-bottom: 8px;
}

.summaryValue {
  font-size: 28px;
  font-weight: 600;
  color: #9c27b0;
}

.summaryText {
  color: #333;
  line-height: 1.5;
  word-break: break-all;
}

.reviewCard {
  height: 100%;
}

.lineActionCell {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
}

.printCard {
  background: #fff;
}

.printTitle {
  font-size: 20px;
  font-weight: 600;
  margin-bottom: 8px;
}

.printMeta {
  margin-bottom: 6px;
  color: #666;
}

.printTable {
  width: 100%;
  border-collapse: collapse;
  margin-top: 12px;
}

.printTable th,
.printTable td {
  border: 1px solid #ddd;
  padding: 8px;
  text-align: left;
}
</style>
