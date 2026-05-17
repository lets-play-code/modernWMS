using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ModernWMS.WMS.Entities.ViewModels
{
    /// <summary>
    /// request for operating pick details
    /// </summary>
    public class DispatchpicklistOperateViewModel
    {
        /// <summary>
        /// pick row ids
        /// </summary>
        [Display(Name = "picklist_id_list")]
        public List<int> picklist_id_list { get; set; } = new List<int>();
    }
}
