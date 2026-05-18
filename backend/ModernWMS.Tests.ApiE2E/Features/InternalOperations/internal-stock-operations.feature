# language: zh-CN
功能: 库内作业

  场景: 移库确认后源库位减少且重复确认被拒绝
    假如以管理员登录
    并且存在"可用库存":
      | warehouse.key | warehouse.name | area.key | area.name          | area.property | location.key | location.code         | goods_owner.key | goods_owner.name | supplier.name   | customer.name | category.name | spu.key | spu.code        | sku.key | sku.code        | qty | is_freeze | series_number      | expiry_date | price | putaway_date |
      | main          | WH-E2E-INT-MV  | src      | AREA-E2E-INT-MV-S  | 1             | src          | LOC-E2E-INT-MV-SRC    | main            | 练习货主-INT-MV  | 练习供应商-INT-MV | 练习客户-INT-MV | 分类-INT-MV   | item    | SPU-E2E-INT-MV | item    | SKU-E2E-INT-MV | 6   | false     | SN-E2E-INT-MV-01   | 2026-12-31  | 10.5  | 2026-05-01   |
      | main          | WH-E2E-INT-MV  | dst      | AREA-E2E-INT-MV-D  | 1             | dst          | LOC-E2E-INT-MV-DST    | main            | 练习货主-INT-MV  | 练习供应商-INT-MV | 练习客户-INT-MV | 分类-INT-MV   | item    | SPU-E2E-INT-MV | item    | SKU-E2E-INT-MV | 0   | false     | SN-E2E-INT-MV-01   | 2026-12-31  | 10.5  | 2026-05-01   |
    当POST "/stockmove":
      """
      {
        "sku_id": ${sku.item.id},
        "orig_goods_location_id": ${location.src.id},
        "dest_googs_location_id": ${location.dst.id},
        "qty": 4,
        "goods_owner_id": ${goods_owner.main.id},
        "series_number": "SN-E2E-INT-MV-01",
        "expiry_date": "2026-12-31T00:00:00",
        "price": 10.5,
        "putaway_date": "2026-05-01T00:00:00"
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data > 0
      """
    并且记录响应字段 "body.json.data" 为 "move.id"
    当GET "/stockmove?id=${move.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          id: *
          job_code: *
          move_status: 0
          sku_code: 'SKU-E2E-INT-MV'
          qty: 4
          orig_goods_location_name: 'LOC-E2E-INT-MV-SRC'
          dest_googs_location_name: 'LOC-E2E-INT-MV-DST'
          series_number: 'SN-E2E-INT-MV-01'
        }
      }
      """
    并且记录响应字段 "body.json.data.job_code" 为 "move.job_code"
    当POST "/stockmove/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "job_code", "operator": 1, "text": "${move.job_code}", "value": "${move.job_code}" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            job_code: *
            move_status: 0
            sku_code: 'SKU-E2E-INT-MV'
            qty: 4
          }]
        }
      }
      """
    当PUT "/stockmove?id=${move.id}":
      """
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当GET "/stockmove/all"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size > 0
      """
    当POST "/stock/location-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "location_name", "operator": 1, "text": "LOC-E2E-INT-MV-SRC", "value": "LOC-E2E-INT-MV-SRC" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            sku_code: 'SKU-E2E-INT-MV'
            location_name: 'LOC-E2E-INT-MV-SRC'
            qty: 2
            qty_available: 2
            qty_locked: 0
            qty_frozen: 0
          }]
        }
      }
      """
    当POST "/stock/location-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "location_name", "operator": 1, "text": "LOC-E2E-INT-MV-DST", "value": "LOC-E2E-INT-MV-DST" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            sku_code: 'SKU-E2E-INT-MV'
            location_name: 'LOC-E2E-INT-MV-DST'
            qty: 4
            qty_available: 4
            qty_locked: 0
            qty_frozen: 0
          }]
        }
      }
      """
    当PUT "/stockmove?id=${move.id}":
      """
      """
    那么response body should match:
      """
      : { isSuccess: false }
      """
    当DELETE "/stockmove?id=${move.id}"
    那么response body should match:
      """
      : { isSuccess: false }
      """

  场景: 冻结与解冻任务通过真实API改变库存可用量
    假如以管理员登录
    并且存在"可用库存":
      | warehouse.key | warehouse.name  | area.key | area.name           | area.property | location.key | location.code         | goods_owner.key | goods_owner.name  | supplier.name    | customer.name  | category.name  | spu.key | spu.code         | sku.key | sku.code         | qty | is_freeze | series_number       |
      | main          | WH-E2E-INT-FRZ  | normal   | AREA-E2E-INT-FRZ-N  | 1             | normal       | LOC-E2E-INT-FRZ-01    | main            | 练习货主-INT-FRZ  | 练习供应商-INT-FRZ | 练习客户-INT-FRZ | 分类-INT-FRZ  | item    | SPU-E2E-INT-FRZ | item    | SKU-E2E-INT-FRZ | 5   | false     | SN-E2E-INT-FRZ-01  |
    当POST "/stockfreeze":
      """
      {
        "job_type": true,
        "sku_id": ${sku.item.id},
        "goods_owner_id": ${goods_owner.main.id},
        "goods_location_id": ${location.normal.id},
        "series_number": "SN-E2E-INT-FRZ-01"
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data > 0
      """
    并且记录响应字段 "body.json.data" 为 "freeze.id"
    当GET "/stockfreeze?id=${freeze.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          id: *
          job_code: *
          job_type: true
          sku_code: 'SKU-E2E-INT-FRZ'
          location_name: 'LOC-E2E-INT-FRZ-01'
          warehouse_name: 'WH-E2E-INT-FRZ'
          series_number: 'SN-E2E-INT-FRZ-01'
        }
      }
      """
    当POST "/stock/stock-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "sku_code", "operator": 1, "text": "SKU-E2E-INT-FRZ", "value": "SKU-E2E-INT-FRZ" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            sku_code: 'SKU-E2E-INT-FRZ'
            qty: 5
            qty_frozen: 5
            qty_locked: 0
            qty_available: 0
          }]
        }
      }
      """
    当POST "/stockfreeze":
      """
      {
        "job_type": false,
        "sku_id": ${sku.item.id},
        "goods_owner_id": ${goods_owner.main.id},
        "goods_location_id": ${location.normal.id},
        "series_number": "SN-E2E-INT-FRZ-01"
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data > 0
      """
    当POST "/stockfreeze/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "sku_code", "operator": 1, "text": "SKU-E2E-INT-FRZ", "value": "SKU-E2E-INT-FRZ" }
        ]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.totals = 2
      """
    当GET "/stockfreeze/all"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size > 1
      """
    当POST "/stock/stock-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "sku_code", "operator": 1, "text": "SKU-E2E-INT-FRZ", "value": "SKU-E2E-INT-FRZ" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            sku_code: 'SKU-E2E-INT-FRZ'
            qty: 5
            qty_frozen: 0
            qty_locked: 0
            qty_available: 5
          }]
        }
      }
      """

  场景: 加工任务先锁定源库存再生成源负调整和目标正调整
    假如以管理员登录
    并且存在"可用库存":
      | warehouse.key | warehouse.name   | area.key | area.name            | area.property | location.key | location.code            | goods_owner.key | goods_owner.name  | supplier.name     | customer.name   | category.name   | spu.key | spu.code            | sku.key | sku.code                | qty | is_freeze | series_number         | expiry_date | price | putaway_date |
      | main          | WH-E2E-INT-PROC  | source   | AREA-E2E-INT-PROC-S  | 1             | source       | LOC-E2E-INT-PROC-SRC     | main            | 练习货主-INT-PROC | 练习供应商-INT-PROC | 练习客户-INT-PROC | 分类-INT-PROC | source  | SPU-E2E-INT-PROC-S  | source  | SKU-E2E-INT-PROC-SRC   | 6   | false     | SN-E2E-INT-PROC-01   | 2026-12-31  | 12.5  | 2026-05-01   |
      | main          | WH-E2E-INT-PROC  | target   | AREA-E2E-INT-PROC-T  | 1             | target       | LOC-E2E-INT-PROC-DST     | main            | 练习货主-INT-PROC | 练习供应商-INT-PROC | 练习客户-INT-PROC | 分类-INT-PROC | target  | SPU-E2E-INT-PROC-T  | target  | SKU-E2E-INT-PROC-DST   | 0   | false     | SN-E2E-INT-PROC-OUT  | 2027-12-31  | 22.5  | 2026-05-18   |
    当POST "/stockprocess":
      """
      {
        "job_type": false,
        "process_status": false,
        "detailList": [
          {
            "sku_id": ${sku.source.id},
            "goods_owner_id": ${goods_owner.main.id},
            "goods_location_id": ${location.source.id},
            "qty": 4,
            "is_source": true,
            "series_number": "SN-E2E-INT-PROC-01",
            "expiry_date": "2026-12-31T00:00:00",
            "price": 12.5,
            "putaway_date": "2026-05-01T00:00:00"
          },
          {
            "sku_id": ${sku.target.id},
            "goods_owner_id": ${goods_owner.main.id},
            "goods_location_id": ${location.target.id},
            "qty": 4,
            "is_source": false,
            "series_number": "SN-E2E-INT-PROC-OUT",
            "expiry_date": "2027-12-31T00:00:00",
            "price": 22.5,
            "putaway_date": "2026-05-18T00:00:00"
          }
        ]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data > 0
      """
    并且记录响应字段 "body.json.data" 为 "process.id"
    当GET "/stockprocess?id=${process.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          id: *
          job_code: *
          job_type: false
          process_status: false
          adjust_status: false
          source_detail_list: [{
            sku_code: 'SKU-E2E-INT-PROC-SRC'
            qty: 4
            series_number: 'SN-E2E-INT-PROC-01'
          }]
          target_detail_list: [{
            sku_code: 'SKU-E2E-INT-PROC-DST'
            qty: 4
            location_name: 'LOC-E2E-INT-PROC-DST'
            series_number: 'SN-E2E-INT-PROC-OUT'
          }]
        }
      }
      """
    并且记录响应字段 "body.json.data.job_code" 为 "process.job_code"
    当POST "/stockprocess/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "job_code", "operator": 1, "text": "${process.job_code}", "value": "${process.job_code}" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            job_code: *
            process_status: false
            adjust_status: false
          }]
        }
      }
      """
    当POST "/stock/location-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "location_name", "operator": 1, "text": "LOC-E2E-INT-PROC-SRC", "value": "LOC-E2E-INT-PROC-SRC" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            sku_code: 'SKU-E2E-INT-PROC-SRC'
            qty: 6
            qty_locked: 4
            qty_available: 2
            qty_frozen: 0
          }]
        }
      }
      """
    当PUT "/stockprocess/process-confirm?id=${process.id}":
      """
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当PUT "/stockprocess/process-confirm?id=${process.id}":
      """
      """
    那么response body should match:
      """
      : { isSuccess: false }
      """
    当PUT "/stockprocess/adjustment-confirm?id=${process.id}":
      """
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当GET "/stockprocess/all"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size > 0
      """
    当POST "/stockprocess/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "job_code", "operator": 1, "text": "${process.job_code}", "value": "${process.job_code}" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            job_code: *
            process_status: true
            adjust_status: true
          }]
        }
      }
      """
    当POST "/stock/location-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "location_name", "operator": 1, "text": "LOC-E2E-INT-PROC-SRC", "value": "LOC-E2E-INT-PROC-SRC" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            sku_code: 'SKU-E2E-INT-PROC-SRC'
            qty: 2
            qty_locked: 0
            qty_available: 2
            qty_frozen: 0
          }]
        }
      }
      """
    当POST "/stock/location-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "location_name", "operator": 1, "text": "LOC-E2E-INT-PROC-DST", "value": "LOC-E2E-INT-PROC-DST" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            sku_code: 'SKU-E2E-INT-PROC-DST'
            qty: 4
            qty_locked: 0
            qty_available: 4
            qty_frozen: 0
          }]
        }
      }
      """
    当POST "/stockadjust/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "sku_code", "operator": 1, "text": "SKU-E2E-INT-PROC-SRC", "value": "SKU-E2E-INT-PROC-SRC" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            sku_code: 'SKU-E2E-INT-PROC-SRC'
            job_type: 2
            qty: -4
          }]
        }
      }
      """
    当POST "/stockadjust/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "sku_code", "operator": 1, "text": "SKU-E2E-INT-PROC-DST", "value": "SKU-E2E-INT-PROC-DST" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            sku_code: 'SKU-E2E-INT-PROC-DST'
            job_type: 2
            qty: 4
          }]
        }
      }
      """

  场景: 盘点差异确认后生成库存调整且重复确认被拒绝
    假如以管理员登录
    并且存在"可用库存":
      | warehouse.key | warehouse.name   | area.key | area.name            | area.property | location.key | location.code            | goods_owner.key | goods_owner.name   | supplier.name      | customer.name    | category.name    | spu.key | spu.code            | sku.key | sku.code              | qty | is_freeze | series_number          | expiry_date | price | putaway_date |
      | main          | WH-E2E-INT-TAKE  | normal   | AREA-E2E-INT-TAKE-N  | 1             | normal       | LOC-E2E-INT-TAKE-01      | main            | 练习货主-INT-TAKE  | 练习供应商-INT-TAKE | 练习客户-INT-TAKE | 分类-INT-TAKE  | item    | SPU-E2E-INT-TAKE   | item    | SKU-E2E-INT-TAKE     | 8   | false     | SN-E2E-INT-TAKE-01    | 2026-12-31  | 9.9   | 2026-05-01   |
    当POST "/stocktaking":
      """
      {
        "sku_id": ${sku.item.id},
        "goods_owner_id": ${goods_owner.main.id},
        "goods_location_id": ${location.normal.id},
        "book_qty": 8,
        "series_number": "SN-E2E-INT-TAKE-01",
        "expiry_date": "2026-12-31T00:00:00",
        "price": 9.9,
        "putaway_date": "2026-05-01T00:00:00"
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data > 0
      """
    并且记录响应字段 "body.json.data" 为 "taking.id"
    当GET "/stocktaking?id=${taking.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          id: *
          job_code: *
          job_status: false
          adjust_status: false
          sku_code: 'SKU-E2E-INT-TAKE'
          book_qty: 8
          counted_qty: 0
          difference_qty: 0
          location_name: 'LOC-E2E-INT-TAKE-01'
          series_number: 'SN-E2E-INT-TAKE-01'
        }
      }
      """
    并且记录响应字段 "body.json.data.job_code" 为 "taking.job_code"
    当POST "/stocktaking/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "job_code", "operator": 1, "text": "${taking.job_code}", "value": "${taking.job_code}" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            job_code: *
            job_status: false
            adjust_status: false
            sku_code: 'SKU-E2E-INT-TAKE'
          }]
        }
      }
      """
    当PUT "/stocktaking":
      """
      {
        "id": ${taking.id},
        "counted_qty": 5
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当GET "/stocktaking?id=${taking.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          job_status: true
          counted_qty: 5
          difference_qty: -3
          sku_code: 'SKU-E2E-INT-TAKE'
          location_name: 'LOC-E2E-INT-TAKE-01'
        }
      }
      """
    当PUT "/stocktaking/adjustment-confirm?id=${taking.id}":
      """
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当PUT "/stocktaking/adjustment-confirm?id=${taking.id}":
      """
      """
    那么response body should match:
      """
      : { isSuccess: false }
      """
    当POST "/stock/location-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "location_name", "operator": 1, "text": "LOC-E2E-INT-TAKE-01", "value": "LOC-E2E-INT-TAKE-01" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            sku_code: 'SKU-E2E-INT-TAKE'
            qty: 5
            qty_locked: 0
            qty_available: 5
            qty_frozen: 0
          }]
        }
      }
      """
    当POST "/stockadjust/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "sku_code", "operator": 1, "text": "SKU-E2E-INT-TAKE", "value": "SKU-E2E-INT-TAKE" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            job_code: *
            sku_code: 'SKU-E2E-INT-TAKE'
            job_type: 1
            qty: -3
          }]
        }
      }
      """
