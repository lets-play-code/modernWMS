# language: zh-CN
功能: ASN入库执行

  场景: 已分拣ASN可以通过列表API观察并保留分拣事实
    假如以管理员登录
    并且存在"已分拣的 到货通知":
      | asn_no          | sku.code        | goods_owner.name | supplier.name | location.code   | asn_qty | sorted_qty |
      | ASN-E2E-IN-001  | SKU-E2E-IN-001  | 练习货主-IN      | 练习供应商-IN | LOC-E2E-IN-01   | 8       | 8          |
    当POST "/asn/list":
      """
      { "pageIndex": 1, "pageSize": 20, "sqlTitle": "asn_status:3", "searchObjects": [] }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    那么所有"到货通知"应为:
      """
      = [{
        asn_no: 'ASN-E2E-IN-001'
        sku_code: 'SKU-E2E-IN-001'
        asn_status: 3
        asn_qty: 8
        sorted_qty: 8
      }]
      """
    并且所有"分拣记录"应为:
      """
      = [{
        asn_no: 'ASN-E2E-IN-001'
        sku_code: 'SKU-E2E-IN-001'
        sorted_qty: 8
        putaway_qty: 0
      }]
      """
