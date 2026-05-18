# language: zh-CN
功能: 登录与权限

  场景: 管理员登录后可以读取菜单权限
    当POST "/login":
      """
      { "user_name": "admin", "password": "1" }
      """
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.access_token= *
      body.json.data.refresh_token= *
      body.json.data.userrole_id= 1
      """
    当GET "/rolemenu/authority?userrole_id=1"
    那么response should be:
      """
      body.json.isSuccess= true
      body.json.data.size > 0
      """

  场景: 未登录业务 API 被拒绝
    当POST "/warehouse/list":
      """
      { "pageIndex": 1, "pageSize": 20, "searchObjects": [] }
      """
    那么response should be:
      """
      status= 401
      """
