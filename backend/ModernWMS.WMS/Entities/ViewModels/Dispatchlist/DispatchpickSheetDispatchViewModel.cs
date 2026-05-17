using System.ComponentModel.DataAnnotations;

namespace ModernWMS.WMS.Entities.ViewModels
{
    /// <summary>
    /// related dispatch order in a generated pick sheet
    /// </summary>
    public class DispatchpickSheetDispatchViewModel
    {
        /// <summary>
        /// dispatchlist id
        /// </summary>
        [Display(Name = "dispatchlist_id")]
        public int dispatchlist_id { get; set; } = 0;

        /// <summary>
        /// dispatch no
        /// </summary>
        [Display(Name = "dispatch_no")]
        public string dispatch_no { get; set; } = string.Empty;

        /// <summary>
        /// customer name
        /// </summary>
        [Display(Name = "customer_name")]
        public string customer_name { get; set; } = string.Empty;

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
    }
}
