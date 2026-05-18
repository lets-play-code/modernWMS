# language: zh-CN
功能: 库内作业

  场景: 冻结任务影响库存可用量并可通过库内作业API观察
    假如以管理员登录
    并且存在"冻结库存任务":
      | job_code        | sku.code       | goods_owner.name | location.code | qty |
      | FRZ-E2E-INT-01  | SKU-E2E-INT-01 | 练习货主-INT     | LOC-E2E-INT-01 | 10  |
    当POST "/stockfreeze/list":
      """
      { "pageIndex": 1, "pageSize": 20, "searchObjects": [] }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    那么所有"冻结任务"应为:
      """
      = [{
        job_code: 'FRZ-E2E-INT-01'
        sku_code: 'SKU-E2E-INT-01'
        qty: 10
        job_type: true
      }]
      """
    并且所有"库存视图"应为:
      """
      = [{
        sku_code: 'SKU-E2E-INT-01'
        qty: 10
        qty_frozen: 10
        qty_locked: 0
        qty_available: 0
      }]
      """
