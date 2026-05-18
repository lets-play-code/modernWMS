# language: zh-CN
功能: 系统管理中的用户、角色与菜单权限

  场景: 系统管理员可以给新角色分配菜单并维护用户口令
    假如以管理员登录
    当GET "/user/select-item"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: [{
          code: 'user_role'
          name: 'administrator'
          value: '1'
          comments: "user's role"
        }]
      }
      """
    当POST "/userrole":
      """
      {
        "role_name": "E2E-SM-ROLE-001",
        "is_valid": true
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: *
      }
      """
    并且记录响应字段 "body.json.data" 为 "role.id"
    当GET "/userrole?id=${role.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          role_name: 'E2E-SM-ROLE-001'
          is_valid: true
        }
      }
      """
    当PUT "/userrole":
      """
      {
        "id": ${role.id},
        "role_name": "E2E-SM-ROLE-001-UPDATED",
        "is_valid": true
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: true
      }
      """
    当GET "/userrole?id=${role.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          role_name: 'E2E-SM-ROLE-001-UPDATED'
          is_valid: true
        }
      }
      """
    当GET "/rolemenu/menus"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: [{
          id: 1
          menu_name: 'companySetting'
          vue_path: 'companySetting'
        }]
      }
      """
    当POST "/rolemenu":
      """
      {
        "userrole_id": ${role.id},
        "role_name": "E2E-SM-ROLE-001-UPDATED",
        "is_valid": true,
        "detailList": [
          {
            "id": 0,
            "menu_id": 1,
            "authority": 1,
            "menu_actions_authority": ["save", "delete", "export"]
          },
          {
            "id": 0,
            "menu_id": 23,
            "authority": 1,
            "menu_actions_authority": ["save"]
          }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: *
      }
      """
    当GET "/rolemenu?userrole_id=${role.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          role_name: 'E2E-SM-ROLE-001-UPDATED'
          detailList: [{
            menu_id: 1
            menu_name: 'companySetting'
            authority: 1
            menu_actions_authority: ['save', 'delete', 'export']
          }, {
            menu_id: 23
            menu_name: 'print'
            authority: 1
            menu_actions_authority: ['save']
          }]
        }
      }
      """
    当GET "/rolemenu/all"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size > 1
      """
    当GET "/rolemenu/authority?userrole_id=${role.id}"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size= 2
      """
    当POST "/user":
      """
      {
        "user_num": "E2E-SM-USER-001",
        "user_name": "系统测试用户",
        "contact_tel": "13900000001",
        "user_role": "E2E-SM-ROLE-001-UPDATED",
        "sex": "male",
        "is_valid": true
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: *
      }
      """
    并且记录响应字段 "body.json.data" 为 "user.id"
    当GET "/user?id=${user.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          user_num: 'E2E-SM-USER-001'
          user_name: '系统测试用户'
          user_role: 'E2E-SM-ROLE-001-UPDATED'
          is_valid: true
        }
      }
      """
    当POST "/user/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "user_num", "operator": 1, "text": "E2E-SM-USER-001", "value": "E2E-SM-USER-001" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          rows: [{
            user_num: 'E2E-SM-USER-001'
            user_role: 'E2E-SM-ROLE-001-UPDATED'
          }]
          totals: 1
        }
      }
      """
    当POST "/user/reset-pwd":
      """
      {
        "id_list": [${user.id}]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: *
      }
      """
    并且记录响应字段 "body.json.data" 为 "user.reset_pwd"
    当POST "/user/change-pwd":
      """
      {
        "id": ${user.id},
        "old_password": "${md5:user.reset_pwd}",
        "new_password": "2237f725e36f07e2cfe8e0eb1a207016"
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: *
      }
      """
    当POST "/login":
      """
      {
        "user_name": "E2E-SM-USER-001",
        "password": "Pwd789"
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          user_name: '系统测试用户'
          user_role: 'E2E-SM-ROLE-001-UPDATED'
        }
      }
      """
    当POST "/login":
      """
      {
        "user_name": "admin",
        "password": "1"
      }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      """
    当POST "/user/excel":
      """
      [
        {
          "user_num": "E2E-SM-USER-EXCEL-001",
          "user_name": "Excel导入用户",
          "contact_tel": "13900000002",
          "user_role": "E2E-SM-ROLE-001-UPDATED",
          "sex": "female",
          "is_valid": true
        }
      ]
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: *
      }
      """
    当POST "/user/list":
      """
      {
        "pageIndex": 1,
        "pageSize": 20,
        "searchObjects": [
          { "name": "user_num", "operator": 1, "text": "E2E-SM-USER-EXCEL-001", "value": "E2E-SM-USER-EXCEL-001" }
        ]
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          rows: [{
            user_num: 'E2E-SM-USER-EXCEL-001'
            user_role: 'E2E-SM-ROLE-001-UPDATED'
          }]
          totals: 1
        }
      }
      """
    当DELETE "/user?id=${user.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: *
      }
      """
    当GET "/user?id=${user.id}"
    那么response body should match:
      """
      : { isSuccess: false }
      """
    当DELETE "/rolemenu?userrole_id=${role.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: *
      }
      """
    当GET "/rolemenu?userrole_id=${role.id}"
    那么response body should match:
      """
      : { isSuccess: false }
      """
    当DELETE "/userrole?id=${role.id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: *
      }
      """
    当GET "/userrole?id=${role.id}"
    那么response body should match:
      """
      : { isSuccess: false }
      """
