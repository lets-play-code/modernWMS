# language: zh-CN
功能: 出库履约

  场景: 已确认发货单锁定库存但不扣减库存
    假如以管理员登录
    并且存在"已锁库 发货单":
      | dispatch_no   | sku.code       | customer.name | goods_owner.name | location.code  | stock_qty | qty | lock_qty |
      | DP-E2E-OUT-01 | SKU-E2E-OUT-01 | 练习客户-OUT  | 练习货主-OUT     | LOC-E2E-OUT-01 | 12        | 8   | 8        |
    当GET "/dispatchlist/by-dispatch_no?dispatch_no=DP-E2E-OUT-01"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size > 0
      """
    那么所有"发货单"应为:
      """
      = [{
        dispatch_no: 'DP-E2E-OUT-01'
        sku_code: 'SKU-E2E-OUT-01'
        dispatch_status: 2
        qty: 8
        lock_qty: 8
      }]
      """
    并且所有"拣货明细"应为:
      """
      = [{
        dispatch_no: 'DP-E2E-OUT-01'
        sku_code: 'SKU-E2E-OUT-01'
        pick_qty: 8
        is_update_stock: false
      }]
      """
    并且所有"库存视图"应为:
      """
      = [{
        sku_code: 'SKU-E2E-OUT-01'
        qty: 12
        qty_frozen: 0
        qty_locked: 8
        qty_available: 4
      }]
      """
