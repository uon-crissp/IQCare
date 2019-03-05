using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace PresentationApp.PharmacyDispense
{
    public partial class frmPharmacy_Configuration : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            (Master.FindControl("levelTwoNavigationUserControl1").FindControl("patientLevelMenu") as Menu).Visible = false;
            (Master.FindControl("levelTwoNavigationUserControl1").FindControl("PharmacyDispensingMenu") as Menu).Visible = true;
        }
    }
}