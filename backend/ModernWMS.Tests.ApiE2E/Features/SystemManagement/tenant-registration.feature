# language: zh-CN
功能: 系统管理中的租户注册

  场景: 新租户注册后可以登录并读取默认菜单权限
    当POST "/user/register":
      """
      {
        "user_name": "e2e_sm_reg_001",
        "sex": "female",
        "auth_string": "4357372d1353b6f3f2996205545167d5",
        "email": "e2e_sm_reg_001@example.com"
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
        "user_name": "e2e_sm_reg_001",
        "password": "RegPwd1"
      }
      """
    那么response body should match:
      """
      : {
        isSuccess: true
        data: {
          user_name: 'e2e_sm_reg_001'
          user_role: 'admin'
          access_token: *
        }
      }
      """
    并且记录响应字段 "body.json.data.userrole_id" 为 "register.userrole_id"
    当GET "/rolemenu/authority?userrole_id=${register.userrole_id}"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: [{
          menu_name: 'companySetting'
          vue_path: 'companySetting'
        }]
      }
      """
    当GET "/user/select-item"
    那么response body should match:
      """
      : {
        isSuccess: true
        data: [{
          code: 'user_role'
          name: 'admin'
        }]
      }
      """
