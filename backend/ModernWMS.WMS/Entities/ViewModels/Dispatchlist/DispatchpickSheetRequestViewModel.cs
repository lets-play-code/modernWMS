using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ModernWMS.WMS.Entities.ViewModels
{
    /// <summary>
    /// request for generating a pick sheet
    /// </summary>
    public class DispatchpickSheetRequestViewModel
    {
        /// <summary>
        /// dispatchlist ids
        /// </summary>
        [Display(Name = "dispatchlist_id_list")]
        public List<int> dispatchlist_id_list { get; set; } = new List<int>();
    }
}
