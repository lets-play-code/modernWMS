# language: zh-CN
功能: 仓库与SKU主数据

  场景: 仓库拓扑和SKU主数据可被准备并通过API观察
    假如以管理员登录
    并且存在"仓库和SKU":
      | warehouse.name | area.name     | area.property | location.code | goods_owner.name | supplier.name | customer.name | category.name | spu.code       | sku.code       |
      | WH-E2E-MD-001  | AREA-E2E-MD-1 | 1             | LOC-E2E-MD-01 | 练习货主-MD      | 练习供应商-MD | 练习客户-MD   | 练习分类-MD   | SPU-E2E-MD-001 | SKU-E2E-MD-001 |
    当POST "/warehouse/list":
      """
      { "pageIndex": 1, "pageSize": 20, "searchObjects": [] }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.rows.size > 0
      """
    那么所有"主数据骨架"应为:
      """
      = [{
        warehouse_name: 'WH-E2E-MD-001'
        location_code: 'LOC-E2E-MD-01'
        goods_owner_name: '练习货主-MD'
        supplier_name: '练习供应商-MD'
        customer_name: '练习客户-MD'
        category_name: '练习分类-MD'
        spu_code: 'SPU-E2E-MD-001'
        sku_code: 'SKU-E2E-MD-001'
      }]
      """
