using System.Collections.Generic;

namespace ModernWMS.WMS.Entities.ViewModels
{
    /// <summary>
    /// runtime picking-sheet viewModel
    /// </summary>
    public class DispatchlistPickingSheetViewModel
    {
        /// <summary>
        /// dispatch numbers in the runtime picking sheet
        /// </summary>
        public List<string> dispatch_nos { get; set; } = new List<string>();

        /// <summary>
        /// aggregated picking lines
        /// </summary>
        public List<DispatchlistPickingSheetLineViewModel> lines { get; set; } = new List<DispatchlistPickingSheetLineViewModel>();
    }
}
