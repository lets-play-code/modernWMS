# language: zh-CN
功能: 仓库与SKU主数据

  场景: 仓库拓扑和SKU主数据可被准备并通过API观察
    假如以管理员登录
    并且存在"仓库和SKU":
      | warehouse.name | area.name     | area.property | location.code | goods_owner.name | supplier.name | customer.name | category.name | spu.code       | sku.code       |
      | WH-E2E-MD-001  | AREA-E2E-MD-1 | 1             | LOC-E2E-MD-01 | 练习货主-MD      | 练习供应商-MD | 练习客户-MD   | 练习分类-MD   | SPU-E2E-MD-001 | SKU-E2E-MD-001 |
    当POST "/warehouse/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "warehouse_name", "operator": 1, "text": "WH-E2E-MD-001", "value": "WH-E2E-MD-001" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          rows: [{
            warehouse_name: 'WH-E2E-MD-001'
            city: '测试城市'
            address: '测试地址'
          }]
        }
      }
      """
    当POST "/warehousearea/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "area_name", "operator": 1, "text": "AREA-E2E-MD-1", "value": "AREA-E2E-MD-1" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          rows: [{
            area_name: 'AREA-E2E-MD-1'
            warehouse_name: 'WH-E2E-MD-001'
            area_property: 1
          }]
        }
      }
      """
    当POST "/goodslocation/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "location_name", "operator": 1, "text": "LOC-E2E-MD-01", "value": "LOC-E2E-MD-01" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          rows: [{
            location_name: 'LOC-E2E-MD-01'
            warehouse_name: 'WH-E2E-MD-001'
            warehouse_area_name: 'AREA-E2E-MD-1'
          }]
        }
      }
      """
    当POST "/goodsowner/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "goods_owner_name", "operator": 1, "text": "练习货主-MD", "value": "练习货主-MD" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          rows: [{ goods_owner_name: '练习货主-MD' }]
        }
      }
      """
    当POST "/supplier/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "supplier_name", "operator": 1, "text": "练习供应商-MD", "value": "练习供应商-MD" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          rows: [{ supplier_name: '练习供应商-MD' }]
        }
      }
      """
    当POST "/customer/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "customer_name", "operator": 1, "text": "练习客户-MD", "value": "练习客户-MD" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          rows: [{ customer_name: '练习客户-MD' }]
        }
      }
      """
    当GET "/category/all"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size > 0
      """
    当POST "/spu/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "spu_code", "operator": 1, "text": "SPU-E2E-MD-001", "value": "SPU-E2E-MD-001" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          rows: [{
            spu_code: 'SPU-E2E-MD-001'
            category_name: '练习分类-MD'
            supplier_name: '练习供应商-MD'
            detailList: [{ sku_code: 'SKU-E2E-MD-001' }]
          }]
        }
      }
      """
    当GET "/spu/sku-bar-code?bar_code=SKU-E2E-MD-001"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          spu_code: 'SPU-E2E-MD-001'
          sku_code: 'SKU-E2E-MD-001'
          category_name: '练习分类-MD'
        }
      }
      """
    当GET "/spu?id=${spu.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          spu_code: 'SPU-E2E-MD-001'
          category_name: '练习分类-MD'
          detailList: [{ sku_code: 'SKU-E2E-MD-001' }]
        }
      }
      """
    当GET "/spu/sku?sku_id=${sku.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          spu_code: 'SPU-E2E-MD-001'
          sku_code: 'SKU-E2E-MD-001'
        }
      }
      """
    当PUT "/spu/sku-safety-stock":
      """
      {
        "sku_id": ${sku.id},
        "detailList": [
          { "id": 0, "sku_id": ${sku.id}, "warehouse_id": ${warehouse.id}, "warehouse_name": "WH-E2E-MD-001", "safety_stock_qty": 6 }
        ]
      }
      """
    那么response body should match:
      """
      : { isSuccess: true }
      """
    当GET "/spu?id=${spu.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          detailList: [{
            sku_code: 'SKU-E2E-MD-001'
            detailList: [{
              warehouse_name: 'WH-E2E-MD-001'
              safety_stock_qty: 6
            }]
          }]
        }
      }
      """
    当POST "/spu":
      """
      {
        "spu_code": "SPU-E2E-MD-API-001",
        "spu_name": "SPU-E2E-MD-API-001",
        "category_id": ${category.id},
        "category_name": "练习分类-MD",
        "supplier_id": ${supplier.id},
        "supplier_name": "练习供应商-MD",
        "length_unit": 1,
        "volume_unit": 2,
        "detailList": [
          {
            "sku_code": "SKU-E2E-MD-API-001",
            "sku_name": "SKU-E2E-MD-API-001",
            "bar_code": "SKU-E2E-MD-API-001",
            "lenght": 10,
            "width": 5,
            "height": 2,
            "unit": "EA"
          }
        ]
      }
      """
    那么response body should match:
      """
      : { isSuccess: true data: * }
      """
    当POST "/spu":
      """
      {
        "spu_code": "SPU-E2E-MD-API-001",
        "spu_name": "SPU-E2E-MD-API-001",
        "category_id": ${category.id},
        "category_name": "练习分类-MD",
        "supplier_id": ${supplier.id},
        "supplier_name": "练习供应商-MD",
        "detailList": []
      }
      """
    那么response body should match:
      """
      : { isSuccess: false }
      """
    当POST "/spu/addlist":
      """
      [
        {
          "spu_code": "SPU-E2E-MD-DUP",
          "spu_name": "重复SPU",
          "category_name": "练习分类-MD",
          "supplier_name": "练习供应商-MD",
          "detailList": []
        },
        {
          "spu_code": "SPU-E2E-MD-DUP",
          "spu_name": "重复SPU",
          "category_name": "练习分类-MD",
          "supplier_name": "练习供应商-MD",
          "detailList": []
        }
      ]
      """
    那么response body should match:
      """
      : { isSuccess: false }
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
