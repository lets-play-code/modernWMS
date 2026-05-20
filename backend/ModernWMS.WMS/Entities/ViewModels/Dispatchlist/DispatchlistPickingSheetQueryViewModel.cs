using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ModernWMS.WMS.Entities.ViewModels
{
    /// <summary>
    /// runtime picking-sheet query viewModel
    /// </summary>
    public class DispatchlistPickingSheetQueryViewModel
    {
        /// <summary>
        /// selected dispatchlist ids
        /// </summary>
        [Display(Name = "dispatchlist_ids")]
        [Required(ErrorMessage = "Required")]
        [MinLength(1, ErrorMessage = "Required")]
        public List<int> dispatchlist_ids { get; set; } = new List<int>();
    }
}
