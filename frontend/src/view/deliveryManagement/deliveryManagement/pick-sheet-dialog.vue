<template>
  <v-dialog v-model="isShow" :width="'85%'" transition="dialog-top-transition" :persistent="true">
    <template #default>
      <v-card class="formCard">
        <v-toolbar color="white" :title="$t('wms.deliveryManagement.pickSheet')"></v-toolbar>
        <v-card-text>
          <div id="pickSheetPrintArea" class="pickSheetPrintArea">
            <div class="pickSheetHeader">
              <h2>{{ $t('wms.deliveryManagement.pickSheet') }}</h2>
              <p>{{ $t('wms.deliveryManagement.relatedDispatches') }}: {{ props.dispatchIds.length }}</p>
            </div>
            <vxe-table :column-config="{ minWidth: '100px' }" :data="data.tableData" :height="'520px'" align="center">
              <template #empty>
                {{ i18n.global.t('system.page.noData') }}
              </template>
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
              <vxe-column field="related_dispatches" min-width="220" :title="$t('wms.deliveryManagement.relatedDispatches')">
                <template #default="{ row }">
                  <div class="relatedDispatchList">
                    <span v-for="item in row.related_dispatches" :key="`${item.dispatch_no}-${item.dispatchlist_id}`">
                      {{ method.formatDispatchItem(item) }}
                    </span>
                  </div>
                </template>
              </vxe-column>
            </vxe-table>
          </div>
        </v-card-text>
        <v-card-actions class="justify-end">
          <v-btn variant="text" @click="method.closeDialog">{{ $t('system.page.close') }}</v-btn>
          <v-btn v-print="'#pickSheetPrintArea'" color="primary" variant="text">{{ $t('system.page.print') }}</v-btn>
        </v-card-actions>
      </v-card>
    </template>
  </v-dialog>
</template>

<script lang="ts" setup>
import { computed, reactive, watch } from 'vue'
import { hookComponent } from '@/components/system/index'
import { getPickSheet } from '@/api/wms/deliveryManagement'
import { DispatchpickSheetDispatchVO, DispatchpickSheetItemVO } from '@/types/DeliveryManagement/DeliveryManagement'
import i18n from '@/languages/i18n'

const emit = defineEmits(['close'])

const props = defineProps<{
  showDialog: boolean
  dispatchIds: number[]
}>()

const isShow = computed(() => props.showDialog)

const data = reactive({
  tableData: [] as DispatchpickSheetItemVO[]
})

const method = reactive({
  getTableData: async () => {
    if (props.dispatchIds.length === 0) {
      data.tableData = []
      return
    }
    const { data: res } = await getPickSheet({
      dispatchlist_id_list: props.dispatchIds
    })
    if (!res.isSuccess) {
      hookComponent.$message({
        type: 'error',
        content: res.errorMessage
      })
      return
    }
    data.tableData = res.data
  },
  formatDispatchItem: (item: DispatchpickSheetDispatchVO) => `${ item.dispatch_no }(${ item.pick_qty })`,
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
.pickSheetHeader {
  margin-bottom: 12px;
}

.pickSheetHeader h2 {
  margin-bottom: 4px;
}

.relatedDispatchList {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 4px;
}
</style>
