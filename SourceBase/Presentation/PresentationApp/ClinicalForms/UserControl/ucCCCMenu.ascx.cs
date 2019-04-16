using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Interface.Clinical;
using Application.Presentation;
using System.Data;
using Application.Common;

namespace PresentationApp.ClinicalForms.UserControl
{
    public partial class ucCCCMenu : System.Web.UI.UserControl
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        private void OpenForm(string FormName)
        {
            int FeatureId = 0;
            IPatientHome PatientManager;
            PatientManager = (IPatientHome)ObjectFactory.CreateInstance("BusinessProcess.Clinical.BPatientHome, BusinessProcess.Clinical");
            DataTable dt = PatientManager.GetCustomFormId(FormName);

            if (dt.Rows.Count > 0)
            {
                FeatureId = Convert.ToInt32(dt.Rows[0]["FeatureID"]);
            }

            if (FeatureId > 0)
            {
                HttpContext.Current.Session["PatientVisitId"] = 0;
                HttpContext.Current.Session["ServiceLocationId"] = 0;
                HttpContext.Current.Session["FeatureID"] = FeatureId;
                HttpContext.Current.Session["LabOrderID"] = null;
                Response.Redirect("frmClinical_CustomForm.aspx");
            }
            else
            {
                MsgBuilder theBuilder = new MsgBuilder();
                theBuilder.DataElements["MessageText"] = FormName + " form not found";
                IQCareMsgBox.Show("#C1", theBuilder, this);
            }
        }

        protected void lnkNutrition_Click(object sender, EventArgs e)
        {
            OpenForm("Nutrition");
        }

        protected void lnkAdvancedCare_Click(object sender, EventArgs e)
        {
            OpenForm("Nutrition");
        }

        protected void lnkPyschiatric_Click(object sender, EventArgs e)
        {
            OpenForm("Nutrition");
        }

        protected void lnkPhysiotheraphy_Click(object sender, EventArgs e)
        {
            OpenForm("Nutrition");
        }

        protected void LinkButton1_Click(object sender, EventArgs e)
        {
            OpenForm("Nutrition");
        }

        protected void LinkButton2_Click(object sender, EventArgs e)
        {
            OpenForm("Nutrition");
        }
    }
}