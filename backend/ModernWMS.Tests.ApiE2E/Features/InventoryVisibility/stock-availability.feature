# language: zh-CN
功能: 库存可用量

  场景: 冻结库存和残次区库存不增加正常可用量
    假如以管理员登录
    并且存在"可用库存":
      | sku.code        | location.code    | goods_owner.name | area.property | qty | is_freeze |
      | SKU-E2E-STK-001 | LOC-E2E-STK-01   | 练习货主-STK     | 1             | 12  | false     |
      | SKU-E2E-STK-001 | LOC-E2E-STK-FRZ  | 练习货主-STK     | 1             | 3   | true      |
      | SKU-E2E-STK-001 | LOC-E2E-STK-DMG  | 练习货主-STK     | 5             | 4   | false     |
    当POST "/stock/stock-list":
      """
      { "pageIndex": 1, "pageSize": 20, "searchObjects": [] }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    那么所有"库存视图"应为:
      """
      = [{
        sku_code: 'SKU-E2E-STK-001'
        qty: 19
        qty_frozen: 3
        qty_locked: 0
        qty_available: 12
      }]
      """
