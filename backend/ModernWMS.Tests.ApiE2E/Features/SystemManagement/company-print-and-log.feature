# language: zh-CN
功能: 系统管理中的公司资料、打印方案与操作日志

  场景: 系统管理员可以维护公司资料、打印方案并查询操作日志
    假如以管理员登录
    当POST "/company":
      """
      {
        "company_name": "E2E-SM-COMPANY-001",
        "city": "厦门",
        "address": "软件园一期",
        "manager": "张三",
        "contact_tel": "13800000001"
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: *
      }
      """
    并且记录响应字段 "body.json.data" 为 "company.id"
    当GET "/company?id=${company.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          company_name: 'E2E-SM-COMPANY-001'
          city: '厦门'
          address: '软件园一期'
          manager: '张三'
          contact_tel: '13800000001'
        }
      }
      """
    当PUT "/company":
      """
      {
        "id": ${company.id},
        "company_name": "E2E-SM-COMPANY-001-UPDATED",
        "city": "泉州",
        "address": "东海湾",
        "manager": "李四",
        "contact_tel": "13800000002"
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: true
      }
      """
    当GET "/company/all"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: [{
          company_name: 'E2E-SM-COMPANY-001-UPDATED'
          city: '泉州'
          manager: '李四'
        }]
      }
      """
    当POST "/actionlog":
      """
      {
        "vue_path": "/base/companySetting",
        "action_content": "更新公司 E2E-SM-COMPANY-001-UPDATED"
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: *
      }
      """
    当POST "/actionlog/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "vue_path", "operator": 1, "text": "/base/companySetting", "value": "/base/companySetting" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          rows: [{
            vue_path: '/base/companySetting'
            action_content: '更新公司 E2E-SM-COMPANY-001-UPDATED'
            user_name: 'Administrator'
          }]
          totals: *
        }
      }
      """
    当POST "/PrintSolution":
      """
      {
        "vue_path": "/base/companySetting",
        "tab_page": "company",
        "solution_name": "E2E-SM-PRINT-001",
        "config_json": "{\"layout\":\"A4\"}",
        "report_length": 210,
        "report_width": 297,
        "report_direction": "P"
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: *
      }
      """
    并且记录响应字段 "body.json.data" 为 "print.id"
    当GET "/PrintSolution?id=${print.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          solution_name: 'E2E-SM-PRINT-001'
          vue_path: '/base/companySetting'
          tab_page: 'company'
          report_length: 210
          report_width: 297
          report_direction: 'P'
        }
      }
      """
    当PUT "/PrintSolution":
      """
      {
        "id": ${print.id},
        "vue_path": "/base/companySetting",
        "tab_page": "company",
        "solution_name": "E2E-SM-PRINT-001-UPDATED",
        "config_json": "{\"layout\":\"LABEL\"}",
        "report_length": 100,
        "report_width": 80,
        "report_direction": "L"
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: true
      }
      """
    当POST "/PrintSolution/get-by-path":
      """
      {
        "vue_path": "/base/companySetting",
        "tab_page": "company"
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: [{
          solution_name: 'E2E-SM-PRINT-001-UPDATED'
          report_length: 100
          report_width: 80
          report_direction: 'L'
        }]
      }
      """
    当POST "/PrintSolution/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "solution_name", "operator": 1, "text": "E2E-SM-PRINT-001-UPDATED", "value": "E2E-SM-PRINT-001-UPDATED" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          rows: [{
            solution_name: 'E2E-SM-PRINT-001-UPDATED'
            vue_path: '/base/companySetting'
          }]
          totals: 1
        }
      }
      """
    当DELETE "/PrintSolution?id=${print.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: *
      }
      """
    当GET "/PrintSolution?id=${print.id}"
    那么response body should match:
      """
      : { isSuccess: false }
      """
    当DELETE "/company?id=${company.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: *
      }
      """
    当GET "/company?id=${company.id}"
    那么response body should match:
      """
      : { isSuccess: false }
      """
