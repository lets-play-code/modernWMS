using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ModernWMS.WMS.Entities.ViewModels
{
    /// <summary>
    /// item-level pick operation viewModel
    /// </summary>
    public class DispatchlistPickItemsOperationViewModel
    {
        /// <summary>
        /// target pick detail ids
        /// </summary>
        [Display(Name = "pick_detail_ids")]
        [Required(ErrorMessage = "Required")]
        [MinLength(1, ErrorMessage = "Required")]
        public List<int> pick_detail_ids { get; set; } = new List<int>();
    }
}
