# language: zh-CN
功能: 库存可视化

  场景: 冻结、残次和跨流程锁定共同影响库存汇总可用量
    假如以管理员登录
    并且存在"可用库存":
      | sku.code         | location.code     | goods_owner.name  | area.property | qty | is_freeze | dispatch_lock_qty | process_locked_qty | move_locked_qty |
      | SKU-E2E-STK-001  | LOC-E2E-STK-N-01  | 练习货主-STK-001  | 1             | 20  | false     | 5                 | 2                  | 1               |
      | SKU-E2E-STK-001  | LOC-E2E-STK-N-01  | 练习货主-STK-001  | 1             | 3   | true      | 0                 | 0                  | 0               |
      | SKU-E2E-STK-001  | LOC-E2E-STK-D-01  | 练习货主-STK-001  | 5             | 4   | false     | 0                 | 0                  | 0               |
    当POST "/stock/stock-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "sku_code", "operator": 1, "text": "SKU-E2E-STK-001", "value": "SKU-E2E-STK-001" }
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
            sku_code: 'SKU-E2E-STK-001'
            qty: 27
            qty_frozen: 3
            qty_locked: 8
            qty_available: 12
          }]
        }
      }
      """

  场景: 库位库存与库存选择查询区分可承诺库存和冻结库存
    假如以管理员登录
    并且存在"可用库存":
      | sku.code         | location.code     | goods_owner.name  | area.property | qty | is_freeze | series_number | dispatch_lock_qty |
      | SKU-E2E-SEL-001  | LOC-E2E-SEL-01    | 练习货主-SEL-001  | 1             | 5   | false     | SER-AVL       | 0                 |
      | SKU-E2E-SEL-002  | LOC-E2E-SEL-01    | 练习货主-SEL-001  | 1             | 6   | false     | SER-LCK       | 6                 |
      | SKU-E2E-SEL-003  | LOC-E2E-SEL-01    | 练习货主-SEL-001  | 1             | 4   | true      | SER-FRZ       | 0                 |
    当POST "/stock/location-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "goods_owner_name", "operator": 1, "text": "练习货主-SEL-001", "value": "练习货主-SEL-001" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 3
          rows: [{
            sku_code: 'SKU-E2E-SEL-001'
            qty: 5
            qty_available: 5
            qty_locked: 0
            qty_frozen: 0
            series_number: 'SER-AVL'
          }, {
            sku_code: 'SKU-E2E-SEL-002'
            qty: 6
            qty_available: 0
            qty_locked: 6
            qty_frozen: 0
            series_number: 'SER-LCK'
          }, {
            sku_code: 'SKU-E2E-SEL-003'
            qty: 4
            qty_available: 0
            qty_locked: 0
            qty_frozen: 4
            series_number: 'SER-FRZ'
          }]
        }
      }
      """
    当POST "/stock/select":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "goods_owner_name", "operator": 1, "text": "练习货主-SEL-001", "value": "练习货主-SEL-001" }
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
            sku_code: 'SKU-E2E-SEL-001'
            qty_available: 5
            is_freeze: false
            series_number: 'SER-AVL'
          }]
        }
      }
      """
    当POST "/stock/select":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "sqlTitle": "all",
        "searchObjects": [
          { "name": "goods_owner_name", "operator": 1, "text": "练习货主-SEL-001", "value": "练习货主-SEL-001" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 3
          rows: [{
            sku_code: 'SKU-E2E-SEL-001'
            qty_available: 5
            is_freeze: false
            series_number: 'SER-AVL'
          }, {
            sku_code: 'SKU-E2E-SEL-002'
            qty_available: 0
            is_freeze: false
            series_number: 'SER-LCK'
          }, {
            sku_code: 'SKU-E2E-SEL-003'
            qty_available: 0
            is_freeze: true
            series_number: 'SER-FRZ'
          }]
        }
      }
      """
    当POST "/stock/select":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "sqlTitle": "frozen",
        "searchObjects": [
          { "name": "goods_owner_name", "operator": 1, "text": "练习货主-SEL-001", "value": "练习货主-SEL-001" }
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
            sku_code: 'SKU-E2E-SEL-003'
            qty_available: 0
            is_freeze: true
            series_number: 'SER-FRZ'
          }]
        }
      }
      """

  场景: 安全库存视图按仓库返回阈值和可用量
    假如以管理员登录
    并且存在"可用库存":
      | warehouse.name  | sku.code         | location.code     | goods_owner.name  | area.property | qty | is_freeze | safety_stock_qty |
      | WH-E2E-SFT-001  | SKU-E2E-SFT-001  | LOC-E2E-SFT-N-01  | 练习货主-SFT-001  | 1             | 10  | false     | 15               |
      | WH-E2E-SFT-001  | SKU-E2E-SFT-001  | LOC-E2E-SFT-N-01  | 练习货主-SFT-001  | 1             | 2   | true      | 15               |
      | WH-E2E-SFT-001  | SKU-E2E-SFT-001  | LOC-E2E-SFT-D-01  | 练习货主-SFT-001  | 5             | 3   | false     | 15               |
    当POST "/stock/safety-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "sku_code", "operator": 1, "text": "SKU-E2E-SFT-001", "value": "SKU-E2E-SFT-001" }
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
            warehouse_name: 'WH-E2E-SFT-001'
            sku_code: 'SKU-E2E-SFT-001'
            qty: 15
            qty_frozen: 2
            qty_locked: 0
            qty_available: 10
            safety_stock_qty: 15
          }]
        }
      }
      """

  场景: 库龄查询按库存日期和有效期范围返回分析视图
    假如以管理员登录
    并且存在"可用库存":
      | warehouse.name  | sku.code         | location.code     | goods_owner.name  | area.property | qty | is_freeze | putaway_date | expiry_date |
      | WH-E2E-AGE-001  | SKU-E2E-AGE-001  | LOC-E2E-AGE-01    | 练习货主-AGE-001  | 1             | 7   | false     | 2026-01-01   | 2026-12-31  |
    当POST "/stock/stock-age-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "sku_code": "SKU-E2E-AGE-001",
        "stock_age_from": 30,
        "stock_age_to": 600,
        "expiry_date_from": "2026-12-01T00:00:00",
        "expiry_date_to": "2027-01-31T00:00:00"
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.totals = 1
      body.json.data.rows[0].stock_age > 30
      """
    那么response body should match:
      """
      : {
        data: {
          rows: [{
            warehouse_name: 'WH-E2E-AGE-001'
            sku_code: 'SKU-E2E-AGE-001'
            qty: 7
          }]
        }
      }
      """

  场景: 出库统计查询汇总已出库数量与金额
    假如以管理员登录
    并且存在"可用库存":
      | warehouse.name  | sku.code         | location.code     | goods_owner.name  | customer.name   | area.property | qty | is_freeze | dispatch_no       | dispatch_status | dispatch_qty | dispatch_picked_qty | sku.price | delivery_date        |
      | WH-E2E-DEL-001  | SKU-E2E-DEL-001  | LOC-E2E-DEL-01    | 练习货主-DEL-001  | 练习客户-DEL-001 | 1             | 5   | false     | DP-E2E-DEL-001    | 6               | 3            | 3                   | 12.25     | 2026-05-10 09:30:00 |
    当POST "/stock/delivery-list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "sku_code": "SKU-E2E-DEL-001",
        "customer_name": "练习客户-DEL-001",
        "goods_owner_name": "练习货主-DEL-001",
        "delivery_date_from": "2026-05-01T00:00:00",
        "delivery_date_to": "2026-05-31T23:59:59"
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          totals: 1
          rows: [{
            dispatch_no: 'DP-E2E-DEL-001'
            sku_code: 'SKU-E2E-DEL-001'
            customer_name: '练习客户-DEL-001'
            goods_owner_name: '练习货主-DEL-001'
            delivery_qty: 3
            delivery_amount: 36.75
          }]
        }
      }
      """
