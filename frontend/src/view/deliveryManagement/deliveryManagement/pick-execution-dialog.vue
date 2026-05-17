<template>
  <v-dialog v-model="isShow" :width="'85%'" transition="dialog-top-transition" :persistent="true">
    <template #default>
      <v-card class="formCard">
        <v-toolbar color="white" :title="`${$t('wms.deliveryManagement.pickExecution')} - ${props.dispatchNo}`"></v-toolbar>
        <v-card-text>
          <div class="actionBar">
            <v-btn variant="text" prepend-icon="mdi-refresh" @click="method.getTableData">{{ $t('system.page.refresh') }}</v-btn>
            <v-btn
              v-if="!props.readonly"
              variant="text"
              color="primary"
              prepend-icon="mdi-check-bold"
              @click="method.confirmRows"
            >
              {{ $t('wms.deliveryManagement.confirmPickDetail') }}
            </v-btn>
            <v-btn
              v-if="!props.readonly"
              variant="text"
              color="warning"
              prepend-icon="mdi-undo-variant"
              @click="method.revokeRows"
            >
              {{ $t('wms.deliveryManagement.revokePickDetail') }}
            </v-btn>
            <v-btn
              v-if="!props.readonly"
              variant="text"
              color="success"
              prepend-icon="mdi-clipboard-check-outline"
              @click="method.reviewDispatch"
            >
              {{ $t('wms.deliveryManagement.reviewPicking') }}
            </v-btn>
          </div>

          <vxe-table ref="xTable" :column-config="{ minWidth: '100px' }" :data="data.tableData" :height="'560px'" align="center">
            <template #empty>
              {{ i18n.global.t('system.page.noData') }}
            </template>
            <vxe-column v-if="!props.readonly" type="checkbox" width="50"></vxe-column>
            <vxe-column type="seq" width="60"></vxe-column>
            <vxe-column field="warehouse_name" :title="$t('wms.stock.warehouse')"></vxe-column>
            <vxe-column field="warehouse_area_name" :title="$t('base.warehouseSetting.area_name')"></vxe-column>
            <vxe-column field="location_name" :title="$t('base.warehouseSetting.location_name')"></vxe-column>
            <vxe-column field="goods_owner_name" :title="$t('base.ownerOfCargo.goods_owner_name')"></vxe-column>
            <vxe-column field="spu_code" :title="$t('wms.deliveryManagement.spu_code')"></vxe-column>
            <vxe-column field="spu_name" :title="$t('wms.deliveryManagement.spu_name')"></vxe-column>
            <vxe-column field="sku_code" :title="$t('wms.deliveryManagement.sku_code')">
              <template #default="{ row }">
                <HoverImagePreview :image-url="row.image_url" :slot-text="row.sku_code" />
              </template>
            </vxe-column>
            <vxe-column field="series_number" :title="$t('wms.stockLocation.series_number')"></vxe-column>
            <vxe-column field="pick_qty" :title="$t('wms.deliveryManagement.order_qty')"></vxe-column>
            <vxe-column field="picked_qty" :title="$t('wms.deliveryManagement.picked_qty')"></vxe-column>
            <vxe-column field="picker" :title="$t('wms.deliveryManagement.picker')"></vxe-column>
          </vxe-table>
        </v-card-text>
        <v-card-actions class="justify-end">
          <v-btn variant="text" @click="method.closeDialog">{{ $t('system.page.close') }}</v-btn>
        </v-card-actions>
      </v-card>
    </template>
  </v-dialog>
</template>

<script lang="ts" setup>
import { computed, reactive, ref, watch } from 'vue'
import { hookComponent } from '@/components/system/index'
import { confirmPickDetail, confirmPicking, revokePickDetail, viewInventoryDetails } from '@/api/wms/deliveryManagement'
import { DispatchpickDetailVO } from '@/types/DeliveryManagement/DeliveryManagement'
import i18n from '@/languages/i18n'
import { httpCodeJudge } from '@/utils/http/httpCodeJudge'

const emit = defineEmits(['close', 'saveSuccess'])

const props = defineProps<{
  showDialog: boolean
  dispatchId: number
  dispatchNo: string
  readonly: boolean
}>()

const xTable = ref()
const isShow = computed(() => props.showDialog)

const data = reactive({
  tableData: [] as DispatchpickDetailVO[]
})

const method = reactive({
  getTableData: async () => {
    if (!props.dispatchId) {
      data.tableData = []
      return
    }
    const { data: res } = await viewInventoryDetails(props.dispatchId)
    if (!res.isSuccess) {
      hookComponent.$message({
        type: 'error',
        content: res.errorMessage
      })
      return
    }
    data.tableData = res.data
  },
  getSelectedIds: (): number[] => {
    const records = xTable.value?.getCheckboxRecords?.() || []
    if (records.length === 0) {
      hookComponent.$message({
        type: 'error',
        content: i18n.global.t('wms.deliveryManagement.opeartionCheckboxIsNull')
      })
      return []
    }
    return records.map((item: DispatchpickDetailVO) => item.id)
  },
  handleOperateError: (msg: string) => {
    if (httpCodeJudge(msg)) {
      emit('saveSuccess')
      method.closeDialog()
      return
    }
    hookComponent.$message({
      type: 'error',
      content: msg
    })
  },
  confirmRows: async () => {
    const ids = method.getSelectedIds()
    if (ids.length === 0) {
      return
    }
    const { data: res } = await confirmPickDetail({
      picklist_id_list: ids
    })
    if (!res.isSuccess) {
      method.handleOperateError(res.errorMessage)
      return
    }
    hookComponent.$message({
      type: 'success',
      content: res.data
    })
    await method.getTableData()
    emit('saveSuccess')
  },
  revokeRows: async () => {
    const ids = method.getSelectedIds()
    if (ids.length === 0) {
      return
    }
    const { data: res } = await revokePickDetail({
      picklist_id_list: ids
    })
    if (!res.isSuccess) {
      method.handleOperateError(res.errorMessage)
      return
    }
    hookComponent.$message({
      type: 'success',
      content: res.data
    })
    await method.getTableData()
    emit('saveSuccess')
  },
  reviewDispatch: async () => {
    hookComponent.$dialog({
      content: `${ i18n.global.t('wms.deliveryManagement.reviewPicking') }?`,
      handleConfirm: async () => {
        const { data: res } = await confirmPicking(props.dispatchNo)
        if (!res.isSuccess) {
          method.handleOperateError(res.errorMessage)
          return
        }
        hookComponent.$message({
          type: 'success',
          content: res.data
        })
        emit('saveSuccess')
        method.closeDialog()
      }
    })
  },
  closeDialog: () => {
    emit('close')
  }
})

watch(
  () => isShow.value,
  (val) => {
    if (val) {
      method.getTableData()
    }
  }
)
</script>

<style scoped lang="less">
.actionBar {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
}
</style>
