# language: zh-CN
功能: 出库履约

  场景: 发货单经创建到签收的完整履约链路
    假如以管理员登录
    并且存在"可用库存":
      | warehouse.key | warehouse.name    | area.key | area.name           | area.property | location.key | location.code         | goods_owner.key | goods_owner.name  | supplier.name     | customer.name     | category.name     | spu.key | spu.code           | sku.key | sku.code           | qty | is_freeze | series_number        | expiry_date | price | putaway_date |
      | main          | WH-E2E-OUT-FLOW   | main     | AREA-E2E-OUT-FLOW   | 1             | main         | LOC-E2E-OUT-FLOW-01   | main            | 练习货主-OUT-FLOW | 练习供应商-OUT-FLOW | 练习客户-OUT-FLOW | 分类-OUT-FLOW     | item    | SPU-E2E-OUT-FLOW  | item    | SKU-E2E-OUT-FLOW  | 8   | false     | SN-E2E-OUT-FLOW-01  | 2026-12-31  | 11.5  | 2026-05-01   |
    当POST "/dispatchlist":
      """
      [
        {
          "customer_id": ${customer.id},
          "customer_name": "练习客户-OUT-FLOW",
          "sku_id": ${sku.item.id},
          "qty": 5
        }
      ]
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当POST "/dispatchlist/advanced-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "customer_name", "operator": 1, "text": "练习客户-OUT-FLOW", "value": "练习客户-OUT-FLOW" }
        ]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.totals = 1
      body.json.data.rows[0].dispatch_status = 0
      body.json.data.rows[0].qty = 5
      """
    并且记录响应字段 "body.json.data.rows[0].dispatch_no" 为 "dispatch.no"
    当POST "/dispatchlist/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "customer_name", "operator": 1, "text": "练习客户-OUT-FLOW", "value": "练习客户-OUT-FLOW" }
        ]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.totals = 1
      body.json.data.rows[0].qty = 5
      """
    并且记录响应字段 "body.json.data.rows[0].id" 为 "dispatch.id"
    当GET "/dispatchlist/confirm-check?dispatch_no=${dispatch.no}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: [{
          dispatchlist_id: *
          dispatch_no: *
          sku_code: 'SKU-E2E-OUT-FLOW'
          qty: 5
          qty_available: 8
          confirm: true
          pick_list: [{
            stock_id: *
            goods_owner_name: '练习货主-OUT-FLOW'
            location_name: 'LOC-E2E-OUT-FLOW-01'
            pick_qty: 5
            series_number: 'SN-E2E-OUT-FLOW-01'
          }]
        }]
      }
      """
    并且记录响应字段 "body.json.data[0].dispatchlist_id" 为 "dispatch.confirm_id"
    并且记录响应字段 "body.json.data[0].pick_list[0].stock_id" 为 "dispatch.stock_id"
    当POST "/dispatchlist/confirm-order":
      """
      [
        {
          "dispatchlist_id": ${dispatch.confirm_id},
          "dispatch_no": "${dispatch.no}",
          "sku_id": ${sku.item.id},
          "qty": 5,
          "confirm": true,
          "pick_list": [
            {
              "stock_id": ${dispatch.stock_id},
              "dispatchlist_id": ${dispatch.confirm_id},
              "goods_owner_id": ${goods_owner.main.id},
              "goods_location_id": ${location.main.id},
              "pick_qty": 5,
              "series_number": "SN-E2E-OUT-FLOW-01",
              "expiry_date": "2026-12-31T00:00:00",
              "price": 11.5,
              "putaway_date": "2026-05-01T00:00:00"
            }
          ]
        }
      ]
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    并且所有"发货单"应为:
      """
      : [{
        sku_code: 'SKU-E2E-OUT-FLOW'
        dispatch_status: 2
        qty: 5
        lock_qty: 5
        picked_qty: 0
        package_qty: 0
        weighing_qty: 0
        actual_qty: 0
        sign_qty: 0
        damage_qty: 0
        waybill_no: ''
        carrier: ''
        freightfee: 0
      }]
      """
    并且所有"拣货明细"应为:
      """
      : [{
        sku_code: 'SKU-E2E-OUT-FLOW'
        pick_qty: 5
        picked_qty: 0
        is_update_stock: false
        series_number: 'SN-E2E-OUT-FLOW-01'
      }]
      """
    并且所有"库存视图"应为:
      """
      : [{
        sku_code: 'SKU-E2E-OUT-FLOW'
        qty: 8
        qty_frozen: 0
        qty_locked: 5
        qty_available: 3
      }]
      """
    当GET "/dispatchlist/pick-list?dispatch_id=${dispatch.id}"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size = 1
      body.json.data[0].pick_qty = 5
      body.json.data[0].picked_qty = 0
      """
    当PUT "/dispatchlist/confirm-pick-dispatchlistno?dispatch_no=${dispatch.no}":
      """
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当POST "/dispatchlist/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "sqlTitle": "package",
        "searchObjects": [
          { "name": "dispatch_no", "operator": 1, "text": "${dispatch.no}", "value": "${dispatch.no}" }
        ]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.totals = 1
      body.json.data.rows[0].dispatch_status = 3
      """
    当POST "/dispatchlist/package":
      """
      [
        {
          "id": ${dispatch.id},
          "dispatch_no": "${dispatch.no}",
          "dispatch_status": 3,
          "package_qty": 5,
          "picked_qty": 5
        }
      ]
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    并且所有"发货单"应为:
      """
      : [{
        sku_code: 'SKU-E2E-OUT-FLOW'
        dispatch_status: 4
        qty: 5
        lock_qty: 5
        picked_qty: 5
        package_qty: 5
        weighing_qty: 0
        actual_qty: 0
        sign_qty: 0
      }]
      """
    当POST "/dispatchlist/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "sqlTitle": "weight",
        "searchObjects": [
          { "name": "dispatch_no", "operator": 1, "text": "${dispatch.no}", "value": "${dispatch.no}" }
        ]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.totals = 1
      body.json.data.rows[0].dispatch_status = 4
      """
    当POST "/dispatchlist/weight":
      """
      [
        {
          "id": ${dispatch.id},
          "dispatch_no": "${dispatch.no}",
          "dispatch_status": 4,
          "weighing_qty": 5,
          "weighing_weight": 12.5,
          "picked_qty": 5
        }
      ]
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当POST "/freightfee":
      """
      {
        "carrier": "承运-E2E-OUT-FLOW",
        "departure_city": "上海",
        "arrival_city": "杭州",
        "price_per_weight": 2.5,
        "price_per_volume": 1.2,
        "min_payment": 10,
        "is_valid": true
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data > 0
      """
    并且记录响应字段 "body.json.data" 为 "freight.id"
    当POST "/dispatchlist/freightfee":
      """
      [
        {
          "id": ${dispatch.id},
          "dispatch_no": "${dispatch.no}",
          "dispatch_status": 5,
          "freightfee_id": ${freight.id},
          "carrier": "承运-E2E-OUT-FLOW",
          "waybill_no": "WB-E2E-OUT-FLOW-01"
        }
      ]
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当POST "/dispatchlist/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "sqlTitle": "delivery",
        "searchObjects": [
          { "name": "dispatch_no", "operator": 1, "text": "${dispatch.no}", "value": "${dispatch.no}" }
        ]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.totals = 1
      body.json.data.rows[0].dispatch_status = 5
      """
    当POST "/dispatchlist/delivery":
      """
      [
        {
          "id": ${dispatch.id},
          "dispatch_no": "${dispatch.no}",
          "dispatch_status": 5,
          "picked_qty": 5
        }
      ]
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    并且所有"发货单"应为:
      """
      : [{
        sku_code: 'SKU-E2E-OUT-FLOW'
        dispatch_status: 6
        qty: 5
        lock_qty: 0
        picked_qty: 5
        package_qty: 5
        weighing_qty: 5
        actual_qty: 5
        sign_qty: 0
        damage_qty: 0
        waybill_no: 'WB-E2E-OUT-FLOW-01'
        carrier: '承运-E2E-OUT-FLOW'
        freightfee: 31.25
      }]
      """
    并且所有"拣货明细"应为:
      """
      : [{
        sku_code: 'SKU-E2E-OUT-FLOW'
        pick_qty: 5
        picked_qty: 5
        is_update_stock: true
        series_number: 'SN-E2E-OUT-FLOW-01'
      }]
      """
    并且所有"库存视图"应为:
      """
      : [{
        sku_code: 'SKU-E2E-OUT-FLOW'
        qty: 3
        qty_frozen: 0
        qty_locked: 0
        qty_available: 3
      }]
      """
    当POST "/dispatchlist/sign":
      """
      [
        {
          "id": ${dispatch.id},
          "dispatch_no": "${dispatch.no}",
          "dispatch_status": 6,
          "damage_qty": 1
        }
      ]
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    并且所有"发货单"应为:
      """
      : [{
        sku_code: 'SKU-E2E-OUT-FLOW'
        dispatch_status: 7
        qty: 5
        lock_qty: 0
        picked_qty: 5
        package_qty: 5
        weighing_qty: 5
        actual_qty: 5
        sign_qty: 4
        damage_qty: 1
        waybill_no: 'WB-E2E-OUT-FLOW-01'
        carrier: '承运-E2E-OUT-FLOW'
        freightfee: 31.25
      }]
      """

  场景: 库存不足订单在确认检查时被标记为不可确认
    假如以管理员登录
    并且存在"可用库存":
      | warehouse.key | warehouse.name      | area.key | area.name             | area.property | location.key | location.code           | goods_owner.key | goods_owner.name    | supplier.name       | customer.name       | category.name       | spu.key | spu.code             | sku.key | sku.code             | qty | is_freeze | series_number           | expiry_date | price | putaway_date |
      | main          | WH-E2E-OUT-SHORT    | main     | AREA-E2E-OUT-SHORT    | 1             | main         | LOC-E2E-OUT-SHORT-01    | main            | 练习货主-OUT-SHORT  | 练习供应商-OUT-SHORT | 练习客户-OUT-SHORT | 分类-OUT-SHORT      | item    | SPU-E2E-OUT-SHORT    | item    | SKU-E2E-OUT-SHORT    | 4   | false     | SN-E2E-OUT-SHORT-01    | 2026-12-31  | 9.9   | 2026-05-01   |
    当POST "/dispatchlist":
      """
      [
        {
          "customer_id": ${customer.id},
          "customer_name": "练习客户-OUT-SHORT",
          "sku_id": ${sku.item.id},
          "qty": 6
        }
      ]
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当POST "/dispatchlist/advanced-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "customer_name", "operator": 1, "text": "练习客户-OUT-SHORT", "value": "练习客户-OUT-SHORT" }
        ]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.totals = 1
      """
    并且记录响应字段 "body.json.data.rows[0].dispatch_no" 为 "dispatch.no"
    当GET "/dispatchlist/confirm-check?dispatch_no=${dispatch.no}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: [{
          dispatch_no: *
          sku_code: 'SKU-E2E-OUT-SHORT'
          qty: 6
          qty_available: 4
          confirm: false
          pick_list: [{
            pick_qty: 4
            series_number: 'SN-E2E-OUT-SHORT-01'
          }]
        }]
      }
      """
    并且所有"发货单"应为:
      """
      : [{
        sku_code: 'SKU-E2E-OUT-SHORT'
        dispatch_status: 0
        qty: 6
        lock_qty: 0
        picked_qty: 0
      }]
      """
    并且所有"库存视图"应为:
      """
      : [{
        sku_code: 'SKU-E2E-OUT-SHORT'
        qty: 4
        qty_frozen: 0
        qty_locked: 0
        qty_available: 4
      }]
      """

  场景: 已锁库发货单取消后释放库存占用
    假如以管理员登录
    并且存在"已锁库 发货单":
      | dispatch_no            | sku.code             | customer.name       | goods_owner.name      | location.code            | stock_qty | qty | lock_qty |
      | DP-E2E-OUT-CANCEL-01   | SKU-E2E-OUT-CANCEL   | 练习客户-OUT-CANCEL | 练习货主-OUT-CANCEL   | LOC-E2E-OUT-CANCEL-01    | 12        | 8   | 8        |
    当POST "/dispatchlist/cancel-order":
      """
      {
        "dispatch_no": "DP-E2E-OUT-CANCEL-01",
        "dispatch_status": 2
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    并且所有"发货单"应为:
      """
      : [{
        dispatch_no: 'DP-E2E-OUT-CANCEL-01'
        sku_code: 'SKU-E2E-OUT-CANCEL'
        dispatch_status: 1
        qty: 8
        lock_qty: 0
        picked_qty: 0
      }]
      """
    并且所有"拣货明细"应为:
      """
      = []
      """
    并且所有"库存视图"应为:
      """
      : [{
        sku_code: 'SKU-E2E-OUT-CANCEL'
        qty: 12
        qty_frozen: 0
        qty_locked: 0
        qty_available: 12
      }]
      """

  场景: 运行时拣货单会按同库存层聚合待拣货明细
    假如以管理员登录
    并且存在"可用库存":
      | warehouse.key | warehouse.name            | area.key | area.name                 | area.property | location.key | location.code               | goods_owner.key | goods_owner.name      | customer.name        | category.name       | spu.key | spu.code             | sku.key | sku.code             | qty | dispatch_no             | dispatch_status | dispatch_qty | dispatch_lock_qty | series_number         | expiry_date | price | putaway_date |
      | main          | WH-E2E-PICK-SHEET-AGG    | main     | AREA-E2E-PICK-SHEET-AGG   | 1             | main         | LOC-E2E-PICK-SHEET-AGG-01   | main            | 练习货主-PICK-AGG    | 练习客户-PICK-AGG    | 分类-PICK-AGG       | item    | SPU-E2E-PICK-AGG     | item    | SKU-E2E-PICK-AGG     | 12  | DP-E2E-PICK-AGG-01   | 2               | 3            | 3                 | SN-E2E-PICK-AGG-01   | 2026-12-31  | 11.5  | 2026-05-01   |
      | main          | WH-E2E-PICK-SHEET-AGG    | main     | AREA-E2E-PICK-SHEET-AGG   | 1             | main         | LOC-E2E-PICK-SHEET-AGG-01   | main            | 练习货主-PICK-AGG    | 练习客户-PICK-AGG    | 分类-PICK-AGG       | item    | SPU-E2E-PICK-AGG     | item    | SKU-E2E-PICK-AGG     | 0   | DP-E2E-PICK-AGG-02   | 2               | 5            | 5                 | SN-E2E-PICK-AGG-01   | 2026-12-31  | 11.5  | 2026-05-01   |
    当GET "/dispatchlist/by-dispatch_no?dispatch_no=DP-E2E-PICK-AGG-01"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size = 1
      """
    并且记录响应字段 "body.json.data[0].id" 为 "dispatch.first_id"
    当GET "/dispatchlist/by-dispatch_no?dispatch_no=DP-E2E-PICK-AGG-02"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size = 1
      """
    并且记录响应字段 "body.json.data[0].id" 为 "dispatch.second_id"
    当POST "/dispatchlist/picking-sheet":
      """
      {
        "dispatchlist_ids": [${dispatch.first_id}, ${dispatch.second_id}]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          dispatch_nos: ['DP-E2E-PICK-AGG-01', 'DP-E2E-PICK-AGG-02']
          lines: [{
            group_key: *
            sku_code: 'SKU-E2E-PICK-AGG'
            location_name: 'LOC-E2E-PICK-SHEET-AGG-01'
            pick_qty: 8
            picked_qty: 0
            pick_detail_ids: [*, *]
            related_dispatches: [{
              dispatch_no: 'DP-E2E-PICK-AGG-01'
              pick_qty: 3
              picked_qty: 0
            }, {
              dispatch_no: 'DP-E2E-PICK-AGG-02'
              pick_qty: 5
              picked_qty: 0
            }]
          }]
        }
      }
      """

  场景: 运行时拣货单不会把不同库位的拣货项错误合并
    假如以管理员登录
    并且存在"可用库存":
      | warehouse.key | warehouse.name              | area.key | area.name                   | area.property | location.key | location.code                 | goods_owner.key | goods_owner.name        | customer.name          | category.name         | spu.key | spu.code               | sku.key | sku.code               | qty | dispatch_no               | dispatch_status | dispatch_qty | dispatch_lock_qty | series_number           | expiry_date | price | putaway_date |
      | main          | WH-E2E-PICK-SHEET-SPLIT    | main     | AREA-E2E-PICK-SHEET-SPLIT   | 1             | first        | LOC-E2E-PICK-SHEET-SPLIT-01   | main            | 练习货主-PICK-SPLIT    | 练习客户-PICK-SPLIT    | 分类-PICK-SPLIT       | item    | SPU-E2E-PICK-SPLIT     | item    | SKU-E2E-PICK-SPLIT     | 6   | DP-E2E-PICK-SPLIT-01   | 2               | 3            | 3                 | SN-E2E-PICK-SPLIT-01   | 2026-12-31  | 11.5  | 2026-05-01   |
      | main          | WH-E2E-PICK-SHEET-SPLIT    | main     | AREA-E2E-PICK-SHEET-SPLIT   | 1             | second       | LOC-E2E-PICK-SHEET-SPLIT-02   | main            | 练习货主-PICK-SPLIT    | 练习客户-PICK-SPLIT    | 分类-PICK-SPLIT       | item    | SPU-E2E-PICK-SPLIT     | item    | SKU-E2E-PICK-SPLIT     | 4   | DP-E2E-PICK-SPLIT-02   | 2               | 4            | 4                 | SN-E2E-PICK-SPLIT-01   | 2026-12-31  | 11.5  | 2026-05-01   |
    当GET "/dispatchlist/by-dispatch_no?dispatch_no=DP-E2E-PICK-SPLIT-01"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size = 1
      """
    并且记录响应字段 "body.json.data[0].id" 为 "dispatch.first_id"
    当GET "/dispatchlist/by-dispatch_no?dispatch_no=DP-E2E-PICK-SPLIT-02"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size = 1
      """
    并且记录响应字段 "body.json.data[0].id" 为 "dispatch.second_id"
    当POST "/dispatchlist/picking-sheet":
      """
      {
        "dispatchlist_ids": [${dispatch.first_id}, ${dispatch.second_id}]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          dispatch_nos: ['DP-E2E-PICK-SPLIT-01', 'DP-E2E-PICK-SPLIT-02']
          lines: [{
            sku_code: 'SKU-E2E-PICK-SPLIT'
            location_name: 'LOC-E2E-PICK-SHEET-SPLIT-01'
            pick_qty: 3
            picked_qty: 0
            pick_detail_ids: [*]
            related_dispatches: [{
              dispatch_no: 'DP-E2E-PICK-SPLIT-01'
              pick_qty: 3
              picked_qty: 0
            }]
          }, {
            sku_code: 'SKU-E2E-PICK-SPLIT'
            location_name: 'LOC-E2E-PICK-SHEET-SPLIT-02'
            pick_qty: 4
            picked_qty: 0
            pick_detail_ids: [*]
            related_dispatches: [{
              dispatch_no: 'DP-E2E-PICK-SPLIT-02'
              pick_qty: 4
              picked_qty: 0
            }]
          }]
        }
      }
      """

  场景: 行级拣货确认与撤销会更新拣货员并保持待拣货状态
    假如以管理员登录
    并且存在"可用库存":
      | warehouse.key | warehouse.name            | area.key | area.name                 | area.property | location.key | location.code               | goods_owner.key | goods_owner.name      | customer.name        | category.name       | spu.key | spu.code             | sku.key | sku.code             | qty | dispatch_no             | dispatch_status | dispatch_qty | dispatch_lock_qty | series_number         | expiry_date | price | putaway_date |
      | main          | WH-E2E-PICK-ITEM         | main     | AREA-E2E-PICK-ITEM        | 1             | main         | LOC-E2E-PICK-ITEM-01        | main            | 练习货主-PICK-ITEM    | 练习客户-PICK-ITEM    | 分类-PICK-ITEM       | item    | SPU-E2E-PICK-ITEM     | item    | SKU-E2E-PICK-ITEM     | 8   | DP-E2E-PICK-ITEM-01   | 2               | 5            | 5                 | SN-E2E-PICK-ITEM-01   | 2026-12-31  | 11.5  | 2026-05-01   |
    当GET "/dispatchlist/by-dispatch_no?dispatch_no=DP-E2E-PICK-ITEM-01"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size = 1
      """
    并且记录响应字段 "body.json.data[0].id" 为 "dispatch.id"
    当GET "/dispatchlist/pick-list?dispatch_id=${dispatch.id}"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size = 1
      body.json.data[0].pick_qty = 5
      body.json.data[0].picked_qty = 0
      """
    并且记录响应字段 "body.json.data[0].id" 为 "pick.id"
    当PUT "/dispatchlist/confirm-pick-items":
      """
      {
        "pick_detail_ids": [${pick.id}]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    并且所有"发货单"应为:
      """
      : [{
        dispatch_no: 'DP-E2E-PICK-ITEM-01'
        sku_code: 'SKU-E2E-PICK-ITEM'
        dispatch_status: 2
        picked_qty: 0
        pick_checker_id: 0
        pick_checker: ''
      }]
      """
    并且所有"拣货明细"应为:
      """
      : [{
        dispatch_no: 'DP-E2E-PICK-ITEM-01'
        sku_code: 'SKU-E2E-PICK-ITEM'
        pick_qty: 5
        picked_qty: 5
        picker_id: 1
        picker: 'Administrator'
        is_update_stock: false
      }]
      """
    当GET "/dispatchlist/pick-list?dispatch_id=${dispatch.id}"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data[0].picked_qty = 5
      body.json.data[0].picker_id = 1
      body.json.data[0].picker = 'Administrator'
      """
    当PUT "/dispatchlist/revoke-pick-items":
      """
      {
        "pick_detail_ids": [${pick.id}]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    并且所有"拣货明细"应为:
      """
      : [{
        dispatch_no: 'DP-E2E-PICK-ITEM-01'
        sku_code: 'SKU-E2E-PICK-ITEM'
        pick_qty: 5
        picked_qty: 0
        picker_id: 0
        picker: ''
        is_update_stock: false
      }]
      """
    当GET "/dispatchlist/pick-list?dispatch_id=${dispatch.id}"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data[0].picked_qty = 0
      body.json.data[0].picker_id = 0
      body.json.data[0].picker = ''
      """

  场景: 整单复核会记录复核员并兼容未先逐条确认的旧流程
    假如以管理员登录
    并且存在"可用库存":
      | warehouse.key | warehouse.name              | area.key | area.name                   | area.property | location.key | location.code                 | goods_owner.key | goods_owner.name        | customer.name          | category.name         | spu.key | spu.code               | sku.key | sku.code               | qty | dispatch_no               | dispatch_status | dispatch_qty | dispatch_lock_qty | series_number           | expiry_date | price | putaway_date |
      | main          | WH-E2E-PICK-REVIEW         | main     | AREA-E2E-PICK-REVIEW        | 1             | main         | LOC-E2E-PICK-REVIEW-01        | main            | 练习货主-PICK-REVIEW    | 练习客户-PICK-REVIEW    | 分类-PICK-REVIEW       | item    | SPU-E2E-PICK-REVIEW     | item    | SKU-E2E-PICK-REVIEW     | 8   | DP-E2E-PICK-REVIEW-01   | 2               | 5            | 5                 | SN-E2E-PICK-REVIEW-01   | 2026-12-31  | 11.5  | 2026-05-01   |
    当PUT "/dispatchlist/confirm-pick-dispatchlistno?dispatch_no=DP-E2E-PICK-REVIEW-01":
      """
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    并且所有"发货单"应为:
      """
      : [{
        dispatch_no: 'DP-E2E-PICK-REVIEW-01'
        sku_code: 'SKU-E2E-PICK-REVIEW'
        dispatch_status: 3
        picked_qty: 5
        pick_checker_id: 1
        pick_checker: 'Administrator'
      }]
      """
    并且所有"拣货明细"应为:
      """
      : [{
        dispatch_no: 'DP-E2E-PICK-REVIEW-01'
        sku_code: 'SKU-E2E-PICK-REVIEW'
        pick_qty: 5
        picked_qty: 5
        picker_id: 1
        picker: 'Administrator'
        is_update_stock: false
      }]
      """
