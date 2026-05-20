using System.ComponentModel.DataAnnotations;

namespace ModernWMS.WMS.Entities.ViewModels
{
    /// <summary>
    /// related dispatch reference in a runtime picking-sheet line
    /// </summary>
    public class DispatchlistPickingSheetDispatchRefViewModel
    {
        /// <summary>
        /// dispatch no
        /// </summary>
        [Display(Name = "dispatch_no")]
        public string dispatch_no { get; set; } = string.Empty;

        /// <summary>
        /// dispatchlist id
        /// </summary>
        [Display(Name = "dispatchlist_id")]
        public int dispatchlist_id { get; set; } = 0;

        /// <summary>
        /// aggregated pick qty for this dispatch reference
        /// </summary>
        [Display(Name = "pick_qty")]
        public int pick_qty { get; set; } = 0;

        /// <summary>
        /// aggregated picked qty for this dispatch reference
        /// </summary>
        [Display(Name = "picked_qty")]
        public int picked_qty { get; set; } = 0;
    }
}
