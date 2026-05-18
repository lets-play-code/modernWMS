# language: zh-CN
功能: ASN入库执行

  场景: ASN 可经由创建到上架的完整链路形成正常库存与残次库存
    假如以管理员登录
    并且存在"仓库和SKU":
      | warehouse.key | warehouse.name | area.key | area.name       | area.property | location.key | location.code  | goods_owner.key | goods_owner.name | supplier.key | supplier.name | customer.name | category.name | spu.key | spu.code        | sku.key | sku.code        |
      | main          | WH-E2E-IN-001  | normal   | AREA-E2E-IN-N   | 1             | normal       | LOC-E2E-IN-N1 | main            | 练习货主-IN      | main         | 练习供应商-IN  | 练习客户-IN   | 分类-IN       | item    | SPU-E2E-IN-001 | item    | SKU-E2E-IN-001 |
      | main          | WH-E2E-IN-001  | damage   | AREA-E2E-IN-D   | 5             | damage       | LOC-E2E-IN-D1 | main            | 练习货主-IN      | main         | 练习供应商-IN  | 练习客户-IN   | 分类-IN       | item    | SPU-E2E-IN-001 | item    | SKU-E2E-IN-001 |
    当POST "/asn/asnmaster":
      """
      {
        "asn_batch": "ASN-BATCH-E2E-001",
        "estimated_arrival_time": "2026-05-18",
        "goods_owner_id": ${goods_owner.main.id},
        "goods_owner_name": "练习货主-IN",
        "weight": 12.5,
        "volume": 3.5,
        "detailList": [
          {
            "spu_id": ${spu.item.id},
            "spu_code": "SPU-E2E-IN-001",
            "spu_name": "SPU-E2E-IN-001",
            "sku_id": ${sku.item.id},
            "sku_code": "SKU-E2E-IN-001",
            "sku_name": "SKU-E2E-IN-001",
            "asn_qty": 8,
            "actual_qty": 0,
            "weight": 12.5,
            "volume": 3.5,
            "supplier_id": ${supplier.main.id},
            "supplier_name": "练习供应商-IN",
            "price": 19.9
          }
        ]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data > 0
      """
    并且记录响应字段 "body.json.data" 为 "asnmaster.id"
    当GET "/asn/asnmaster?id=${asnmaster.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          id: *
          asn_no: *
          asn_batch: 'ASN-BATCH-E2E-001'
          goods_owner_name: '练习货主-IN'
          detailList: [{
            id: *
            asn_status: 0
            spu_code: 'SPU-E2E-IN-001'
            sku_code: 'SKU-E2E-IN-001'
            asn_qty: 8
            price: 19.9
            supplier_name: '练习供应商-IN'
          }]
        }
      }
      """
    并且记录响应字段 "body.json.data.asn_no" 为 "asn.no"
    并且记录响应字段 "body.json.data.detailList[0].id" 为 "asn.id"
    当POST "/asn/asnmaster/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "asn_batch", "operator": 1, "text": "ASN-BATCH-E2E-001", "value": "ASN-BATCH-E2E-001" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          rows: [{
            asn_batch: 'ASN-BATCH-E2E-001'
            goods_owner_name: '练习货主-IN'
            detailList: [{
              sku_code: 'SKU-E2E-IN-001'
              asn_qty: 8
            }]
          }]
        }
      }
      """
    当PUT "/asn/confirm":
      """
      [
        { "id": ${asn.id}, "arrival_time": "2026-05-18T08:00:00" }
      ]
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当PUT "/asn/unload":
      """
      [
        {
          "id": ${asn.id},
          "unload_time": "2026-05-18T09:00:00",
          "unload_person_id": 0,
          "unload_person": ""
        }
      ]
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当PUT "/asn/sorting":
      """
      [
        {
          "asn_id": ${asn.id},
          "is_auto_num": false,
          "series_number": "SN-E2E-IN-001",
          "sorted_qty": 8,
          "expiry_date": "2026-12-31"
        }
      ]
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当GET "/asn/sorting?asn_id=${asn.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: [{
          series_number: *
          sorted_qty: 8
          putaway_qty: 0
        }]
      }
      """
    并且记录响应字段 "body.json.data[0].series_number" 为 "asnsort.series_number"
    当PUT "/asn/sorted":
      """
      [${asn.id}]
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当GET "/asn/pending-putaway?id=${asn.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: [{
          goods_owner_id: *
          goods_owner_name: '练习货主-IN'
          series_number: *
          sorted_qty: 8
        }]
      }
      """
    当PUT "/asn/putaway":
      """
      [
        {
          "asn_id": ${asn.id},
          "goods_owner_id": ${goods_owner.main.id},
          "series_number": "${asnsort.series_number}",
          "goods_location_id": ${location.normal.id},
          "putaway_qty": 6
        },
        {
          "asn_id": ${asn.id},
          "goods_owner_id": ${goods_owner.main.id},
          "series_number": "${asnsort.series_number}",
          "goods_location_id": ${location.damage.id},
          "putaway_qty": 2
        }
      ]
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当POST "/asn/print-sn":
      """
      [${asn.id}]
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: [{
          asn_id: *
          sku_code: 'SKU-E2E-IN-001'
          sku_name: 'SKU-E2E-IN-001'
          spu_code: 'SPU-E2E-IN-001'
          series_number: *
        }]
      }
      """
    当POST "/asn/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "sqlTitle": "asn_status:4",
        "searchObjects": [
          { "name": "asn_no", "operator": 1, "text": "${asn.no}", "value": "${asn.no}" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          rows: [{
            sku_code: 'SKU-E2E-IN-001'
            asn_status: 4
            asn_qty: 8
            actual_qty: 8
            sorted_qty: 8
            shortage_qty: 0
            more_qty: 0
            damage_qty: 2
          }]
        }
      }
      """
    那么所有"到货通知"应为:
      """
      = [{
        asn_no: *
        sku_code: 'SKU-E2E-IN-001'
        asn_status: 4
        asn_qty: 8
        actual_qty: 8
        sorted_qty: 8
        shortage_qty: 0
        more_qty: 0
        damage_qty: 2
        supplier_name: '练习供应商-IN'
        goods_owner_name: '练习货主-IN'
        price: 19.9
        expiry_date: '2026-12-31'
      }]
      """
    并且所有"分拣记录"应为:
      """
      = [{
        asn_no: *
        sku_code: 'SKU-E2E-IN-001'
        series_number: *
        sorted_qty: 8
        putaway_qty: 8
        expiry_date: '2026-12-31'
      }]
      """
    并且所有"库存层"应为:
      """
      = [{
        sku_code: 'SKU-E2E-IN-001'
        location_code: 'LOC-E2E-IN-D1'
        goods_owner_name: '练习货主-IN'
        series_number: *
        qty: 2
        is_freeze: false
        expiry_date: '2026-12-31'
        price: 19.9
        putaway_date: *
      }, {
        sku_code: 'SKU-E2E-IN-001'
        location_code: 'LOC-E2E-IN-N1'
        goods_owner_name: '练习货主-IN'
        series_number: *
        qty: 6
        is_freeze: false
        expiry_date: '2026-12-31'
        price: 19.9
        putaway_date: *
      }]
      """
    并且所有"库存视图"应为:
      """
      = [{
        sku_code: 'SKU-E2E-IN-001'
        qty: 8
        qty_frozen: 0
        qty_locked: 0
        qty_available: 6
      }]
      """

  场景: 草稿ASN可批量改货主并通过详情查询反映变更
    假如以管理员登录
    并且存在"仓库和SKU":
      | warehouse.name | area.name      | area.property | location.code  | goods_owner.key | goods_owner.name | supplier.key | supplier.name   | customer.name | category.name | spu.key | spu.code        | sku.key | sku.code        |
      | WH-E2E-IN-003  | AREA-E2E-IN-03 | 1             | LOC-E2E-IN-03  | main            | 练习货主-IN-3-A   | main         | 练习供应商-IN-3 | 练习客户-IN-3 | 分类-IN-3      | item    | SPU-E2E-IN-003 | item    | SKU-E2E-IN-003 |
      | WH-E2E-IN-003  | AREA-E2E-IN-03 | 1             | LOC-E2E-IN-03  | secondary       | 练习货主-IN-3-B   | main         | 练习供应商-IN-3 | 练习客户-IN-3 | 分类-IN-3      | item    | SPU-E2E-IN-003 | item    | SKU-E2E-IN-003 |
    当POST "/asn/asnmaster":
      """
      {
        "asn_batch": "ASN-BATCH-E2E-003",
        "estimated_arrival_time": "2026-05-20",
        "goods_owner_id": ${goods_owner.main.id},
        "goods_owner_name": "练习货主-IN-3-A",
        "detailList": [
          {
            "spu_id": ${spu.item.id},
            "spu_code": "SPU-E2E-IN-003",
            "spu_name": "SPU-E2E-IN-003",
            "sku_id": ${sku.item.id},
            "sku_code": "SKU-E2E-IN-003",
            "sku_name": "SKU-E2E-IN-003",
            "asn_qty": 4,
            "supplier_id": ${supplier.main.id},
            "supplier_name": "练习供应商-IN-3",
            "price": 8.8
          }
        ]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data > 0
      """
    并且记录响应字段 "body.json.data" 为 "asnmaster.id"
    当GET "/asn/asnmaster?id=${asnmaster.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          detailList: [{
            id: *
            sku_code: 'SKU-E2E-IN-003'
            asn_qty: 4
          }]
        }
      }
      """
    并且记录响应字段 "body.json.data.asn_no" 为 "asn.no"
    并且记录响应字段 "body.json.data.detailList[0].id" 为 "asn.id"
    当PUT "/asn/bulk-modify-goods-owner":
      """
      {
        "goods_owner_id": ${goods_owner.secondary.id},
        "goods_owner_name": "练习货主-IN-3-B",
        "idList": [${asn.id}]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当GET "/asn?id=${asn.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          asn_status: 0
          sku_code: 'SKU-E2E-IN-003'
          asn_qty: 4
          supplier_name: '练习供应商-IN-3'
          goods_owner_name: '练习货主-IN-3-B'
        }
      }
      """
    那么所有"到货通知"应为:
      """
      : [{
        asn_no: *
        sku_code: 'SKU-E2E-IN-003'
        asn_status: 0
        asn_qty: 4
        goods_owner_name: '练习货主-IN-3-B'
        supplier_name: '练习供应商-IN-3'
        price: 8.8
      }]
      """

  场景: 已卸货ASN不能直接上架且不会形成库存
    假如以管理员登录
    并且存在"已卸货的 到货通知":
      | asn_no                 | sku.code        | goods_owner.name | supplier.name | location.code   | asn_qty |
      | ASN-E2E-IN-ILLEGAL-01 | SKU-E2E-IN-002  | 练习货主-IN-2    | 练习供应商-IN-2 | LOC-E2E-IN-02 | 5       |
    当PUT "/asn/putaway":
      """
      [
        {
          "asn_id": ${asn.id},
          "goods_owner_id": ${goods_owner.id},
          "series_number": "SN-ILLEGAL-001",
          "goods_location_id": ${location.id},
          "putaway_qty": 1
        }
      ]
      """
    那么response should be:
      """
      body.json.isSuccess= false
      """
    那么所有"到货通知"应为:
      """
      : [{
        asn_no: 'ASN-E2E-IN-ILLEGAL-01'
        sku_code: 'SKU-E2E-IN-002'
        asn_status: 2
        asn_qty: 5
        actual_qty: 0
        sorted_qty: 0
        shortage_qty: 0
        more_qty: 0
        damage_qty: 0
      }]
      """
    并且所有"库存层"应为:
      """
      = []
      """
