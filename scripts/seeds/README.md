# Bundled seed files

该目录保存课程仓库随附的基础 seed 文件，供本地启动与数据库重置脚本直接使用。

当前文件：

- `database_mysql.sql`：ModernWMS 官方 MySQL 初始化脚本的仓库内置副本

保存在代码库中的原因：

- 避免课程或训练环境在 `reset-db` 时依赖外部网络下载
- 让本地重置结果更稳定、可重复
- 降低因上游链接不可用或网络波动导致的初始化失败风险

上游来源：

- `https://modernwms.ikeyly.com/assets/staticFile/database_mysql.sql`
