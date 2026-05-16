CREATE DATABASE wms;
USE wms;
CREATE TABLE IF NOT EXISTS `company` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`company_name` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`city` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`address` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`manager` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`contact_tel` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `supplier` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`supplier_name` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`city` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`address` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`email` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`manager` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`contact_tel` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`is_valid` bit  NOT NULL  DEFAULT 1  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `customer` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`customer_name` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`city` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`address` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`email` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`manager` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`contact_tel` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`is_valid` bit  NOT NULL  DEFAULT 1  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `warehouse` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`warehouse_name` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`city` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`address` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`email` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`manager` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`contact_tel` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`is_valid` bit  NOT NULL  DEFAULT 1  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `warehousearea` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`warehouse_id` int  NOT NULL  ,
	`area_name` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`area_property` tinyint  NOT NULL  DEFAULT 0  ,
	`parent_id` int  NOT NULL  DEFAULT 0  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`is_valid` bit  NOT NULL  DEFAULT 1  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `goodslocation` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`warehouse_id` int  NOT NULL  DEFAULT 0  ,
	`warehouse_name` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`warehouse_area_id` int  NOT NULL  DEFAULT 0  ,
	`warehouse_area_name` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`warehouse_area_property` tinyint  NOT NULL  DEFAULT 0  ,
	`location_name` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`location_length` decimal(5,2)  NOT NULL  DEFAULT 0 ,
	`location_width` decimal(5,2)  NOT NULL  DEFAULT 0  ,
	`location_heigth` decimal(5,2)  NOT NULL  DEFAULT 0  ,
	`location_volume` decimal(12,2)  NOT NULL  DEFAULT 0  ,
	`location_load` decimal(8,2)  NOT NULL  DEFAULT 0  ,
	`roadway_number` varchar(10) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`shelf_number` varchar(10) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`layer_number` varchar(10) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`tag_number` varchar(10) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`is_valid` bit  NOT NULL  DEFAULT 1  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `freightfee` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`carrier` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`departure_city` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`arrival_city` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`price_per_weight` decimal(6,2)  NOT NULL  DEFAULT 0  ,
	`price_per_volume` decimal(6,2)  NOT NULL  DEFAULT 0  ,
	`min_payment` decimal(8,2)  NOT NULL  DEFAULT 0  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`is_valid` bit  NOT NULL  DEFAULT 1  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `category` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`category_name` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`parent_id` int  NOT NULL  DEFAULT 0  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`is_valid` bit  NOT NULL  DEFAULT 1  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `spu` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`spu_code` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`spu_name` varchar(200) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`category_id` int  NOT NULL  DEFAULT 0  ,
	`spu_description` varchar(1000) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`supplier_id` int  NOT NULL  DEFAULT 0  ,
	`supplier_name` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`brand` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`origin` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`length_unit` tinyint  NOT NULL  DEFAULT 1  ,
	`volume_unit` tinyint  NOT NULL  DEFAULT 0  ,
	`weight_unit` tinyint  NOT NULL  DEFAULT 1  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`is_valid` bit  NOT NULL  DEFAULT 1  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `sku` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`spu_id` int  NOT NULL  DEFAULT 0  ,
	`sku_code` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`sku_name` varchar(200) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`weight` decimal(8,3)  NOT NULL  DEFAULT 0  ,
	`lenght` decimal(8,3)  NOT NULL  DEFAULT 0  ,
	`width` decimal(8,3)  NOT NULL  DEFAULT 0  ,
	`height` decimal(8,3)  NOT NULL  DEFAULT 0  ,
	`volume` decimal(15,3)  NOT NULL  DEFAULT 0  ,
	`unit` varchar(5) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`cost` decimal(10,2)  NOT NULL  DEFAULT 0  ,
	`price` decimal(10,2)  NOT NULL  DEFAULT 0  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`bar_code` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT '',
	`image_url` varchar(1024) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT ''
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `sku_safety_stock` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`sku_id` int  NOT NULL  DEFAULT 0  ,
	`warehouse_id` int  NOT NULL  DEFAULT 0  ,
	`safety_stock_qty` int  NOT NULL  DEFAULT 0
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `user` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`user_num` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`user_name` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`contact_tel` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`user_role` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`sex` varchar(10) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`is_valid` bit  NOT NULL  DEFAULT 1  ,
	`auth_string` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`email` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `userrole` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`role_name` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`is_valid` bit  NOT NULL  DEFAULT 1  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `menu` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`menu_name` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`module` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`vue_path` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`vue_path_detail` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`vue_directory` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`sort` int  NOT NULL  DEFAULT 0  ,
	`tenant_id` bigint  NOT NULL  ,
	`menu_actions` JSON  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `rolemenu` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`userrole_id` int  NOT NULL  DEFAULT 0  ,
	`menu_id` int  NOT NULL  DEFAULT 0  ,
	`authority` tinyint  NOT NULL  DEFAULT 0  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`tenant_id` bigint  NOT NULL  ,
	`menu_actions_authority` JSON  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `goodsowner` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`goods_owner_name` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`city` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`address` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`manager` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`contact_tel` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`is_valid` bit  NOT NULL  DEFAULT 1  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `asnmaster` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`asn_no` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`asn_batch` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`estimated_arrival_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`asn_status` tinyint  NOT NULL  DEFAULT 0  ,
	`weight` decimal(12,3)  NOT NULL  DEFAULT 0  ,
	`volume` decimal(15,3)  NOT NULL  DEFAULT 0  ,
	`goods_owner_id` int  NOT NULL  DEFAULT 0  ,
	`goods_owner_name` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `asn` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`asnmaster_id` int  NOT NULL  DEFAULT 0  ,
	`asn_no` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`asn_status` tinyint  NOT NULL  DEFAULT 0  ,
	`spu_id` int  NOT NULL  DEFAULT 0  ,
	`sku_id` int  NOT NULL  DEFAULT 0  ,
	`asn_qty` int  NOT NULL  DEFAULT 0  ,
	`actual_qty` int  NOT NULL  DEFAULT 0  ,
	`sorted_qty` int  NOT NULL  DEFAULT 0  ,
	`shortage_qty` int  NOT NULL  DEFAULT 0  ,
	`more_qty` int  NOT NULL  DEFAULT 0  ,
	`damage_qty` int  NOT NULL  DEFAULT 0  ,
	`weight` decimal(12,3)  NOT NULL  DEFAULT 0  ,
	`volume` decimal(15,3)  NOT NULL  DEFAULT 0  ,
	`supplier_id` int  NOT NULL  DEFAULT 0  ,
	`supplier_name` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`goods_owner_id` int  NOT NULL  DEFAULT 0  ,
	`goods_owner_name` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`is_valid` bit  NOT NULL  DEFAULT 1  ,
	`tenant_id` bigint  NOT NULL  ,
	`arrival_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`unload_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`unload_person_id` int  NOT NULL  DEFAULT 0  ,
	`unload_person` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `asnsort` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`asn_id` int  NOT NULL  DEFAULT 0  ,
	`sorted_qty` int  NOT NULL  DEFAULT 0  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`is_valid` bit  NOT NULL  DEFAULT 1  ,
	`tenant_id` bigint  NOT NULL  ,
	`series_number` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`putaway_qty` int  NOT NULL  DEFAULT 0
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `stock` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`sku_id` int  NOT NULL  DEFAULT 0  ,
	`goods_location_id` int  NOT NULL  DEFAULT 0  ,
	`qty` int  NOT NULL  DEFAULT 0  ,
	`goods_owner_id` int  NOT NULL  DEFAULT 0  ,
	`is_freeze` bit  NOT NULL  DEFAULT 0  ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`tenant_id` bigint  NOT NULL  ,
	`series_number` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `stockmove` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`job_code` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`move_status` tinyint  NOT NULL  DEFAULT 0  ,
	`sku_id` int  NOT NULL  DEFAULT 0  ,
	`orig_goods_location_id` int  NOT NULL  DEFAULT 0  ,
	`dest_googs_location_id` int  NOT NULL  DEFAULT 0  ,
	`qty` int  NOT NULL  DEFAULT 0  ,
	`goods_owner_id` int  NOT NULL  DEFAULT 0  ,
	`handler` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`handle_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`tenant_id` bigint  NOT NULL  ,
	`series_number` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `stocktaking` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`job_code` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`job_status` bit  NOT NULL  DEFAULT 0  ,
	`sku_id` int  NOT NULL  DEFAULT 0  ,
	`goods_owner_id` int  NOT NULL  DEFAULT 0  ,
	`goods_location_id` int  NOT NULL  DEFAULT 0  ,
	`book_qty` int  NOT NULL  DEFAULT 0  ,
	`counted_qty` int  NOT NULL  DEFAULT 0  ,
	`difference_qty` int  NOT NULL  DEFAULT 0  ,
	`handler` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`handle_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`tenant_id` bigint  NOT NULL  ,
	`series_number` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `stockadjust` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`job_code` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`job_type` tinyint  NOT NULL  DEFAULT 0  ,
	`sku_id` int  NOT NULL  DEFAULT 0  ,
	`goods_owner_id` int  NOT NULL  DEFAULT 0  ,
	`goods_location_id` int  NOT NULL  DEFAULT 0  ,
	`qty` int  NOT NULL  DEFAULT 0  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`tenant_id` bigint  NOT NULL  ,
	`is_update_stock` bit  NOT NULL  DEFAULT 0  ,
	`source_table_id` int  NOT NULL  DEFAULT 0  ,
	`series_number` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `stockfreeze` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`job_code` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`job_type` bit  NOT NULL  DEFAULT 1  ,
	`sku_id` int  NOT NULL  DEFAULT 0  ,
	`goods_owner_id` int  NOT NULL  DEFAULT 0  ,
	`goods_location_id` int  NOT NULL  DEFAULT 0  ,
	`handler` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`handle_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`tenant_id` bigint  NOT NULL  ,
	`series_number` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `stockprocess` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`job_code` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`job_type` bit  NOT NULL  DEFAULT 0  ,
	`process_status` bit  NOT NULL  DEFAULT 0  ,
	`processor` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`process_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `stockprocessdetail` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`stock_process_id` int  NOT NULL  DEFAULT 0  ,
	`sku_id` int  NOT NULL  DEFAULT 0  ,
	`goods_owner_id` int  NOT NULL  DEFAULT 0  ,
	`goods_location_id` int  NOT NULL  DEFAULT 0  ,
	`qty` int  NOT NULL  DEFAULT 0  ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`tenant_id` bigint  NOT NULL  ,
	`is_source` bit  NOT NULL  DEFAULT 0  ,
	`is_update_stock` bit  NOT NULL  DEFAULT 0  ,
	`series_number` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `dispatchlist` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`dispatch_no` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`dispatch_status` tinyint  NOT NULL  DEFAULT 0  ,
	`customer_id` int  NOT NULL  DEFAULT 0  ,
	`customer_name` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`sku_id` int  NOT NULL  DEFAULT 0  ,
	`qty` int  NOT NULL  DEFAULT 0  ,
	`weight` decimal(12,3)  NOT NULL  DEFAULT 0  ,
	`volume` decimal(15,3)  NOT NULL  DEFAULT 0  ,
	`creator` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`create_time` datetime  NOT NULL  DEFAULT '1000-01-01'   ,
	`damage_qty` int  NOT NULL  DEFAULT 0  ,
	`lock_qty` int  NOT NULL  DEFAULT 0  ,
	`picked_qty` int  NOT NULL  DEFAULT 0  ,
	`intrasit_qty` int  NOT NULL  DEFAULT 0  ,
	`package_qty` int  NOT NULL  DEFAULT 0  ,
	`weighing_qty` int  NOT NULL  DEFAULT 0  ,
	`actual_qty` int  NOT NULL  DEFAULT 0  ,
	`sign_qty` int  NOT NULL  DEFAULT 0  ,
	`package_no` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`package_person` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`package_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`weighing_no` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`weighing_person` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`weighing_weight` decimal(15,3)  NOT NULL  DEFAULT 0  ,
	`waybill_no` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`carrier` varchar(256) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`freightfee` decimal(10,2)  NOT NULL  DEFAULT 0  ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `dispatchpicklist` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`dispatchlist_id` int  NOT NULL  DEFAULT 0  ,
	`goods_owner_id` int  NOT NULL  DEFAULT 0  ,
	`goods_location_id` int  NOT NULL  DEFAULT 0  ,
	`sku_id` int  NOT NULL  DEFAULT 0  ,
	`pick_qty` int  NOT NULL  DEFAULT 0  ,
	`picked_qty` int  NOT NULL  DEFAULT 0  ,
	`is_update_stock` bit  NOT NULL  DEFAULT 0  ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`series_number` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `action_log` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`vue_path` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`user_name` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`action_content` varchar(2000) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`action_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `user_defined_print_solution` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY   ,
	`vue_path` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`tab_page` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''   ,
	`solution_name` varchar(64) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''   ,
	`config_json` JSON  NOT NULL  ,
	`report_length` decimal(10,2)  NOT NULL  DEFAULT 0   ,
	`report_width` decimal(10,2)  NOT NULL  DEFAULT 0   ,
	`report_direction` varchar(2) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1000-01-01'  ,
	`tenant_id` bigint  NOT NULL
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
CREATE TABLE IF NOT EXISTS `global_unique_serial` (
	`id` int AUTO_INCREMENT  NOT NULL PRIMARY KEY  ,
	`table_name` varchar(128) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`prefix_char` varchar(8) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT ''  ,
	`reset_rule` varchar(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci   NOT NULL  DEFAULT '' ,
	`current_no` int  NOT NULL  DEFAULT 1   ,
	`last_update_time` datetime  NOT NULL  DEFAULT '1900-01-01'   ,
	`tenant_id` bigint  NOT NULL  DEFAULT 0
) ENGINE = INNODB CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ;
ALTER TABLE `asn` ADD COLUMN `expiry_date` DATE  DEFAULT '1000-01-01' NOT NULL;
ALTER TABLE `stock` ADD COLUMN `expiry_date` DATE  DEFAULT '1000-01-01' NOT NULL;
ALTER TABLE `dispatchpicklist` ADD COLUMN `picker_id` INT  DEFAULT 0 NOT NULL;
ALTER TABLE `dispatchpicklist` ADD COLUMN `picker` VARCHAR(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT '' NOT NULL;
ALTER TABLE `company` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `company` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `supplier` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `supplier` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `customer` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `customer` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `warehouse` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `warehouse` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `warehousearea` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `warehousearea` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `goodslocation` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `goodslocation` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `freightfee` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `freightfee` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `category` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `category` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `spu` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `spu` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `sku` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `sku` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `user` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `user` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `userrole` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `userrole` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `rolemenu` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `rolemenu` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `goodsowner` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `goodsowner` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `asnmaster` CHANGE `estimated_arrival_time` `estimated_arrival_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `asnmaster` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `asnmaster` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `asn` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `asn` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `asn` CHANGE `arrival_time` `arrival_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `asn` CHANGE `unload_time` `unload_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `asn` CHANGE `expiry_date` `expiry_date` DATE  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `asnsort` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `asnsort` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stock` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockmove` CHANGE `handle_time` `handle_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockmove` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockmove` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stocktaking` CHANGE `handle_time` `handle_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stocktaking` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stocktaking` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockadjust` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockadjust` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockfreeze` CHANGE `handle_time` `handle_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockfreeze` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockprocess` CHANGE `process_time` `process_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockprocess` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockprocess` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockprocessdetail` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `dispatchlist` CHANGE `create_time` `create_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `dispatchlist` CHANGE `package_time` `package_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `dispatchlist` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `dispatchpicklist` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `action_log` CHANGE `action_time` `action_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `user_defined_print_solution` CHANGE `last_update_time` `last_update_time` DATETIME  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `dispatchlist` ADD COLUMN `pick_checker_id` INT  DEFAULT 0 NOT NULL;
ALTER TABLE `dispatchlist` ADD COLUMN `pick_checker` VARCHAR(32) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT '' NOT NULL;
ALTER TABLE `asn` ADD COLUMN `price` DECIMAL(10,2)  DEFAULT 0 NOT NULL;
ALTER TABLE `stock` ADD COLUMN `price` DECIMAL(10,2)  DEFAULT 0 NOT NULL;
ALTER TABLE `stockmove` ADD COLUMN `expiry_date` DATE  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockmove` ADD COLUMN `price` DECIMAL(10,2)  DEFAULT 0 NOT NULL;
ALTER TABLE `stocktaking` ADD COLUMN `expiry_date` DATE  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stocktaking` ADD COLUMN `price` DECIMAL(10,2)  DEFAULT 0 NOT NULL;
ALTER TABLE `stockadjust` ADD COLUMN `expiry_date` DATE  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockadjust` ADD COLUMN `price` DECIMAL(10,2)  DEFAULT 0 NOT NULL;
ALTER TABLE `stockprocessdetail` ADD COLUMN `expiry_date` DATE  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockprocessdetail` ADD COLUMN `price` DECIMAL(10,2)  DEFAULT 0 NOT NULL;
ALTER TABLE `dispatchpicklist` ADD COLUMN `expiry_date` DATE  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `dispatchpicklist` ADD COLUMN `price` DECIMAL(10,2)  DEFAULT 0 NOT NULL;
ALTER TABLE `stock` ADD COLUMN `putaway_date` DATE  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockmove` ADD COLUMN `putaway_date` DATE  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stocktaking` ADD COLUMN `putaway_date` DATE  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockadjust` ADD COLUMN `putaway_date` DATE  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `stockprocessdetail` ADD COLUMN `putaway_date` DATE  DEFAULT '1900-01-01' NOT NULL;
ALTER TABLE `dispatchpicklist` ADD COLUMN `putaway_date` DATE  DEFAULT '1900-01-01' NOT NULL;


INSERT INTO `userrole` (`id`, `role_name`, `is_valid`, `create_time`, `last_update_time`, `tenant_id`)
VALUES(1,'administrator',TRUE,'2022-12-21 10:30:00','2022-12-23 08:26:36',1);

INSERT INTO `user` (`id`, `user_num`, `user_name`, `contact_tel`, `user_role`, `sex`, `is_valid`, `auth_string`, `creator`, `create_time`, `last_update_time`, `tenant_id`, `email`)
VALUES(1,'admin','Administrator','18559851','administrator','male',TRUE,'c4ca4238a0b923820dcc509a6f75849b','admin','1000-01-01 00:00:00','2022-12-23 10:55:37',1,'');


INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (1, 'companySetting', 'baseModule', 'companySetting', '', 'base/companySetting', 1, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (2, 'userRoleSetting', 'baseModule', 'userRoleSetting', '', 'base/userRoleSetting', 2, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (3, 'roleMenu', 'baseModule', 'roleMenu', '', 'base/roleMenu', 3, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (4, 'userManagement', 'baseModule', 'userManagement', '', 'base/userManagement', 4, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (5, 'commodityCategorySetting', 'baseModule', 'commodityCategorySetting', '', 'base/commodityCategorySetting', 5, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (6, 'commodityManagement', 'baseModule', 'commodityManagement', '', 'base/commodityManagement', 6, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (7, 'supplier', 'baseModule', 'supplier', '', 'base/supplier', 7, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (8, 'warehouseSetting', 'baseModule', 'warehouseSetting', '', 'base/warehouseSetting', 8, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (9, 'ownerOfCargo', 'baseModule', 'ownerOfCargo', '', 'base/ownerOfCargo', 9, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (10, 'freightSetting', 'baseModule', 'freightSetting', '', 'base/freightSetting', 10, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (11, 'customer', 'baseModule', 'customer', '', 'base/customer', 11, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (12, 'stockManagement', 'statisticAnalysis', 'stockManagement', '', 'wms/stockManagement', 3, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (13, 'warehouseProcessing', 'warehouseWorkingModule', 'warehouseProcessing', '', 'warehouseWorking/warehouseProcessing', 4, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (14, 'warehouseMove', 'warehouseWorkingModule', 'warehouseMove', '', 'warehouseWorking/warehouseMove', 5, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (15, 'warehouseFreeze', 'warehouseWorkingModule', 'warehouseFreeze', '', 'warehouseWorking/warehouseFreeze', 6, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (16, 'warehouseAdjust', 'warehouseWorkingModule', 'warehouseAdjust', '', 'warehouseWorking/warehouseAdjust', 7, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (17, 'warehouseTaking', 'warehouseWorkingModule', 'warehouseTaking', '', 'warehouseWorking/warehouseTaking', 8, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (18, 'stockAsn', '', 'stockAsn', '', 'wms/stockAsn', 2, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (19, 'deliveryManagement', '', 'deliveryManagement', '', 'deliveryManagement/deliveryManagement', 5, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (20, 'saftyStock', 'statisticAnalysis', 'saftyStock', '', 'statisticAnalysis/saftyStock', 4, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (21, 'asnStatistic', 'statisticAnalysis', 'asnStatistic', '', 'statisticAnalysis/asnStatistic', 5, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (22, 'deliveryStatistic', 'statisticAnalysis', 'deliveryStatistic', '', 'statisticAnalysis/deliveryStatistic', 6, 1, '[]');
INSERT INTO `wms`.`menu`(`id`, `menu_name`, `module`, `vue_path`, `vue_path_detail`, `vue_directory`, `sort`, `tenant_id`, `menu_actions`) VALUES (23, 'print', 'baseModule', 'print', '', 'base/print', 11, 1, '[]');


INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (1, 1, 2, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"save\", \"delete\", \"export\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (2, 1, 3, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (3, 1, 4, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"delete\", \"save\", \"import\", \"export\", \"resetPwd\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (4, 1, 5, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"save\", \"delete\", \"export\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (5, 1, 6, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"save\", \"delete\", \"export\", \"saftyStock\", \"printQrCode\", \"printBarCode\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (6, 1, 7, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"delete\", \"save\", \"import\", \"export\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (7, 1, 8, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"warehouse-save\", \"warehouse-delete\", \"warehouse-import\", \"warehouse-export\", \"area-save\", \"area-delete\", \"area-export\", \"location-save\", \"location-delete\", \"location-export\", \"location-printBarCode\", \"location-printQrCode\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (8, 1, 9, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"save\", \"delete\", \"import\", \"export\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (9, 1, 10, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"save\", \"delete\", \"import\", \"export\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (10, 1, 11, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"save\", \"delete\", \"import\", \"export\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (11, 1, 12, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"area-export\", \"stock-export\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (12, 1, 13, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"group\", \"split\", \"confirmOpeartion\", \"confirmAdjust\", \"delete\", \"export\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (13, 1, 14, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"save\", \"delete\", \"export\", \"confirm\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (14, 1, 15, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"freeze\", \"unfreeze\", \"export\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (15, 1, 16, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"export\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (16, 1, 17, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"save\", \"delete\", \"export\", \"confirmOpeartion\", \"confirmAdjust\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (17, 1, 18, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"notice-save\", \"notice-delete\", \"notice-export\", \"delivered-confirm\", \"delivered-export\", \"unloaded-confirm\", \"unloaded-delete\", \"unloaded-export\", \"sorted-editCount\", \"sorted-confirm\", \"sorted-delete\", \"sorted-export\", \"putOnTheShelf-editArrival\", \"putOnTheShelf-delete\", \"putOnTheShelf-export\", \"detail-export\", \"notice-printQrCode\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (18, 1, 19, 1, '2023-08-30 15:36:15', '2023-10-11 10:11:58', 1, '[\"invoice-save\", \"invoice-confirm\", \"invoice-revoke\", \"invoice-delete\", \"invoice-export\", \"picked-confirm\", \"picked-revoke\", \"picked-export\", \"packaged-package\", \"packaged-export\", \"packaged-revoke\", \"weighed-weigh\", \"weighed-revoke\", \"weighed-export\", \"delivered-delivery\", \"delivered-setCarrier\", \"delivered-signIn\", \"delivered-export\", \"signedIn-export\", \"invoice-printQrCode\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (19, 1, 1, 1, '2023-08-31 15:35:10', '2023-10-11 10:11:58', 1, '[\"save\", \"delete\", \"export\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (20, 1, 20, 1, '2023-09-01 09:43:56', '2023-10-11 10:11:58', 1, '[\"export\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (21, 1, 21, 1, '2023-09-08 11:08:28', '2023-10-11 10:11:58', 1, '[\"export\"]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (22, 1, 22, 1, '2023-09-08 11:08:28', '2023-10-11 10:11:58', 1, '[]');
INSERT INTO `wms`.`rolemenu`(`id`, `userrole_id`, `menu_id`, `authority`, `create_time`, `last_update_time`, `tenant_id`, `menu_actions_authority`) VALUES (23, 1, 23, 1, '2023-10-11 10:11:58', '2023-10-11 10:12:03', 1, '[\"save\", \"delete\", \"export\"]');
