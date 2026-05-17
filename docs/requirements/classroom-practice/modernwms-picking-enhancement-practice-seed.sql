-- ModernWMS 综合课程练习补种 SQL
-- 使用前提：已导入仓库内置的官方 MySQL seed（scripts/seeds/database_mysql.sql），并已存在 wms 数据库
-- 数据集目标：
--   1) 提供一条从 ASN 到签收的可操作主线
--   2) 提供可直接验证 ASN 查询 bug 的到货通知数据
--   3) 提供可直接验证拣货增强的待拣货数据
--   4) 提供仓内作业模块（冻结 / 移库 / 调整 / 盘点 / 加工）的演示快照

USE `wms`;

SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

-- ------------------------------------------------------------
-- 0. 清理本练习补种产生的数据（便于重复导入）
-- ------------------------------------------------------------
DELETE FROM `stockprocessdetail` WHERE `id` BETWEEN 54501 AND 54599;
DELETE FROM `stockprocess` WHERE `id` BETWEEN 54401 AND 54499;
DELETE FROM `stocktaking` WHERE `id` BETWEEN 54301 AND 54399;
DELETE FROM `stockadjust` WHERE `id` BETWEEN 54201 AND 54299;
DELETE FROM `stockfreeze` WHERE `id` BETWEEN 54101 AND 54199;
DELETE FROM `stockmove` WHERE `id` BETWEEN 54001 AND 54099;
DELETE FROM `asnsort` WHERE `id` BETWEEN 53201 AND 53299;
DELETE FROM `asn` WHERE `id` BETWEEN 53101 AND 53199 OR `asn_no` IN ('ASN-E2E-001', 'ASN-BUG-001', 'ASN-BUG-002', 'ASN-DEMO-UNLOAD-001', 'ASN-DEMO-SORT-001', 'ASN-DEMO-GROUND-001', 'ASN-DEMO-RECEIPT-001');
DELETE FROM `asnmaster` WHERE `id` BETWEEN 53001 AND 53099 OR `asn_no` IN ('ASN-E2E-001', 'ASN-BUG-001', 'ASN-BUG-002', 'ASN-DEMO-UNLOAD-001', 'ASN-DEMO-SORT-001', 'ASN-DEMO-GROUND-001', 'ASN-DEMO-RECEIPT-001');
DELETE FROM `dispatchpicklist` WHERE `id` BETWEEN 52001 AND 52099;
DELETE FROM `dispatchlist` WHERE `id` BETWEEN 51901 AND 51999 OR `dispatch_no` IN ('DP-TRAIN-001', 'DP-TRAIN-002', 'DP-TRAIN-003', 'DP-E2E-001', 'DP-DEMO-NEW-001', 'DP-DEMO-PICKED-001', 'DP-DEMO-PACKAGED-001', 'DP-DEMO-WEIGHED-001', 'DP-DEMO-DELIVERED-001', 'DP-DEMO-SIGNED-001');
DELETE FROM `stock` WHERE `id` BETWEEN 51801 AND 51899;
DELETE FROM `sku` WHERE `id` BETWEEN 51701 AND 51799 OR `sku_code` IN ('SKU-PICK-A-STD', 'SKU-PICK-B-SMALL', 'SKU-E2E-A-STD', 'SKU-ASN-BUG-A', 'SKU-ASN-BUG-B', 'SKU-WORK-DEMO');
DELETE FROM `spu` WHERE `id` BETWEEN 51601 AND 51699 OR `spu_code` IN ('SPU-PICK-A', 'SPU-PICK-B', 'SPU-E2E-A', 'SPU-ASN-BUG-A', 'SPU-ASN-BUG-B', 'SPU-WORK-DEMO');
DELETE FROM `category` WHERE `id` = 51501 OR `category_name` = '练习-WMS综合演示';
DELETE FROM `customer` WHERE `id` BETWEEN 51401 AND 51499 OR `customer_name` IN ('华东零售客户', '华南渠道客户', '华北电商客户', '全链路演练客户');
DELETE FROM `goodsowner` WHERE `id` = 51301 OR `goods_owner_name` = '练习货主A';
DELETE FROM `goodslocation` WHERE `id` BETWEEN 51201 AND 51299 OR `location_name` IN ('PICK-A-01', 'PICK-A-02', 'STOCK-A-01', 'STOCK-A-02');
DELETE FROM `warehousearea` WHERE `id` BETWEEN 51101 AND 51199 OR `area_name` IN ('练习一号仓拣货区', '练习一号仓存储区');
DELETE FROM `warehouse` WHERE `id` = 51001 OR `warehouse_name` = '练习一号仓';
DELETE FROM `supplier` WHERE `id` BETWEEN 50901 AND 50999 OR `supplier_name` IN ('华东供应商A', '华南供应商B', '主线供应商E2E');
DELETE FROM `rolemenu` WHERE `id` IN (56001, 56002);
DELETE FROM `user` WHERE `id` IN (57001, 57002) OR `user_num` IN ('picker01', 'checker01');
DELETE FROM `userrole` WHERE `id` IN (58001, 58002) OR `role_name` IN ('picker', 'checker');

-- ------------------------------------------------------------
-- 1. 调整管理员 deliveryManagement 权限，补上历史增强入口 picked-pick
-- ------------------------------------------------------------
UPDATE `rolemenu`
SET `menu_actions_authority` = '["invoice-save", "invoice-confirm", "invoice-revoke", "invoice-delete", "invoice-export", "invoice-printQrCode", "picked-confirm", "picked-revoke", "picked-export", "picked-pick", "packaged-package", "packaged-export", "packaged-revoke", "weighed-weigh", "weighed-revoke", "weighed-export", "delivered-delivery", "delivered-setCarrier", "delivered-signIn", "delivered-export", "signedIn-export"]'
WHERE `userrole_id` = 1 AND `menu_id` = 19;

-- ------------------------------------------------------------
-- 2. 角色与账号
-- ------------------------------------------------------------
INSERT INTO `userrole` (`id`, `role_name`, `is_valid`, `create_time`, `last_update_time`, `tenant_id`)
VALUES
  (58001, 'picker', 1, '2026-05-15 10:00:00', '2026-05-15 10:00:00', 1),
  (58002, 'checker', 1, '2026-05-15 10:00:00', '2026-05-15 10:00:00', 1);

INSERT INTO `user` (`id`, `user_num`, `user_name`, `contact_tel`, `user_role`, `sex`, `is_valid`, `auth_string`, `email`, `creator`, `create_time`, `last_update_time`, `tenant_id`)
VALUES
  (57001, 'picker01', '拣货员-李明', '13800000001', 'picker', 'male', 1, 'c4ca4238a0b923820dcc509a6f75849b', 'picker01@example.com', 'admin', '2026-05-15 10:00:00', '2026-05-15 10:00:00', 1),
  (57002, 'checker01', '复核员-王敏', '13800000002', 'checker', 'female', 1, 'c4ca4238a0b923820dcc509a6f75849b', 'checker01@example.com', 'admin', '2026-05-15 10:00:00', '2026-05-15 10:00:00', 1);

INSERT INTO `rolemenu` (`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`)
VALUES
  (56001, 58001, 19, 1, '2026-05-15 10:00:00', '2026-05-15 10:00:00', 1, '["picked-pick", "picked-confirm", "picked-export"]'),
  (56002, 58002, 19, 1, '2026-05-15 10:00:00', '2026-05-15 10:00:00', 1, '["picked-confirm", "picked-export"]');

-- ------------------------------------------------------------
-- 3. 基础资料：仓库 / 库区 / 库位 / 货主 / 供应商 / 客户 / 分类 / 商品
-- ------------------------------------------------------------
INSERT INTO `warehouse` (`id`, `warehouse_name`, `city`, `address`, `email`, `manager`, `contact_tel`, `creator`, `create_time`, `last_update_time`, `is_valid`, `tenant_id`)
VALUES
  (51001, '练习一号仓', '上海', '上海市浦东新区练习路 100 号', 'warehouse.practice@example.com', '仓库主管-陈工', '021-50000001', 'admin', '2026-05-15 10:05:00', '2026-05-15 10:05:00', 1, 1);

INSERT INTO `warehousearea` (`id`, `warehouse_id`, `area_name`, `area_property`, `parent_id`, `create_time`, `last_update_time`, `is_valid`, `tenant_id`)
VALUES
  (51101, 51001, '练习一号仓拣货区', 1, 0, '2026-05-15 10:06:00', '2026-05-15 10:06:00', 1, 1),
  (51102, 51001, '练习一号仓存储区', 2, 0, '2026-05-15 10:06:00', '2026-05-15 10:06:00', 1, 1);

INSERT INTO `goodslocation` (`id`, `warehouse_id`, `warehouse_name`, `warehouse_area_id`, `warehouse_area_name`, `warehouse_area_property`, `location_name`, `location_length`, `location_width`, `location_heigth`, `location_volume`, `location_load`, `roadway_number`, `shelf_number`, `layer_number`, `tag_number`, `create_time`, `last_update_time`, `is_valid`, `tenant_id`)
VALUES
  (51201, 51001, '练习一号仓', 51101, '练习一号仓拣货区', 1, 'PICK-A-01', 1.20, 1.00, 1.80, 2.16, 500.00, 'A', '01', '01', '01', '2026-05-15 10:08:00', '2026-05-15 10:08:00', 1, 1),
  (51202, 51001, '练习一号仓', 51101, '练习一号仓拣货区', 1, 'PICK-A-02', 1.20, 1.00, 1.80, 2.16, 500.00, 'A', '01', '01', '02', '2026-05-15 10:08:00', '2026-05-15 10:08:00', 1, 1),
  (51203, 51001, '练习一号仓', 51102, '练习一号仓存储区', 2, 'STOCK-A-01', 1.50, 1.20, 2.00, 3.60, 800.00, 'B', '01', '01', '01', '2026-05-15 10:08:00', '2026-05-15 10:08:00', 1, 1),
  (51204, 51001, '练习一号仓', 51102, '练习一号仓存储区', 2, 'STOCK-A-02', 1.50, 1.20, 2.00, 3.60, 800.00, 'B', '01', '01', '02', '2026-05-15 10:08:00', '2026-05-15 10:08:00', 1, 1);

INSERT INTO `goodsowner` (`id`, `goods_owner_name`, `city`, `address`, `manager`, `contact_tel`, `creator`, `create_time`, `last_update_time`, `is_valid`, `tenant_id`)
VALUES
  (51301, '练习货主A', '上海', '上海市徐汇区货主路 8 号', '货主联系人-张伟', '021-60000001', 'admin', '2026-05-15 10:10:00', '2026-05-15 10:10:00', 1, 1);

INSERT INTO `customer` (`id`, `customer_name`, `city`, `address`, `email`, `manager`, `contact_tel`, `creator`, `create_time`, `last_update_time`, `is_valid`, `tenant_id`)
VALUES
  (51401, '华东零售客户', '杭州', '杭州市滨江区演练大道 1 号', 'east-retail@example.com', '客户经理-许静', '0571-70000001', 'admin', '2026-05-15 10:12:00', '2026-05-15 10:12:00', 1, 1),
  (51402, '华南渠道客户', '广州', '广州市天河区演练大道 2 号', 'south-channel@example.com', '客户经理-宋凯', '020-70000002', 'admin', '2026-05-15 10:12:00', '2026-05-15 10:12:00', 1, 1),
  (51403, '华北电商客户', '北京', '北京市朝阳区演练大道 3 号', 'north-ecom@example.com', '客户经理-赵岩', '010-70000003', 'admin', '2026-05-15 10:12:00', '2026-05-15 10:12:00', 1, 1),
  (51404, '全链路演练客户', '南京', '南京市建邺区主线路 9 号', 'e2e@example.com', '客户经理-周岚', '025-70000004', 'admin', '2026-05-15 10:12:00', '2026-05-15 10:12:00', 1, 1);

INSERT INTO `supplier` (`id`, `supplier_name`, `city`, `address`, `email`, `manager`, `contact_tel`, `creator`, `create_time`, `last_update_time`, `is_valid`, `tenant_id`)
VALUES
  (50901, '华东供应商A', '苏州', '苏州市工业园区供应大道 1 号', 'supplier-a@example.com', '供应商联系人-陈峰', '0512-80000001', 'admin', '2026-05-15 10:13:00', '2026-05-15 10:13:00', 1, 1),
  (50902, '华南供应商B', '深圳', '深圳市南山区供应大道 2 号', 'supplier-b@example.com', '供应商联系人-刘洋', '0755-80000002', 'admin', '2026-05-15 10:13:00', '2026-05-15 10:13:00', 1, 1),
  (50903, '主线供应商E2E', '无锡', '无锡市新吴区主线路 3 号', 'supplier-e2e@example.com', '供应商联系人-顾琳', '0510-80000003', 'admin', '2026-05-15 10:13:00', '2026-05-15 10:13:00', 1, 1);

INSERT INTO `category` (`id`, `category_name`, `parent_id`, `creator`, `create_time`, `last_update_time`, `is_valid`, `tenant_id`)
VALUES
  (51501, '练习-WMS综合演示', 0, 'admin', '2026-05-15 10:14:00', '2026-05-15 10:14:00', 1, 1);

INSERT INTO `spu` (`id`, `spu_code`, `spu_name`, `category_id`, `spu_description`, `supplier_id`, `supplier_name`, `brand`, `origin`, `length_unit`, `volume_unit`, `weight_unit`, `creator`, `create_time`, `last_update_time`, `is_valid`, `tenant_id`)
VALUES
  (51601, 'SPU-PICK-A', '拣货演练箱', 51501, '用于演练多单共享与多库位拆拣的核心商品。', 50903, '主线供应商E2E', 'PracticeBrand', 'CN', 1, 1, 2, 'admin', '2026-05-15 10:16:00', '2026-05-15 10:16:00', 1, 1),
  (51602, 'SPU-PICK-B', '拣货演练标签纸', 51501, '用于提供简单单行对照场景的商品。', 50903, '主线供应商E2E', 'PracticeBrand', 'CN', 1, 1, 2, 'admin', '2026-05-15 10:16:00', '2026-05-15 10:16:00', 1, 1),
  (51603, 'SPU-E2E-A', '全链路演练箱', 51501, '用于学员从 ASN 一路推进到签收的主线商品。', 50903, '主线供应商E2E', 'CourseBrand', 'CN', 1, 1, 2, 'admin', '2026-05-15 10:17:00', '2026-05-15 10:17:00', 1, 1),
  (51604, 'SPU-ASN-BUG-A', 'ASN查询演练箱', 51501, '用于验证到货通知按供应商 / SKU 搜索的对照商品 A。', 50901, '华东供应商A', 'CourseBrand', 'CN', 1, 1, 2, 'admin', '2026-05-15 10:17:00', '2026-05-15 10:17:00', 1, 1),
  (51605, 'SPU-ASN-BUG-B', 'ASN查询演练袋', 51501, '用于验证到货通知按供应商 / SKU 搜索的对照商品 B。', 50902, '华南供应商B', 'CourseBrand', 'CN', 1, 1, 2, 'admin', '2026-05-15 10:17:00', '2026-05-15 10:17:00', 1, 1),
  (51606, 'SPU-WORK-DEMO', '仓内作业演示箱', 51501, '用于冻结、移库、调整、盘点、加工等仓内作业演示。', 50903, '主线供应商E2E', 'CourseBrand', 'CN', 1, 1, 2, 'admin', '2026-05-15 10:17:00', '2026-05-15 10:17:00', 1, 1);

INSERT INTO `sku` (`id`, `spu_id`, `sku_code`, `sku_name`, `weight`, `lenght`, `width`, `height`, `volume`, `unit`, `cost`, `price`, `create_time`, `last_update_time`, `bar_code`, `image_url`)
VALUES
  (51701, 51601, 'SKU-PICK-A-STD', '拣货演练箱-标准款', 2.500, 10.000, 10.000, 12.000, 1.200, 'pcs', 65.00, 89.00, '2026-05-15 10:18:00', '2026-05-15 10:18:00', '6900000000001', ''),
  (51702, 51602, 'SKU-PICK-B-SMALL', '拣货演练标签纸-小包', 0.300, 5.000, 4.000, 1.000, 0.020, 'pcs', 7.50, 12.50, '2026-05-15 10:18:00', '2026-05-15 10:18:00', '6900000000002', ''),
  (51703, 51603, 'SKU-E2E-A-STD', '全链路演练箱-标准款', 1.800, 20.000, 15.000, 10.000, 0.800, 'pcs', 42.00, 68.00, '2026-05-15 10:18:00', '2026-05-15 10:18:00', '6900000000003', ''),
  (51704, 51604, 'SKU-ASN-BUG-A', 'ASN查询演练箱-基础款', 1.200, 18.000, 12.000, 8.000, 0.500, 'pcs', 35.00, 58.00, '2026-05-15 10:18:00', '2026-05-15 10:18:00', '6900000000004', ''),
  (51705, 51605, 'SKU-ASN-BUG-B', 'ASN查询演练袋-基础款', 0.800, 16.000, 10.000, 6.000, 0.350, 'pcs', 22.00, 36.00, '2026-05-15 10:18:00', '2026-05-15 10:18:00', '6900000000005', ''),
  (51706, 51606, 'SKU-WORK-DEMO', '仓内作业演示箱-教学款', 0.900, 15.000, 12.000, 6.000, 0.400, 'pcs', 18.00, 25.00, '2026-05-15 10:18:00', '2026-05-15 10:18:00', '6900000000006', '');

-- ------------------------------------------------------------
-- 4. 库存：保留拣货训练库存，并补充收货完成 / 仓内作业 / 发货状态快照库存
-- ------------------------------------------------------------
INSERT INTO `stock` (`id`, `sku_id`, `goods_location_id`, `qty`, `goods_owner_id`, `is_freeze`, `last_update_time`, `tenant_id`, `series_number`, `expiry_date`, `price`, `putaway_date`)
VALUES
  (51801, 51701, 51201, 7, 51301, 0, '2026-05-15 10:20:00', 1, 'LOT-A-202605', '2026-12-31', 89.00, '2026-05-01'),
  (51802, 51701, 51202, 4, 51301, 0, '2026-05-15 10:20:00', 1, 'LOT-A-202605', '2026-12-31', 89.00, '2026-05-01'),
  (51803, 51701, 51203, 12, 51301, 0, '2026-05-15 10:20:00', 1, 'LOT-A-202605', '2026-12-31', 89.00, '2026-05-01'),
  (51804, 51702, 51202, 6, 51301, 0, '2026-05-15 10:20:00', 1, 'LOT-B-202605', '2027-01-31', 12.50, '2026-05-02'),
  (51805, 51702, 51204, 10, 51301, 0, '2026-05-15 10:20:00', 1, 'LOT-B-202605', '2027-01-31', 12.50, '2026-05-02'),
  (51806, 51704, 51203, 4, 51301, 0, '2026-05-15 10:21:00', 1, 'SN-RECEIPT-001', '2027-03-31', 58.00, '2026-05-10'),
  (51807, 51706, 51204, 8, 51301, 1, '2026-05-15 10:21:00', 1, 'WORK-FREEZE-001', '2027-05-31', 25.00, '2026-05-11'),
  (51808, 51706, 51204, 5, 51301, 0, '2026-05-15 10:21:00', 1, 'WORK-MOVE-PENDING', '2027-05-31', 25.00, '2026-05-11'),
  (51809, 51706, 51202, 3, 51301, 0, '2026-05-15 10:21:00', 1, 'WORK-MOVE-DONE', '2027-05-31', 25.00, '2026-05-11'),
  (51810, 51706, 51203, 6, 51301, 0, '2026-05-15 10:21:00', 1, 'WORK-ADJUST-PENDING', '2027-05-31', 25.00, '2026-05-11'),
  (51811, 51706, 51204, 8, 51301, 0, '2026-05-15 10:21:00', 1, 'WORK-TAKE-DONE', '2027-05-31', 25.00, '2026-05-11'),
  (51812, 51706, 51203, 10, 51301, 0, '2026-05-15 10:21:00', 1, 'WORK-TAKE-OPEN', '2027-05-31', 25.00, '2026-05-11'),
  (51813, 51706, 51203, 2, 51301, 0, '2026-05-15 10:21:00', 1, 'WORK-PROC-SRC-OPEN', '2027-05-31', 25.00, '2026-05-11'),
  (51814, 51706, 51202, 3, 51301, 0, '2026-05-15 10:21:00', 1, 'WORK-PROC-TGT-DONE', '2027-05-31', 25.00, '2026-05-11'),
  (51815, 51706, 51203, 3, 51301, 0, '2026-05-15 10:21:00', 1, 'WORK-PROC-SRC-DONE', '2027-05-31', 25.00, '2026-05-11'),
  (51816, 51706, 51203, 4, 51301, 0, '2026-05-15 10:21:00', 1, 'WORK-UNFREEZE-001', '2027-05-31', 25.00, '2026-05-11'),
  (51817, 51702, 51202, 2, 51301, 0, '2026-05-15 10:21:00', 1, 'OUT-PICKED-001', '2027-01-31', 12.50, '2026-05-11'),
  (51818, 51702, 51201, 2, 51301, 0, '2026-05-15 10:21:00', 1, 'OUT-PACKAGED-001', '2027-01-31', 12.50, '2026-05-11'),
  (51819, 51701, 51202, 2, 51301, 0, '2026-05-15 10:21:00', 1, 'OUT-WEIGHED-001', '2026-12-31', 89.00, '2026-05-11'),
  (51820, 51701, 51203, 1, 51301, 0, '2026-05-15 10:21:00', 1, 'OUT-DELIVERED-001', '2026-12-31', 89.00, '2026-05-11'),
  (51821, 51702, 51204, 1, 51301, 0, '2026-05-15 10:21:00', 1, 'OUT-SIGNED-001', '2027-01-31', 12.50, '2026-05-11'),
  (51822, 51706, 51203, 5, 51301, 0, '2026-05-15 10:21:00', 1, 'WORK-ADJUST-DONE', '2027-05-31', 25.00, '2026-05-11');

-- ------------------------------------------------------------
-- 5. ASN 主线 / Bug / 快照场景
-- ------------------------------------------------------------
INSERT INTO `asnmaster` (`id`, `asn_no`, `asn_batch`, `estimated_arrival_time`, `asn_status`, `weight`, `volume`, `goods_owner_id`, `goods_owner_name`, `creator`, `create_time`, `last_update_time`, `tenant_id`)
VALUES
  (53001, 'ASN-E2E-001', 'E2E-BATCH-001', '2026-05-20 09:00:00', 0, 14.400, 6.400, 51301, '练习货主A', 'practice-seed', '2026-05-15 10:30:00', '2026-05-15 10:30:00', 1),
  (53002, 'ASN-BUG-001', 'BUG-BATCH-A', '2026-05-21 10:00:00', 0, 6.000, 2.500, 51301, '练习货主A', 'practice-seed', '2026-05-15 10:31:00', '2026-05-15 10:31:00', 1),
  (53003, 'ASN-BUG-002', 'BUG-BATCH-B', '2026-05-21 11:00:00', 0, 5.600, 2.450, 51301, '练习货主A', 'practice-seed', '2026-05-15 10:32:00', '2026-05-15 10:32:00', 1),
  (53004, 'ASN-DEMO-UNLOAD-001', 'DEMO-ARRIVAL-001', '2026-05-18 08:30:00', 1, 4.800, 2.000, 51301, '练习货主A', 'practice-seed', '2026-05-15 10:33:00', '2026-05-15 10:33:00', 1),
  (53005, 'ASN-DEMO-SORT-001', 'DEMO-SORT-001', '2026-05-17 08:30:00', 2, 4.800, 2.100, 51301, '练习货主A', 'practice-seed', '2026-05-15 10:34:00', '2026-05-15 10:34:00', 1),
  (53006, 'ASN-DEMO-GROUND-001', 'DEMO-GROUND-001', '2026-05-16 08:30:00', 3, 4.000, 1.750, 51301, '练习货主A', 'practice-seed', '2026-05-15 10:35:00', '2026-05-15 10:35:00', 1),
  (53007, 'ASN-DEMO-RECEIPT-001', 'DEMO-RECEIPT-001', '2026-05-14 08:30:00', 4, 4.800, 2.000, 51301, '练习货主A', 'practice-seed', '2026-05-15 10:36:00', '2026-05-15 10:36:00', 1);

INSERT INTO `asn` (`id`, `asnmaster_id`, `asn_no`, `asn_status`, `spu_id`, `sku_id`, `asn_qty`, `actual_qty`, `sorted_qty`, `shortage_qty`, `more_qty`, `damage_qty`, `weight`, `volume`, `supplier_id`, `supplier_name`, `goods_owner_id`, `goods_owner_name`, `creator`, `create_time`, `last_update_time`, `is_valid`, `tenant_id`, `arrival_time`, `unload_time`, `unload_person_id`, `unload_person`, `expiry_date`, `price`)
VALUES
  (53101, 53001, 'ASN-E2E-001', 0, 51603, 51703, 8, 0, 0, 0, 0, 0, 14.400, 6.400, 50903, '主线供应商E2E', 51301, '练习货主A', 'practice-seed', '2026-05-15 10:30:00', '2026-05-15 10:30:00', 1, 1, '1900-01-01 00:00:00', '1900-01-01 00:00:00', 0, '', '2027-06-30', 68.00),
  (53102, 53002, 'ASN-BUG-001', 0, 51604, 51704, 5, 0, 0, 0, 0, 0, 6.000, 2.500, 50901, '华东供应商A', 51301, '练习货主A', 'practice-seed', '2026-05-15 10:31:00', '2026-05-15 10:31:00', 1, 1, '1900-01-01 00:00:00', '1900-01-01 00:00:00', 0, '', '2027-03-31', 58.00),
  (53103, 53003, 'ASN-BUG-002', 0, 51605, 51705, 7, 0, 0, 0, 0, 0, 5.600, 2.450, 50902, '华南供应商B', 51301, '练习货主A', 'practice-seed', '2026-05-15 10:32:00', '2026-05-15 10:32:00', 1, 1, '1900-01-01 00:00:00', '1900-01-01 00:00:00', 0, '', '2027-04-30', 36.00),
  (53104, 53004, 'ASN-DEMO-UNLOAD-001', 1, 51604, 51704, 4, 0, 0, 0, 0, 0, 4.800, 2.000, 50901, '华东供应商A', 51301, '练习货主A', 'practice-seed', '2026-05-15 10:33:00', '2026-05-15 10:33:00', 1, 1, '2026-05-18 09:10:00', '1900-01-01 00:00:00', 0, '', '2027-03-31', 58.00),
  (53105, 53005, 'ASN-DEMO-SORT-001', 2, 51605, 51705, 6, 0, 0, 0, 0, 0, 4.800, 2.100, 50902, '华南供应商B', 51301, '练习货主A', 'practice-seed', '2026-05-15 10:34:00', '2026-05-15 10:34:00', 1, 1, '2026-05-17 09:00:00', '2026-05-17 10:00:00', 1, 'admin', '2027-04-30', 36.00),
  (53106, 53006, 'ASN-DEMO-GROUND-001', 3, 51605, 51705, 5, 0, 5, 0, 0, 0, 4.000, 1.750, 50902, '华南供应商B', 51301, '练习货主A', 'practice-seed', '2026-05-15 10:35:00', '2026-05-15 10:35:00', 1, 1, '2026-05-16 09:00:00', '2026-05-16 09:45:00', 1, 'admin', '2027-04-30', 36.00),
  (53107, 53007, 'ASN-DEMO-RECEIPT-001', 4, 51604, 51704, 4, 4, 4, 0, 0, 0, 4.800, 2.000, 50901, '华东供应商A', 51301, '练习货主A', 'practice-seed', '2026-05-15 10:36:00', '2026-05-15 10:36:00', 1, 1, '2026-05-14 09:00:00', '2026-05-14 09:45:00', 1, 'admin', '2027-03-31', 58.00);

INSERT INTO `asnsort` (`id`, `asn_id`, `sorted_qty`, `creator`, `create_time`, `last_update_time`, `is_valid`, `tenant_id`, `series_number`, `putaway_qty`)
VALUES
  (53201, 53106, 2, 'practice-seed', '2026-05-16 10:00:00', '2026-05-16 10:00:00', 1, 1, 'SN-GROUND-001', 0),
  (53202, 53106, 3, 'practice-seed', '2026-05-16 10:01:00', '2026-05-16 10:01:00', 1, 1, 'SN-GROUND-002', 0),
  (53203, 53107, 4, 'practice-seed', '2026-05-14 10:00:00', '2026-05-14 10:00:00', 1, 1, 'SN-RECEIPT-001', 4);

-- ------------------------------------------------------------
-- 6. 发货主线、拣货专项与状态快照
-- ------------------------------------------------------------
INSERT INTO `dispatchlist` (`id`, `dispatch_no`, `dispatch_status`, `customer_id`, `customer_name`, `sku_id`, `qty`, `weight`, `volume`, `creator`, `create_time`, `damage_qty`, `lock_qty`, `picked_qty`, `intrasit_qty`, `package_qty`, `weighing_qty`, `actual_qty`, `sign_qty`, `package_no`, `package_person`, `package_time`, `weighing_no`, `weighing_person`, `weighing_weight`, `waybill_no`, `carrier`, `freightfee`, `last_update_time`, `tenant_id`, `pick_checker_id`, `pick_checker`)
VALUES
  (51901, 'DP-TRAIN-001', 2, 51401, '华东零售客户', 51701, 6, 15.000, 7.200, 'practice-seed', '2026-05-15 10:25:00', 0, 6, 0, 0, 0, 0, 0, 0, '', '', '1900-01-01 00:00:00', '', '', 0.000, '', '', 0.00, '2026-05-15 10:25:00', 1, 0, ''),
  (51902, 'DP-TRAIN-002', 2, 51402, '华南渠道客户', 51701, 5, 12.500, 6.000, 'practice-seed', '2026-05-15 10:26:00', 0, 5, 0, 0, 0, 0, 0, 0, '', '', '1900-01-01 00:00:00', '', '', 0.000, '', '', 0.00, '2026-05-15 10:26:00', 1, 0, ''),
  (51903, 'DP-TRAIN-003', 2, 51403, '华北电商客户', 51702, 3, 0.900, 0.060, 'practice-seed', '2026-05-15 10:27:00', 0, 3, 0, 0, 0, 0, 0, 0, '', '', '1900-01-01 00:00:00', '', '', 0.000, '', '', 0.00, '2026-05-15 10:27:00', 1, 0, ''),
  (51904, 'DP-E2E-001', 0, 51404, '全链路演练客户', 51703, 4, 7.200, 3.200, 'practice-seed', '2026-05-15 10:40:00', 0, 0, 0, 0, 0, 0, 0, 0, '', '', '1900-01-01 00:00:00', '', '', 0.000, '', '', 0.00, '2026-05-15 10:40:00', 1, 0, ''),
  (51905, 'DP-DEMO-NEW-001', 1, 51402, '华南渠道客户', 51701, 2, 5.000, 2.400, 'practice-seed', '2026-05-15 10:41:00', 0, 0, 0, 0, 0, 0, 0, 0, '', '', '1900-01-01 00:00:00', '', '', 0.000, '', '', 0.00, '2026-05-15 10:41:00', 1, 0, ''),
  (51906, 'DP-DEMO-PICKED-001', 3, 51403, '华北电商客户', 51702, 2, 0.600, 0.040, 'practice-seed', '2026-05-15 10:42:00', 0, 2, 2, 0, 0, 0, 0, 0, '', '', '1900-01-01 00:00:00', '', '', 0.000, '', '', 0.00, '2026-05-15 10:42:00', 1, 57002, '复核员-王敏'),
  (51907, 'DP-DEMO-PACKAGED-001', 4, 51401, '华东零售客户', 51702, 2, 0.600, 0.040, 'practice-seed', '2026-05-15 10:43:00', 0, 2, 2, 0, 2, 0, 0, 0, 'PKG-DEMO-001', '打包员-陈力', '2026-05-15 11:10:00', '', '', 0.000, '', '', 0.00, '2026-05-15 11:10:00', 1, 57002, '复核员-王敏'),
  (51908, 'DP-DEMO-WEIGHED-001', 5, 51402, '华南渠道客户', 51701, 2, 5.000, 2.400, 'practice-seed', '2026-05-15 10:44:00', 0, 2, 2, 0, 2, 2, 0, 0, 'PKG-DEMO-002', '打包员-陈力', '2026-05-15 11:20:00', 'WG-DEMO-001', '称重员-韩涛', 5.200, '', '', 0.00, '2026-05-15 11:30:00', 1, 57002, '复核员-王敏'),
  (51909, 'DP-DEMO-DELIVERED-001', 6, 51403, '华北电商客户', 51701, 2, 5.000, 2.400, 'practice-seed', '2026-05-15 10:45:00', 0, 0, 2, 2, 2, 2, 2, 0, 'PKG-DEMO-003', '打包员-陈力', '2026-05-15 11:40:00', 'WG-DEMO-002', '称重员-韩涛', 5.100, 'YB-DEMO-001', '课程快递', 18.00, '2026-05-15 12:00:00', 1, 57002, '复核员-王敏'),
  (51910, 'DP-DEMO-SIGNED-001', 7, 51401, '华东零售客户', 51702, 1, 0.300, 0.020, 'practice-seed', '2026-05-15 10:46:00', 0, 0, 1, 0, 1, 1, 1, 1, 'PKG-DEMO-004', '打包员-陈力', '2026-05-15 12:10:00', 'WG-DEMO-003', '称重员-韩涛', 0.320, 'YB-DEMO-002', '课程快递', 10.00, '2026-05-15 13:00:00', 1, 57002, '复核员-王敏');

INSERT INTO `dispatchpicklist` (`id`, `dispatchlist_id`, `goods_owner_id`, `goods_location_id`, `sku_id`, `pick_qty`, `picked_qty`, `is_update_stock`, `last_update_time`, `series_number`, `picker_id`, `picker`, `expiry_date`, `price`, `putaway_date`)
VALUES
  (52001, 51901, 51301, 51201, 51701, 6, 0, 0, '2026-05-15 10:30:00', 'LOT-A-202605', 0, '', '2026-12-31', 89.00, '2026-05-01'),
  (52002, 51902, 51301, 51201, 51701, 1, 0, 0, '2026-05-15 10:30:00', 'LOT-A-202605', 0, '', '2026-12-31', 89.00, '2026-05-01'),
  (52003, 51902, 51301, 51202, 51701, 4, 0, 0, '2026-05-15 10:30:00', 'LOT-A-202605', 0, '', '2026-12-31', 89.00, '2026-05-01'),
  (52004, 51903, 51301, 51202, 51702, 3, 0, 0, '2026-05-15 10:30:00', 'LOT-B-202605', 0, '', '2027-01-31', 12.50, '2026-05-02'),
  (52005, 51906, 51301, 51202, 51702, 2, 2, 0, '2026-05-15 10:42:00', 'OUT-PICKED-001', 57001, '拣货员-李明', '2027-01-31', 12.50, '2026-05-11'),
  (52006, 51907, 51301, 51201, 51702, 2, 2, 0, '2026-05-15 10:43:00', 'OUT-PACKAGED-001', 57001, '拣货员-李明', '2027-01-31', 12.50, '2026-05-11'),
  (52007, 51908, 51301, 51202, 51701, 2, 2, 0, '2026-05-15 10:44:00', 'OUT-WEIGHED-001', 57001, '拣货员-李明', '2026-12-31', 89.00, '2026-05-11'),
  (52008, 51909, 51301, 51203, 51701, 2, 2, 1, '2026-05-15 12:00:00', 'OUT-DELIVERED-001', 57001, '拣货员-李明', '2026-12-31', 89.00, '2026-05-11'),
  (52009, 51910, 51301, 51204, 51702, 1, 1, 1, '2026-05-15 13:00:00', 'OUT-SIGNED-001', 57001, '拣货员-李明', '2027-01-31', 12.50, '2026-05-11');

-- ------------------------------------------------------------
-- 7. 仓内作业演示快照：冻结 / 移库 / 调整 / 盘点 / 加工
-- ------------------------------------------------------------
INSERT INTO `stockfreeze` (`id`, `job_code`, `job_type`, `sku_id`, `goods_owner_id`, `goods_location_id`, `handler`, `handle_time`, `last_update_time`, `tenant_id`, `series_number`)
VALUES
  (54101, 'FREEZE-DEMO-001', 1, 51706, 51301, 51204, 'admin', '2026-05-15 14:00:00', '2026-05-15 14:00:00', 1, 'WORK-FREEZE-001'),
  (54102, 'FREEZE-DEMO-002', 0, 51706, 51301, 51203, 'admin', '2026-05-15 14:10:00', '2026-05-15 14:10:00', 1, 'WORK-UNFREEZE-001');

INSERT INTO `stockmove` (`id`, `job_code`, `move_status`, `sku_id`, `orig_goods_location_id`, `dest_googs_location_id`, `qty`, `goods_owner_id`, `handler`, `handle_time`, `creator`, `create_time`, `last_update_time`, `tenant_id`, `series_number`, `expiry_date`, `price`, `putaway_date`)
VALUES
  (54001, 'MOVE-DEMO-001', 0, 51706, 51204, 51201, 2, 51301, '', '1900-01-01 00:00:00', 'practice-seed', '2026-05-15 14:20:00', '2026-05-15 14:20:00', 1, 'WORK-MOVE-PENDING', '2027-05-31', 25.00, '2026-05-11'),
  (54002, 'MOVE-DEMO-002', 1, 51706, 51203, 51202, 3, 51301, 'admin', '2026-05-15 14:30:00', 'practice-seed', '2026-05-15 14:25:00', '2026-05-15 14:30:00', 1, 'WORK-MOVE-DONE', '2027-05-31', 25.00, '2026-05-11');

INSERT INTO `stockadjust` (`id`, `job_code`, `job_type`, `sku_id`, `goods_owner_id`, `goods_location_id`, `qty`, `creator`, `create_time`, `last_update_time`, `tenant_id`, `is_update_stock`, `source_table_id`, `series_number`, `expiry_date`, `price`, `putaway_date`)
VALUES
  (54201, 'ADJUST-DEMO-001', 0, 51706, 51301, 51203, 2, 'practice-seed', '2026-05-15 14:40:00', '2026-05-15 14:40:00', 1, 0, 0, 'WORK-ADJUST-PENDING', '2027-05-31', 25.00, '2026-05-11'),
  (54202, 'ADJUST-DEMO-002', 0, 51706, 51301, 51203, 1, 'practice-seed', '2026-05-15 14:50:00', '2026-05-15 14:50:00', 1, 1, 0, 'WORK-ADJUST-DONE', '2027-05-31', 25.00, '2026-05-11'),
  (54203, 'ADJUST-DEMO-003', 1, 51706, 51301, 51204, 1, 'practice-seed', '2026-05-15 15:00:00', '2026-05-15 15:00:00', 1, 1, 54302, 'WORK-TAKE-DONE', '2027-05-31', 25.00, '2026-05-11'),
  (54204, 'ADJUST-DEMO-004', 2, 51706, 51301, 51202, 3, 'practice-seed', '2026-05-15 15:10:00', '2026-05-15 15:10:00', 1, 1, 54504, 'WORK-PROC-TGT-DONE', '2027-05-31', 25.00, '2026-05-11');

INSERT INTO `stocktaking` (`id`, `job_code`, `job_status`, `sku_id`, `goods_owner_id`, `goods_location_id`, `book_qty`, `counted_qty`, `difference_qty`, `handler`, `handle_time`, `creator`, `create_time`, `last_update_time`, `tenant_id`, `series_number`, `expiry_date`, `price`, `putaway_date`)
VALUES
  (54301, 'TAKING-DEMO-001', 0, 51706, 51301, 51203, 10, 0, 0, '', '1900-01-01 00:00:00', 'practice-seed', '2026-05-15 15:20:00', '2026-05-15 15:20:00', 1, 'WORK-TAKE-OPEN', '2027-05-31', 25.00, '2026-05-11'),
  (54302, 'TAKING-DEMO-002', 1, 51706, 51301, 51204, 8, 7, -1, 'admin', '2026-05-15 15:30:00', 'practice-seed', '2026-05-15 15:25:00', '2026-05-15 15:30:00', 1, 'WORK-TAKE-DONE', '2027-05-31', 25.00, '2026-05-11');

INSERT INTO `stockprocess` (`id`, `job_code`, `job_type`, `process_status`, `processor`, `process_time`, `creator`, `create_time`, `last_update_time`, `tenant_id`)
VALUES
  (54401, 'PROCESS-DEMO-001', 0, 0, '', '1900-01-01 00:00:00', 'practice-seed', '2026-05-15 15:40:00', '2026-05-15 15:40:00', 1),
  (54402, 'PROCESS-DEMO-002', 1, 1, 'admin', '2026-05-15 15:55:00', 'practice-seed', '2026-05-15 15:45:00', '2026-05-15 15:55:00', 1);

INSERT INTO `stockprocessdetail` (`id`, `stock_process_id`, `sku_id`, `goods_owner_id`, `goods_location_id`, `qty`, `last_update_time`, `tenant_id`, `is_source`, `is_update_stock`, `series_number`, `expiry_date`, `price`, `putaway_date`)
VALUES
  (54501, 54401, 51706, 51301, 51203, 2, '2026-05-15 15:40:00', 1, 1, 0, 'WORK-PROC-SRC-OPEN', '2027-05-31', 25.00, '2026-05-11'),
  (54502, 54401, 51706, 51301, 51201, 2, '2026-05-15 15:40:00', 1, 0, 0, 'WORK-PROC-TGT-OPEN', '2027-05-31', 25.00, '2026-05-11'),
  (54503, 54402, 51706, 51301, 51203, 3, '2026-05-15 15:55:00', 1, 1, 1, 'WORK-PROC-SRC-DONE', '2027-05-31', 25.00, '2026-05-11'),
  (54504, 54402, 51706, 51301, 51202, 3, '2026-05-15 15:55:00', 1, 0, 1, 'WORK-PROC-TGT-DONE', '2027-05-31', 25.00, '2026-05-11');

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;
