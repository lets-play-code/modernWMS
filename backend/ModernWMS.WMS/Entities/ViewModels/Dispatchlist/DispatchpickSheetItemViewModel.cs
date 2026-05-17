using ModernWMS.Core.Utility;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ModernWMS.WMS.Entities.ViewModels
{
    /// <summary>
    /// aggregated pick sheet row
    /// </summary>
    public class DispatchpickSheetItemViewModel
    {
        /// <summary>
        /// sku id
        /// </summary>
        [Display(Name = "sku_id")]
        public int sku_id { get; set; } = 0;

        /// <summary>
        /// goods owner id
        /// </summary>
        [Display(Name = "goods_owner_id")]
        public int goods_owner_id { get; set; } = 0;

        /// <summary>
        /// goods location id
        /// </summary>
        [Display(Name = "goods_location_id")]
        public int goods_location_id { get; set; } = 0;

        /// <summary>
        /// spu code
        /// </summary>
        public string spu_code { get; set; } = string.Empty;

        /// <summary>
        /// spu name
        /// </summary>
        public string spu_name { get; set; } = string.Empty;

        /// <summary>
        /// spu description
        /// </summary>
        public string spu_description { get; set; } = string.Empty;

        /// <summary>
        /// sku code
        /// </summary>
        public string sku_code { get; set; } = string.Empty;

        /// <summary>
        /// bar code
        /// </summary>
        public string bar_code { get; set; } = string.Empty;

        /// <summary>
        /// image url
        /// </summary>
        public string image_url { get; set; } = string.Empty;

        /// <summary>
        /// goods owner name
        /// </summary>
        public string goods_owner_name { get; set; } = string.Empty;

        /// <summary>
        /// warehouse name
        /// </summary>
        public string warehouse_name { get; set; } = string.Empty;

        /// <summary>
        /// warehouse area name
        /// </summary>
        public string warehouse_area_name { get; set; } = string.Empty;

        /// <summary>
        /// location name
        /// </summary>
        public string location_name { get; set; } = string.Empty;

        /// <summary>
        /// series number
        /// </summary>
        [Display(Name = "series_number")]
        [MaxLength(64, ErrorMessage = "MaxLength")]
        public string series_number { get; set; } = string.Empty;

        /// <summary>
        /// expiry date
        /// </summary>
        public DateTime expiry_date { get; set; } = UtilConvert.MinDate;

        /// <summary>
        /// price
        /// </summary>
        public decimal price { get; set; } = 0;

        /// <summary>
        /// putaway date
        /// </summary>
        public DateTime putaway_date { get; set; } = UtilConvert.MinDate;

        /// <summary>
        /// planned pick qty
        /// </summary>
        [Display(Name = "pick_qty")]
        public int pick_qty { get; set; } = 0;

        /// <summary>
        /// confirmed pick qty
        /// </summary>
        [Display(Name = "picked_qty")]
        public int picked_qty { get; set; } = 0;

        /// <summary>
        /// related dispatch orders
        /// </summary>
        public List<DispatchpickSheetDispatchViewModel> related_dispatches { get; set; } = new List<DispatchpickSheetDispatchViewModel>();
    }
}
