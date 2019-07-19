using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Interface.Clinical;
using Application.Presentation;
using System.Data;
using Application.Common;

namespace IQCare.Web
{
    public partial class frmFindAddCustom : LogPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["AppLocation"] == null || Session.Count == 0 || Session["AppUserID"].ToString() == "")
            {
                IQCareMsgBox.Show("SessionExpired", this);
                Response.Redirect("~/frmlogin.aspx", true);
            }
            if (IsPostBack) return;

            try
            {
                HtmlGenericControl lblServiceArea = (HtmlGenericControl)FindPatient.FindControl("lblServiceArea");
                lblServiceArea.InnerText = Request.QueryString["srvNm"];

                if (Convert.ToInt32(Session["Paperless"]) != 1)//waiting list is available only in paperless mode
                {
                    btnWaitingList.Visible = false;
                }

                Session["HIVPatientStatus"] = 0;
                Session["PMTCTPatientStatus"] = 0;
                //SetEnrollmentCombo();
                Session["PatientId"] = 0;
                Session["TechnicalAreaName"] = Request.QueryString["srvNm"];
                Session["TechnicalAreaId"] = Request.QueryString["mod"];
                string urlParam = String.Format("openWaitingList('./frmWaitingList.aspx?mod={0}');return false;", Session["TechnicalAreaId"]);

                btnWaitingList.OnClientClick = urlParam;
                if (Request.QueryString["srvNm"] == "Pharmacy Dispense" || Request.QueryString["srvNm"] == "Laboratory") //&& Request.QueryString["mod"] == "206"
                {
                    ((Button)FindPatient.FindControl("btnAdd")).Enabled = false;
                    (FindPatient.FindControl("ddCareEndedStatus") as DropDownList).Visible = false;
                    (FindPatient.FindControl("lblCareendedstatus") as HtmlGenericControl).Visible = false;
                    (Master.FindControl("levelTwoNavigationUserControl1").FindControl("UserControl_Alerts1") as UserControl).Visible = false;
                    (Master.FindControl("levelTwoNavigationUserControl1").FindControl("PanelPatiInfo") as Panel).Visible = false;
                    //(Master.FindControl("patientBanner") as Control).Visible = false;
                    (Master.FindControl("level2Navigation") as Control).Visible = false;
                    //(Master.FindControl("imageFlipLevel2") as Control).Visible = false;
                }
            }
            catch (Exception ex)
            {

                CLogger.WriteLog(ELogLevel.ERROR, ex.ToString());
                if (Session["PatientId"] == null || Convert.ToInt32(Session["PatientId"]) != 0)
                {
                    IQCareMsgBox.NotifyAction("Application has an issue, Please contact Administrator!", "Application Error", true, this, "window.location.href='../frmFindAddCustom.aspx?srvNm=" + Session["TechnicalAreaName"] + "&mod=" + Session["TechnicalAreaId"] + "'");
                }
                else
                {
                    if (Session["TechnicalAreaId"] != null || Convert.ToInt16(Session["TechnicalAreaId"]) != 0)
                    {
                        IQCareMsgBox.NotifyAction("Application has an issue, Please contact Administrator!", "Application Error", true, this, "window.location.href='../frmFacilityHome.aspx';");
                        //Response.Write("<script>alert('Application has an issue, Please contact Administrator!') ; window.location.href='../frmFacilityHome.aspx'</script>");

                    }
                    else
                    {

                        IQCareMsgBox.NotifyAction("Application has an issue, Please contact Administrator!", "Application Error", true, this, "window.location.href='../frmLogin.aspx';");
                        //Response.Write("<script>alert('Application has an issue, Please contact Administrator!') ; window.location.href='../frmLogin.aspx'</script>");
                    }
                }
                ex = null;
            }
        }


        protected override void OnInit(EventArgs e)
        {
            try
            {
                base.OnInit(e);
                if (Request.QueryString["mod"] == "0")
                {
                    FindPatient.IncludeEnrollement = true;
                }
                else
                {
                    FindPatient.IncludeEnrollement = false;
                    if (Request.QueryString["mod"] != "")
                    {
                        FindPatient.SelectedServiceLine = int.Parse(Request.QueryString["mod"]);
                    }
                }
                FindPatient.SelectedPatientChanged += new CommandEventHandler(FindPatient_SelectedPatientChanged);
            }
            catch (Exception ex)
            {

                CLogger.WriteLog(ELogLevel.ERROR, ex.ToString());
                if (Session["PatientId"] == null || Convert.ToInt32(Session["PatientId"]) != 0)
                {
                    IQCareMsgBox.NotifyAction("Application has an issue, Please contact Administrator!", "Application Error", true, this, "window.location.href='../frmFindAddCustom.aspx?srvNm=" + Session["TechnicalAreaName"] + "&mod=" + Session["TechnicalAreaId"].ToString() + "'");
                    //Response.Write("<script>alert('Application has an issue, Please contact Administrator!') ; window.location.href='../frmFindAddCustom.aspx?srvNm=" + Session["TechnicalAreaName"] + "&mod=0'</script>");
                }
                else
                {
                    if (Session["TechnicalAreaId"] != null || Convert.ToInt16(Session["TechnicalAreaId"]) != 0)
                    {
                        IQCareMsgBox.NotifyAction("Application has an issue, Please contact Administrator!", "Application Error", true, this, "window.location.href='../frmFacilityHome.aspx';");
                        //Response.Write("<script>alert('Application has an issue, Please contact Administrator!') ; window.location.href='../frmFacilityHome.aspx'</script>");

                    }
                    else
                    {

                        IQCareMsgBox.NotifyAction("Application has an issue, Please contact Administrator!", "Application Error", true, this, "window.location.href='../frmLogin.aspx';");
                        //Response.Write("<script>alert('Application has an issue, Please contact Administrator!') ; window.location.href='../frmLogin.aspx'</script>");
                    }
                }
                ex = null;
            }


        }
        void FindPatient_SelectedPatientChanged(object sender, CommandEventArgs e)
        {
            int LocationID, PatientID, ModuleId;
            string sPatientService;

            string sActiveService = Session["TechnicalAreaName"].ToString();
            int iCurrentModule = Convert.ToInt16(Session["TechnicalAreaId"]);

            List<KeyValuePair<string, string>> param = e.CommandArgument as List<KeyValuePair<string, string>>;
            PatientID = Convert.ToInt32(param.Find(l => l.Key == "PatientID").Value);
            LocationID = Convert.ToInt32(param.Find(l => l.Key == "LocationID").Value);
            ModuleId = Convert.ToInt32(param.Find(l => l.Key == "ModuleID").Value);
            sPatientService = param.Find(l => l.Key == "ModuleName").Value;

            if (iCurrentModule == ModuleId || sActiveService.ToLower().Contains("pharmacy") || sActiveService.ToLower().Contains("laboratory"))
            {
                openPatientDetails(PatientID);
            }
            else if (ModuleId == 0)
            {
                openPatientDetails(PatientID);
            }
            else
            {
                IQCareMsgBox.NotifyAction("This Patient is currently in \'" + sPatientService + "\' service area. If you you wish to serve them in \'" + sActiveService + "\', open the patient record in \'" + sPatientService + "\' then transfer to this service area.", "Different Service Area", false, this, "");
            }
        }

        private void openPatientDetails(int patientID)
        {

            HttpContext.Current.Session["PatientId"] = patientID;
            HttpContext.Current.Session["PatientVisitId"] = 0;
            HttpContext.Current.Session["ServiceLocationId"] = 0;
            HttpContext.Current.Session["LabId"] = 0;
            HttpContext.Current.Session["CareEndFlag"] = "0";
            /* Session["TechnicalAreaName"] = null;
             Session["TechnicalAreaId"] = 0;*/


            #region "Refresh Patient Records"
            IPatientHome PManager = (IPatientHome)ObjectFactory.CreateInstance("BusinessProcess.Clinical.BPatientHome, BusinessProcess.Clinical");
            System.Data.DataSet thePDS = PManager.GetPatientDetails(Convert.ToInt32(HttpContext.Current.Session["PatientId"]), Convert.ToInt32(HttpContext.Current.Session["SystemId"]), Convert.ToInt32(HttpContext.Current.Session["TechnicalAreaId"]));


            HttpContext.Current.Session["PatientInformation"] = thePDS.Tables[0];
            if (thePDS.Tables[40].Rows.Count > 0)
            {
                HttpContext.Current.Session["CareEndFlag"] = thePDS.Tables[40].Rows[0]["CareEnded"].ToString();
            }            
            #endregion
            string theUrl = "";
            if (Request.QueryString["srvNm"] == "Records")
            {
                Session["TechnicalAreaName"] = "Records";
                theUrl = string.Format("{0}", "./frmAddTechnicalArea.aspx");
                Response.Redirect(theUrl);
            }
            else
            {
                //Check if the patient is enrolled and go directly to patient home page if patient is enrolled
                IPatientRegistration PatRegMgr = (IPatientRegistration)ObjectFactory.CreateInstance("BusinessProcess.Clinical.BPatientRegistration, BusinessProcess.Clinical");
                DataSet theDS = PatRegMgr.GetFieldNames(int.Parse(Request.QueryString["mod"]), Convert.ToInt32(Session["PatientId"]));

                if (Session["TechnicalAreaId"].ToString() == "206")
                {
                    Session["PatientVisitID"] = 0;
                    theUrl = "./PharmacyDispense/frmPharmacyDispense_PatientOrder.aspx";
                }
                else if (Session["TechnicalAreaId"].ToString() == "300")
                {
                    theUrl = "./Laboratory/frm_LabTestResults.aspx";
                }
                else if (theDS.Tables[3].Rows.Count > 0)//check if patient is care ended, redirect to homepage
                {
                    theUrl = "./ClinicalForms/frmPatient_Home.aspx";
                }
                else if (theDS.Tables[2].Rows.Count > 0 && theDS.Tables[2].Rows[0]["StartDate"].ToString() != "")
                {
                    theUrl = "./ClinicalForms/frmPatient_Home.aspx";
                }
                else
                {
                    theUrl = string.Format("{0}?mod={1}", "./frmAddTechnicalArea.aspx", Request.QueryString["mod"]);
                }

                Response.Redirect(theUrl, false);
            }
        }

    }
}
