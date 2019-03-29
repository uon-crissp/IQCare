using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data;

namespace PresentationApp.HIVCE
{
    public partial class MoriskyAdherence : System.Web.UI.Page
    {
        int PatientId;
        int locationId;
        int userId;

        protected void Page_Load(object sender, EventArgs e)
        {

            if (!object.Equals(Session["PatientId"], null))
            {
                PatientId = Convert.ToInt32(Session["PatientId"]);
            }
            if (!object.Equals(Session["AppLocationId"], null))
            {
                locationId = Convert.ToInt32(Session["AppLocationId"]);
            }
            if (!object.Equals(Session["AppUserId"], null))
            {
                userId = Convert.ToInt32(Session["AppUserId"]);
            }


        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            DataTable dt = new DataTable();

            dt.Columns.Add(new DataColumn("Ptn_pk", typeof(string)));
            dt.Columns.Add(new DataColumn("Visit_Pk", typeof(string)));
            dt.Columns.Add(new DataColumn("visitdate", typeof(string)));
            dt.Columns.Add(new DataColumn("LocationId", typeof(string)));
            dt.Columns.Add(new DataColumn("UserID", typeof(string)));
            dt.Columns.Add(new DataColumn("ForgetMedicineSinceLastVisit", typeof(string)));
            dt.Columns.Add(new DataColumn("CarelessAboutTakingMedicine", typeof(string)));
            dt.Columns.Add(new DataColumn("FeelWorseStopTakingMedicine", typeof(string)));
            dt.Columns.Add(new DataColumn("FeelBetterStopTakingMedicine", typeof(string)));
            dt.Columns.Add(new DataColumn("TakeMedicineYesterday", typeof(string)));
            dt.Columns.Add(new DataColumn("SymptomsUnderControl_StopTakingMedicine", typeof(string)));
            dt.Columns.Add(new DataColumn("UnderPresureStickingYourTreatmentPlan", typeof(string)));
            dt.Columns.Add(new DataColumn("RememberingMedications", typeof(string)));
            dt.Columns.Add(new DataColumn("MMAS4_Score", typeof(string)));
            dt.Columns.Add(new DataColumn("MMAS8_Score", typeof(string)));
            dt.Columns.Add(new DataColumn("MMAS4_AdherenceRating", typeof(string)));
            dt.Columns.Add(new DataColumn("MMAS8_AdherenceRating", typeof(string)));
            dt.Columns.Add(new DataColumn("ReferToCounselor", typeof(string)));
            dt.Columns.Add(new DataColumn("signature", typeof(string)));
            dt.Columns.Add(new DataColumn("VisitTypeId", typeof(string)));

            DataRow dr = dt.NewRow();
            dr["Ptn_pk"] = PatientId;
            dr["Visit_Pk"] = 0;
            dr["visitdate"] = DateTime.Now.ToString("dd-MMM-yyyy");
            dr["LocationId"] = locationId;
            dr["UserID"] = userId;
            dr["ForgetMedicineSinceLastVisit"] = chkForgotMed.Value;
            dr["CarelessAboutTakingMedicine"] = chkCarelessMed.Value;
            dr["FeelWorseStopTakingMedicine"] = chkWorseTakingMed.Value;
            dr["FeelBetterStopTakingMedicine"] = chkFeelBetterMed.Value;
            dr["TakeMedicineYesterday"] = chkYesterdayMed.Value;
            dr["SymptomsUnderControl_StopTakingMedicine"] = chkSymptomUnderControl.Value;
            dr["UnderPresureStickingYourTreatmentPlan"] = chkStickingTreatmentPlan.Value;
            dr["RememberingMedications"] = "";
            dr["MMAS4_Score"] = txtMMAS4Score.Value;
            dr["MMAS8_Score"] = txtMMAS8Score.Value;
            dr["MMAS4_AdherenceRating"] = txtMMAS4Rating.Value;
            dr["MMAS8_AdherenceRating"] = txtMMAS8Rating.Value;
            dr["ReferToCounselor"] = 0;
            dr["signature"] = userId;
            dr["VisitTypeId"] = 0;
        }
    }
}