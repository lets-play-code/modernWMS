using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using ModernWMS.Core.Utility;

namespace ModernWMS.WMS.Entities.ViewModels
{
    /// <summary>
    /// aggregated runtime picking-sheet line viewModel
    /// </summary>
    public class DispatchlistPickingSheetLineViewModel
    {
        /// <summary>
        /// response-only grouping key
        /// </summary>
        [Display(Name = "group_key")]
        public string group_key { get; set; } = string.Empty;

        /// <summary>
        /// pick detail ids included in the aggregated line
        /// </summary>
        [Display(Name = "pick_detail_ids")]
        public List<int> pick_detail_ids { get; set; } = new List<int>();

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
        /// sku code
        /// </summary>
        public string sku_code { get; set; } = string.Empty;

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
        /// aggregated pick qty
        /// </summary>
        [Display(Name = "pick_qty")]
        public int pick_qty { get; set; } = 0;

        /// <summary>
        /// aggregated picked qty
        /// </summary>
        [Display(Name = "picked_qty")]
        public int picked_qty { get; set; } = 0;

        /// <summary>
        /// related dispatch breakdowns
        /// </summary>
        public List<DispatchlistPickingSheetDispatchRefViewModel> related_dispatches { get; set; } = new List<DispatchlistPickingSheetDispatchRefViewModel>();
    }
}
