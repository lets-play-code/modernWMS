# language: zh-CN
功能: 运费模板维护

  场景: 运费模板可经由新增查询更新导入和删除维护
    假如以管理员登录
    当POST "/freightfee":
      """
      {
        "carrier": "承运-E2E-FF-01",
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
    当GET "/freightfee?id=${freight.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          id: *
          carrier: '承运-E2E-FF-01'
          departure_city: '上海'
          arrival_city: '杭州'
          price_per_weight: 2.5
          price_per_volume: 1.2
          min_payment: 10
          is_valid: true
        }
      }
      """
    当POST "/freightfee/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "carrier", "operator": 1, "text": "承运-E2E-FF-01", "value": "承运-E2E-FF-01" }
        ]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.totals = 1
      body.json.data.rows[0].carrier = '承运-E2E-FF-01'
      body.json.data.rows[0].arrival_city = '杭州'
      """
    当GET "/freightfee/all"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size > 0
      """
    当PUT "/freightfee":
      """
      {
        "id": ${freight.id},
        "carrier": "承运-E2E-FF-01",
        "departure_city": "上海",
        "arrival_city": "苏州",
        "price_per_weight": 2.8,
        "price_per_volume": 1.5,
        "min_payment": 12,
        "is_valid": false
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data = true
      """
    当GET "/freightfee?id=${freight.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          id: *
          carrier: '承运-E2E-FF-01'
          arrival_city: '苏州'
          price_per_weight: 2.8
          price_per_volume: 1.5
          min_payment: 12
          is_valid: false
        }
      }
      """
    当POST "/freightfee/excel":
      """
      [
        {
          "carrier": "承运-E2E-FF-02",
          "departure_city": "北京",
          "arrival_city": "天津",
          "price_per_weight": 3.0,
          "price_per_volume": 1.8,
          "min_payment": 15
        }
      ]
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当POST "/freightfee/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "carrier", "operator": 1, "text": "承运-E2E-FF-02", "value": "承运-E2E-FF-02" }
        ]
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.totals = 1
      body.json.data.rows[0].arrival_city = '天津'
      body.json.data.rows[0].min_payment = 15
      """
    当DELETE "/freightfee?id=${freight.id}"
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当GET "/freightfee?id=${freight.id}"
    那么response body should match:
      """
      : { isSuccess: false }
      """
