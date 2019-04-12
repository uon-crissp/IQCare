using System;
using System.Data;
using System.IO;
using System.Configuration;
using System.Collections;
using System.Web;
using System.Text;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;
using Microsoft.VisualBasic;
using Interface.Clinical;
using Interface.Security;
using Application.Common;
using Application.Presentation;
using Interface.Administration;
using Interface.Service;

public partial class frmPatientCustomRegistration : LogPage
{
    DataSet theDSXML = new DataSet();
    string ObjFactoryParameter = "BusinessProcess.Clinical.BPatientRegistration, BusinessProcess.Clinical";
    string ObjFactoryParameterBCustom = "BusinessProcess.Clinical.BCustomForm, BusinessProcess.Clinical";
    int FeatureID = 126, PatientID = 0, VisitID = 0, LocationID = 0;
    Boolean theConditional;
    Hashtable htParameters;
    Boolean rdoTrueFalseStatus = true;

    protected void Page_PreRender(object sender, EventArgs e)
    {
        if (Session["AppLocation"] == null || Session.Count == 0 || Session["AppUserID"].ToString() == "")
        {
            IQCareMsgBox.Show("SessionExpired", this);
            Response.Redirect("~/frmlogin.aspx", true);
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {

        if (Session["AppLocation"] == null || Session.Count == 0 || Session["AppUserID"].ToString() == "")
        {
            IQCareMsgBox.Show("SessionExpired", this);
            Response.Redirect("~/frmlogin.aspx", true);
        }

        (Master.FindControl("levelTwoNavigationUserControl1").FindControl("PanelPatiInfo") as Panel).Visible = false;
        Ajax.Utility.RegisterTypeForAjax(typeof(frmPatientCustomRegistration));
        ddProvince.SelectedIndexChanged += new EventHandler(SelectedProvinceItemTypeChanged);
        Attributes();
        theDSXML.ReadXml(MapPath(".\\XMLFiles\\AllMasters.con"));
        if (!IsPostBack)
        {
            Binddropdown();
        }
        PatientID = Convert.ToInt32(Session["PatientId"]);
        LocationID = Convert.ToInt32(Session["AppLocationId"]);
        VisitID = Convert.ToInt32(ViewState["VisitPk"]);

        if (PatientID > 0)
        {
            if (!IsPostBack)
            {
                LoadPatientStaticData(PatientID);
            }
        }
    }

    [Ajax.AjaxMethod(Ajax.HttpSessionStateRequirement.ReadWrite)]
    public string GetDuplicateRecord(string strfname, string strmname, string strlname, string address, string Phone)
    {
        IPatientRegistration PatientManager;
        StringBuilder objBilder = new StringBuilder();
        PatientManager = (IPatientRegistration)ObjectFactory.CreateInstance(ObjFactoryParameter);
        DataSet dsPatient = new DataSet();
        dsPatient = PatientManager.GetDuplicatePatientSearchResults(strlname, strmname, strfname, address, Phone);

        if (dsPatient.Tables[0].Rows.Count > 0)
        {
            objBilder.Append("<table border='0'  width='100%'>");
            objBilder.Append("<tr style='background-color:#e1e1e1'>");
            //objBilder.Append("<td class='smallerlabel'>PatientID</td>");
            objBilder.Append("<td class='smallerlabel'>IQ Number</td>");
            objBilder.Append("<td class='smallerlabel'>F name</td>");
            objBilder.Append("<td class='smallerlabel'>L name</td>");
            objBilder.Append("<td class='smallerlabel'>Registration Date</td>");
            objBilder.Append("<td class='smallerlabel'>Dob</td>");
            objBilder.Append("<td class='smallerlabel'>Sex</td>");
            objBilder.Append("<td class='smallerlabel'>Phone</td>");
            objBilder.Append("<td class='smallerlabel'>Facility</td>");
            objBilder.Append("</tr>");
            for (int i = 0; i < dsPatient.Tables[0].Rows.Count; i++)
            {
                objBilder.Append("<tr>");
                //objBilder.Append("<td class='smallerlabel'>" + dsPatient.Tables[0].Rows[i]["PatientRegistrationID"].ToString() + "</td>");
                objBilder.Append("<td class='smallerlabel'>" + dsPatient.Tables[0].Rows[i]["IQNumber"].ToString() + "</td>");
                objBilder.Append("<td class='smallerlabel'>" + dsPatient.Tables[0].Rows[i]["firstname"].ToString() + "</td>");
                objBilder.Append("<td class='smallerlabel'>" + dsPatient.Tables[0].Rows[i]["lastname"].ToString() + "</td>");
                objBilder.Append("<td class='smallerlabel'>" + dsPatient.Tables[0].Rows[i]["RegistrationDate"].ToString() + "</td>");
                objBilder.Append("<td class='smallerlabel'>" + dsPatient.Tables[0].Rows[i]["dobPatient"].ToString() + "</td>");
                objBilder.Append("<td class='smallerlabel'>" + dsPatient.Tables[0].Rows[i]["sex"].ToString() + "</td>");
                objBilder.Append("<td class='smallerlabel'>" + dsPatient.Tables[0].Rows[i]["Phone"].ToString() + "</td>");
                objBilder.Append("<td class='smallerlabel'>" + dsPatient.Tables[0].Rows[i]["FacilityName"].ToString() + "</td>");
                objBilder.Append("</tr>");
            }
            objBilder.Append("</table>");
        }
        return objBilder.ToString();
    }

    private void Attributes()
    {

        IIQCareSystem SystemManager = (IIQCareSystem)ObjectFactory.CreateInstance("BusinessProcess.Security.BIQCareSystem, BusinessProcess.Security");
        DateTime theCurrentDate = SystemManager.SystemDate();
        SystemManager = null;
        txtSysDate.Text = theCurrentDate.ToString(Session["AppDateFormat"].ToString());
        txtlastName.Attributes.Add("onkeyup", "chkString('" + txtlastName.ClientID + "')");
        txtfirstName.Attributes.Add("onkeyup", "chkString('" + txtfirstName.ClientID + "')");
        TxtDOB.Attributes.Add("onkeyup", "DateFormat(this,this.value,event,false,'3');");
        TxtDOB.Attributes.Add("onblur", "ValidateAge(); DateFormat(this,this.value,event,true,'3'); CalcualteAge('" + txtageCurrentYears.ClientID + "','" + txtageCurrentMonths.ClientID + "','" + TxtDOB.ClientID + "','" + txtSysDate.ClientID + "'); isCheckValidDate('" + Application["AppCurrentDate"] + "', '" + TxtDOB.ClientID + "', '" + TxtDOB.ClientID + "');");
        //Add by Rahmat as on 07-Feb-2018 for calculate year and month and fill text box from first time on words..
        TxtDOB.Attributes.Add("onChange", "CalcualteAge('" + txtageCurrentYears.ClientID + "','" + txtageCurrentMonths.ClientID + "','" + TxtDOB.ClientID + "','" + txtSysDate.ClientID + "');");

        txtRegDate.Attributes.Add("onkeyup", "DateFormat(this,this.value,event,false,'3')");
        txtRegDate.Attributes.Add("onblur", "DateFormat(this,this.value,event,true,'3'); isCheckValidDate('" + Application["AppCurrentDate"] + "', '" + txtRegDate.ClientID + "', '" + txtRegDate.ClientID + "');");

        txtageCurrentYears.Attributes.Add("onkeyup", "chkNumeric('" + txtageCurrentYears.ClientID + "')");
        txtageCurrentMonths.Attributes.Add("onkeyup", "chkNumeric('" + txtageCurrentMonths.ClientID + "')");
        txtphone.Attributes.Add("onkeyup", "chkNumeric('" + txtphone.ClientID + "')");
        txtemergContactPhone.Attributes.Add("onkeyup", "chkNumeric('" + txtemergContactPhone.ClientID + "')");
        txtageCurrentMonths.Attributes.Add("onkeyup", "chkNumeric('" + txtageCurrentMonths.ClientID + "')");
        txtageCurrentYears.Attributes.Add("onkeyup", "chkNumeric('" + txtageCurrentYears.ClientID + "')");

    }

    private void HashTableParameter()
    {
        try
        {
            htParameters = new Hashtable();
            htParameters.Clear();
            htParameters.Add("FirstName", txtfirstName.Text.Trim());
            htParameters.Add("MiddleName", txtmiddleName.Text.Trim());
            htParameters.Add("LastName", txtlastName.Text.Trim());
            htParameters.Add("Gender", ddgender.SelectedValue);
            htParameters.Add("DOB", TxtDOB.Text);
            htParameters.Add("RegistrationDate", txtRegDate.Value);
        }
        catch (Exception err)
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["MessageText"] = err.Message.ToString();
            IQCareMsgBox.Show("#C1", theBuilder, this);
            return;
        }
        finally
        {

        }
    }

    private void ApplyBusinessRules(object theControl, string ControlID, bool theConField)
    {
        try
        {
            DataTable theDT = (DataTable)ViewState["BusRule"];
            string Max = "", Min = "", Column = "";
            bool theEnable = theConField;
            string[] Field;
            if (ControlID == "9")
            {
                Field = ((Control)theControl).ID.Split('_');
            }
            else
            {
                Field = ((Control)theControl).ID.Split('-');
            }
            foreach (DataRow DR in theDT.Rows)
            {
                if (Field[0] == "Pnl")
                {

                    if (Field[1] == Convert.ToString(DR["FieldId"]) && Convert.ToString(DR["BusRuleId"]) == "14"
                        && Session["PatientSex"].ToString() != "Male")
                        theEnable = false;

                    if (Field[1] == Convert.ToString(DR["FieldId"]) && Convert.ToString(DR["BusRuleId"]) == "15"
                        && Session["PatientSex"].ToString() != "Female")
                        theEnable = false;

                    if (Field[1] == Convert.ToString(DR["FieldId"]) && Convert.ToString(DR["BusRuleId"]) == "16")
                    {
                        if ((DR["Value"] != System.DBNull.Value) && (DR["Value1"] != System.DBNull.Value))
                        {
                            if (Convert.ToDecimal(Session["PatientAge"]) >= Convert.ToDecimal(DR["Value"]) && Convert.ToDecimal(Session["PatientAge"]) <= Convert.ToDecimal(DR["Value1"]))
                            {
                            }
                            else
                                theEnable = false;
                        }
                    }

                }
                else
                {
                    if (Field[1] == Convert.ToString(DR["FieldName"]) && Field[2].ToLower() == Convert.ToString(DR["TableName"]).ToLower() && Field[3] == Convert.ToString(DR["FieldId"]) && Convert.ToString(DR["BusRuleId"]) == "2")
                    {
                        Max = Convert.ToString(DR["Value"]);
                        Column = Convert.ToString(DR["FieldLabel"]);
                    }
                    if (Field[1] == Convert.ToString(DR["FieldName"]) && Field[2].ToLower() == Convert.ToString(DR["TableName"]).ToLower() && Field[3] == Convert.ToString(DR["FieldId"]) && Convert.ToString(DR["BusRuleId"]) == "3")
                    {
                        Min = Convert.ToString(DR["Value"]);

                    }
                    if (Field[1] == Convert.ToString(DR["FieldName"]) && Field[2].ToLower() == Convert.ToString(DR["TableName"]).ToLower() && Field[3] == Convert.ToString(DR["FieldId"]) && Convert.ToString(DR["BusRuleId"]) == "16")
                    {
                        if ((DR["Value"] != System.DBNull.Value) && (DR["Value1"] != System.DBNull.Value))
                        {
                            if (Convert.ToDecimal(Session["PatientAge"]) >= Convert.ToDecimal(DR["Value"]) && Convert.ToDecimal(Session["PatientAge"]) <= Convert.ToDecimal(DR["Value1"]))
                            {
                            }
                            else
                                theEnable = false;
                        }
                    }
                }
            }

            if (theControl.GetType().ToString() == "System.Web.UI.WebControls.TextBox")
            {
                Field = ((Control)theControl).ID.Split('-');
                TextBox tbox = (TextBox)theControl;
                tbox.Enabled = theEnable;
                if (ControlID == "1")
                { }
                else if (ControlID == "2" && Field[0] == "TXT")
                {
                    tbox.Attributes.Add("onkeyup", "chkDecimal('" + tbox.ClientID + "')");
                }
                else if (ControlID == "3" && Field[0] == "TXTNUM")
                {
                    tbox.Attributes.Add("onkeyup", "chkNumeric('" + tbox.ClientID + "')");
                }
                else if (ControlID == "5" && Field[0] == "TXTDT")
                {
                    tbox.Attributes.Add("onkeyup", "DateFormat(this,this.value,event,false,'3')");
                    tbox.Attributes.Add("onblur", "DateFormat(this,this.value,event,true,'3')");
                }
                if (Max != "" && Min != "")
                {
                    tbox.Attributes.Add("onblur", "isBetween('" + tbox.ClientID + "', '" + Column + "', '" + Min + "', '" + Max + "')");
                }
                else if (Max != "")
                {
                    tbox.Attributes.Add("onblur", "checkMax('" + tbox.ClientID + "', '" + Column + "', '" + Max + "')");
                }
                else if (Min != "")
                {
                    tbox.Attributes.Add("onblur", "checkMin('" + tbox.ClientID + "', '" + Column + "', '" + Min + "')");
                }

            }
            else if (theControl.GetType().ToString() == "System.Web.UI.WebControls.DropDownList")
            {
                DropDownList ddList = (DropDownList)theControl;
                ddList.Enabled = theEnable;

            }
            else if (theControl.GetType().ToString() == "System.Web.UI.WebControls.CheckBox")
            {
                CheckBox Multichk = (CheckBox)theControl;
                Multichk.Enabled = theEnable;
            }
            else if (theControl.GetType().ToString() == "System.Web.UI.HtmlControls.HtmlInputRadioButton")
            {
                HtmlInputRadioButton Rdobtn = (HtmlInputRadioButton)theControl;
                Rdobtn.Visible = theEnable;
                rdoTrueFalseStatus = true;
                if (theEnable == false)
                {
                    rdoTrueFalseStatus = false;
                }
            }
            else if (theControl.GetType().ToString() == "System.Web.UI.WebControls.Image")
            {
                Image img = (Image)theControl;
                img.Visible = theEnable;
            }
            else if (theControl.GetType().ToString() == "System.Web.UI.WebControls.Panel")
            {
                Panel pnl = (Panel)theControl;
                pnl.Enabled = theEnable;
            }
        }
        catch (Exception err)
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["MessageText"] = err.Message.ToString();
            IQCareMsgBox.Show("#C1", theBuilder, this);
        }
    }

    private void LoadPatientStaticData(int Ptn_Pk)
    {
        String moduleID;
        if (Session["CEModule"] != null)
            moduleID = Session["CEModule"].ToString();
        IQCareUtils theUtil = new IQCareUtils();
        try
        {
            IPatientRegistration PatientManager = (IPatientRegistration)ObjectFactory.CreateInstance(ObjFactoryParameter);
            DataSet theDS = PatientManager.GetPatientRegistration(Ptn_Pk, 12);
            ViewState["themstpatient"] = theDS.Tables[0];
            ViewState["VisitPk"] = theDS.Tables[4].Rows[0]["VisitId"].ToString();
            this.txtIQCareRef.Text = theDS.Tables[0].Rows[0]["IQNumber"].ToString();
            ViewState["IQNumber"] = txtIQCareRef.Text;
            this.ddgender.SelectedValue = theDS.Tables[0].Rows[0]["RegSex"].ToString();

            this.txtRegDate.Value = String.Format("{0:dd-MMM-yyyy}", Convert.ToDateTime(theDS.Tables[0].Rows[0]["RegDate"]));
            this.txtageCurrentYears.Text = theDS.Tables[0].Rows[0]["Age"].ToString();
            this.txtageCurrentMonths.Text = theDS.Tables[0].Rows[0]["Age1"].ToString();
            this.txtlastName.Text = theDS.Tables[0].Rows[0]["LastName"].ToString();
            this.txtmiddleName.Text = theDS.Tables[0].Rows[0]["MiddleName"].ToString();
            this.txtfirstName.Text = theDS.Tables[0].Rows[0]["FirstName"].ToString();
            this.TxtDOB.Text = ((DateTime)theDS.Tables[0].Rows[0]["RegDOB"]).ToString(Session["AppDateFormat"].ToString());
            if (Convert.ToInt32(theDS.Tables[0].Rows[0]["DobPrecision"]) == 1)
            {
                this.rbtndobPrecEstimated.Checked = true;
            }
            else if (Convert.ToInt32(theDS.Tables[0].Rows[0]["DobPrecision"]) == 0)
            {
                this.rbtndobPrecExact.Checked = true;
            }
            this.ddmaritalStatus.SelectedValue = theDS.Tables[0].Rows[0]["MaritalStatus"].ToString();
            this.ddvillageName.SelectedValue = theDS.Tables[0].Rows[0]["VillageName"].ToString();
            this.dddistrictName.SelectedValue = theDS.Tables[0].Rows[0]["DistrictName"].ToString();
            this.ddProvince.SelectedValue = theDS.Tables[0].Rows[0]["Province"].ToString();
            this.ddCountry.SelectedValue = theDS.Tables[0].Rows[0]["CountryID"].ToString();
            //this.ddCountry.Enabled = false;
            this.txtlocalCouncil.Text = theDS.Tables[0].Rows[0]["LocalCouncil"].ToString();
            this.txtaddress.Text = theDS.Tables[0].Rows[0]["Address"].ToString();
            this.txtphone.Text = theDS.Tables[0].Rows[0]["Phone"].ToString();
            this.txtemergContactName.Text = theDS.Tables[1].Rows[0]["EmergContactName"].ToString();
            this.txtemergContactPhone.Text = theDS.Tables[1].Rows[0]["EmergContactPhone"].ToString();
            this.txtemergContactAddress.Text = theDS.Tables[1].Rows[0]["EmergContactAddress"].ToString();
            this.ddEmergContactRelation.SelectedValue = theDS.Tables[1].Rows[0]["EmergContactRelation"].ToString();

            this.txtNOKName.Text = theDS.Tables[1].Rows[0]["NextofKinName"].ToString();
            this.txtNOKPhone.Text = theDS.Tables[1].Rows[0]["NextofKinTelNo"].ToString();
            this.txtNOKAddress.Text = theDS.Tables[1].Rows[0]["NextofAddress"].ToString();
            this.ddlNOKRelationship.Text = theDS.Tables[1].Rows[0]["NextofKinRelationship"].ToString();
        }
        catch (Exception err)
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["MessageText"] = err.Message.ToString();
            IQCareMsgBox.Show("#C1", theBuilder, this);
            return;
        }
        finally
        {

        }
    }

    private StringBuilder UpdateCustomRegistrationData(int PatientID, int VisitID, int LocationID)
    {
        DataTable LnkDTUnique = new DataTable();
        StringBuilder sbUpdate = new StringBuilder();
        DataTable theDTNoMulti = new DataTable();
        DataTable theDTMulti = new DataTable();
        DataTable theDTConMulti = new DataTable();
        ICustomForm MgrSaveUpdate = (ICustomForm)ObjectFactory.CreateInstance(ObjFactoryParameterBCustom);

        if (ViewState["NoMulti"] != null)
        {
            theDTNoMulti = ((DataTable)ViewState["NoMulti"]);
            theDTMulti = ((DataTable)ViewState["LnkTable"]);
            theDTConMulti = ((DataTable)ViewState["LnkConTable"]);
            theDTNoMulti = theDTNoMulti.Select("IsNull(FieldName,'') <> ''").CopyToDataTable();
            LnkDTUnique = theDTNoMulti.DefaultView.ToTable(true, "PDFTableName", "FeatureName");

        }
        int DOBPrecision = 0;
        if (rbtndobPrecEstimated.Checked == true)
        {
            DOBPrecision = 1;
        }
        else if (rbtndobPrecExact.Checked == true)
        {
            DOBPrecision = 0;
        }
        else
        {
            DOBPrecision = 2;
        }
        /////////////////////////////////////////////////
        StringBuilder SbmstpatColumns = new StringBuilder();
        StringBuilder SbmstpatValues = new StringBuilder();
        SbmstpatColumns.Append("Update [MST_PATIENT]Set ");
        SbmstpatColumns.Append("FirstName=encryptbykey(key_guid('Key_CTC'),'" + txtfirstName.Text + "'), MiddleName=encryptbykey(key_guid('Key_CTC'),'" + txtmiddleName.Text + "'),");
        SbmstpatColumns.Append("LastName=encryptbykey(key_guid('Key_CTC'),'" + txtlastName.Text + "'), LocationID='" + Session["AppLocationId"] + "', RegistrationDate='" + txtRegDate.Value + "',[ID/PassportNo]='0',");
        SbmstpatColumns.Append("Sex='" + ddgender.SelectedValue + "',DOB='" + TxtDOB.Text + "',DobPrecision='" + DOBPrecision + "',MaritalStatus='" + ddmaritalStatus.SelectedValue + "',VillageName='" + ddvillageName.SelectedValue + "',DistrictName='" + dddistrictName.SelectedValue + "',Province='" + ddProvince.SelectedValue + "',");
        SbmstpatColumns.Append("LocalCouncil='" + txtlocalCouncil.Text + "',Address=encryptbykey(key_guid('Key_CTC'),'" + txtaddress.Text + "'),Phone=encryptbykey(key_guid('Key_CTC'),'" + txtphone.Text + "'),");
        SbmstpatColumns.Append("CountryId='" + Session["AppCountryId"] + "', PosId='" + Session["AppPosID"] + "', SatelliteId='" + Session["AppSatelliteId"] + "', ");


        StringBuilder SbContColumns = new StringBuilder();
        StringBuilder SbContValues = new StringBuilder();
        SbContColumns.Append(" Delete  from [DTL_PATIENTCONTACTS] where Ptn_Pk=" + PatientID + " and Visitid=" + VisitID + " and LocationID=" + LocationID + " ");
        //SbContColumns.Append(" Insert into [DTL_PATIENTCONTACTS](Ptn_pk,Visitid,LocationId,UserID,CreateDate,EmergContactName,EmergContactRelation,EmergContactPhone,EmergContactAddress,");
        //SbContValues.Append("Values(" + PatientID + "," + VisitID + ", " + LocationID + "," + Session["AppUserId"] + ", GetDate(),'" + txtemergContactName.Text + "'," + ddEmergContactRelation.SelectedValue + ",'" + txtemergContactPhone.Text + "','" + txtemergContactAddress.Text + "',");
        SbContColumns.Append(" Insert into [DTL_PATIENTCONTACTS](Ptn_pk,Visitid,LocationId,UserID,CreateDate,EmergContactName,EmergContactRelation,EmergContactPhone,EmergContactAddress,NextofKinName,NextofKinRelationship,NextofKinTelNo,NextofAddress,");
        SbContValues.Append("Values(IDENT_CURRENT('mst_Patient'),IDENT_CURRENT('Ord_Visit')," + Session["AppLocationId"] + "," + Session["AppUserId"] + ", GetDate(),'" + txtemergContactName.Text + "'," + ddEmergContactRelation.SelectedValue + ",'" + txtemergContactPhone.Text + "','" + txtemergContactAddress.Text + "','" + txtNOKName.Text + "'," + ddlNOKRelationship.SelectedValue + ",'" + txtNOKPhone.Text + "','" + txtNOKAddress.Text + "',");

        StringBuilder SbHouseHoldColumns = new StringBuilder();
        StringBuilder SbHouseHoldValues = new StringBuilder();
        SbHouseHoldColumns.Append(" Delete  from [DTL_PATIENTHOUSEHOLDINFO] where Ptn_Pk=" + PatientID + " and Visit_Pk=" + VisitID + " and LocationID=" + LocationID + " ");
        SbHouseHoldColumns.Append("Insert into [DTL_PATIENTHOUSEHOLDINFO](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SbHouseHoldValues.Append("Values(" + PatientID + "," + VisitID + ", " + LocationID + "," + Session["AppUserId"] + ", GetDate(),");

        StringBuilder SbruralResidenceColumns = new StringBuilder();
        StringBuilder SbruralResidenceValues = new StringBuilder();
        SbruralResidenceColumns.Append(" Delete  from [DTL_RURALRESIDENCE] where Ptn_Pk=" + PatientID + " and Visit_Pk=" + VisitID + " and LocationID=" + LocationID + " ");
        SbruralResidenceColumns.Append("Insert into [DTL_RURALRESIDENCE](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SbruralResidenceValues.Append("Values(" + PatientID + "," + VisitID + ", " + LocationID + "," + Session["AppUserId"] + ", GetDate(),");

        StringBuilder SburbanresidenceColumns = new StringBuilder();
        StringBuilder SburbanresidenceValues = new StringBuilder();
        SburbanresidenceColumns.Append(" Delete  from [DTL_URBANRESIDENCE] where Ptn_Pk=" + PatientID + " and Visit_Pk=" + VisitID + " and LocationID=" + LocationID + " ");
        SburbanresidenceColumns.Append("Insert into [DTL_URBANRESIDENCE](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SburbanresidenceValues.Append("Values(" + PatientID + "," + VisitID + ", " + LocationID + "," + Session["AppUserId"] + ", GetDate(),");

        StringBuilder SbpatienthivprevcareenrollmentColumns = new StringBuilder();
        StringBuilder SbpatienthivprevcareenrollmentValues = new StringBuilder();
        SbpatienthivprevcareenrollmentColumns.Append(" Delete  from [DTL_PATIENTHIVPREVCAREENROLLMENT] where Ptn_Pk=" + PatientID + " and Visit_Pk=" + VisitID + " and LocationID=" + LocationID + " ");
        SbpatienthivprevcareenrollmentColumns.Append("Insert into [DTL_PATIENTHIVPREVCAREENROLLMENT](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SbpatienthivprevcareenrollmentValues.Append("Values(" + PatientID + "," + VisitID + ", " + LocationID + "," + Session["AppUserId"] + ", GetDate(),");

        StringBuilder SbpatientguarantorColumns = new StringBuilder();
        StringBuilder SbpatientguarantorValues = new StringBuilder();
        SbpatientguarantorColumns.Append(" Delete  from [DTL_PATIENTGUARANTOR] where Ptn_Pk=" + PatientID + " and Visit_Pk=" + VisitID + " and LocationID=" + LocationID + " ");
        SbpatientguarantorColumns.Append("Insert into [DTL_PATIENTGUARANTOR](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SbpatientguarantorValues.Append("Values(" + PatientID + "," + VisitID + ", " + LocationID + "," + Session["AppUserId"] + ", GetDate(),");

        StringBuilder SbpatientDepositsColumns = new StringBuilder();
        StringBuilder SbpatientDepositsValues = new StringBuilder();
        SbpatientDepositsColumns.Append(" Delete  from [DTL_PATIENTDEPOSITS] where Ptn_Pk=" + PatientID + " and Visit_Pk=" + VisitID + " and LocationID=" + LocationID + " ");
        SbpatientDepositsColumns.Append("Insert into [DTL_PATIENTDEPOSITS](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SbpatientDepositsValues.Append("Values(" + PatientID + "," + VisitID + ", " + LocationID + "," + Session["AppUserId"] + ", GetDate(),");

        StringBuilder SbpatientInterviewerColumns = new StringBuilder();
        StringBuilder SbpatientInterviewerValues = new StringBuilder();
        SbpatientInterviewerColumns.Append(" Delete  from [DTL_PATIENTINTERVIEWER] where Ptn_Pk=" + PatientID + " and Visit_Pk=" + VisitID + " and LocationID=" + LocationID + " ");
        SbpatientInterviewerColumns.Append("Insert into [DTL_PATIENTINTERVIEWER](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SbpatientInterviewerValues.Append("Values(" + PatientID + "," + VisitID + ", " + LocationID + "," + Session["AppUserId"] + ", GetDate(),");

        StringBuilder SbCustColumns = new StringBuilder();
        StringBuilder SbCustValues = new StringBuilder();
        string TableName = "DTL_FBCUSTOMFIELD_" + "Patient Registration".Replace(' ', '_');
        SbCustColumns.Append("if exists(select name from sysobjects where type = 'u' and name ='" + TableName + "') begin ");
        SbCustColumns.Append(" Delete  from [" + TableName + "] where Ptn_Pk=" + PatientID + " and Visit_pk=" + VisitID + " and LocationID=" + LocationID + " ");
        SbCustColumns.Append(" Insert into [" + TableName + "](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SbCustValues.Append("Values(" + PatientID + "," + VisitID + "," + LocationID + "," + Session["AppUserId"] + ", GetDate(),");
        //////////////////////////////////////////////////
        //For Controls Other than Multiselect
        foreach (DataRow theMainDR in LnkDTUnique.Rows)
        {
            StringBuilder SbColumns = new StringBuilder();
            StringBuilder SbValues = new StringBuilder();

            if (Convert.ToString(theMainDR["PDFTableName"]).ToUpper() == "DTL_PATIENTCONTACTS")
            {
                SbColumns.Append(" Delete  from [" + theMainDR["PDFTableName"] + "] where Ptn_Pk=" + PatientID + " and VisitID=" + VisitID + " and LocationID=" + LocationID + " ");
                SbColumns.Append(" Insert into [" + theMainDR["PDFTableName"] + "](Ptn_pk,VisitId,LocationId,UserID,Updatedate,");
                SbValues.Append("Values(" + PatientID + "," + VisitID + ", " + LocationID + "," + Session["AppUserId"] + ", GetDate(),");
            }
            else if (theMainDR["PDFTableName"].ToString() == "ord_patientpharmacyorder")
            {
                SbColumns.Append(" Delete  from [" + theMainDR["PDFTableName"] + "] where Ptn_Pk=" + PatientID + " and VisitID=" + VisitID + " and LocationID=" + LocationID + " ");
                SbColumns.Append(" Insert into [" + theMainDR["PDFTableName"] + "](Ptn_pk,VisitId,LocationId,UserID,Updatedate,");
                SbValues.Append("Values(" + PatientID + "," + VisitID + ", " + LocationID + "," + Session["AppUserId"] + ", GetDate(),");
            }
            else
            {
                SbColumns.Append(" Delete  from [" + theMainDR["PDFTableName"] + "] where Ptn_Pk=" + PatientID + " and Visit_pk=" + VisitID + " and LocationID=" + LocationID + " ");
                SbColumns.Append(" Insert into [" + theMainDR["PDFTableName"] + "](Ptn_pk,Visit_pk,LocationId,UserID,Updatedate,");
                SbValues.Append("Values(" + PatientID + "," + VisitID + ", " + LocationID + "," + Session["AppUserId"] + ", GetDate(),");
            }

            if (Convert.ToString(theMainDR["PDFTableName"]).ToUpper() == "MST_PATIENT")
            {
            }
            else
            {
                if (SbColumns.Length > 0)
                {
                    SbColumns.Remove(SbColumns.Length - 1, 1);
                    SbValues.Remove(SbValues.Length - 1, 1);
                    sbUpdate.Append(SbColumns.Append(")"));
                    sbUpdate.Append(SbValues.Append(")"));
                }
            }
        }

        SbmstpatColumns.Append("UserID='" + Session["AppUserId"] + "', UpdateDate=getdate() where ptn_pk='" + PatientID + "' and LocationID='" + Session["AppLocationId"] + "' ");
        sbUpdate.Append(SbmstpatColumns);
        SbmstpatColumns = new StringBuilder();
        SbmstpatColumns.Append("Update [ord_Visit] Set VisitDate='" + txtRegDate.Value + "', UserID='" + Session["AppUserId"] + "', UpdateDate=getdate() where Visit_Id='" + VisitID + "' and Visittype=12");
        sbUpdate.Append(SbmstpatColumns);
        if (SbContColumns.Length > 0)
        {
            SbContColumns.Remove(SbContColumns.Length - 1, 1);
            SbContValues.Remove(SbContValues.Length - 1, 1);
            sbUpdate.Append(SbContColumns.Append(")"));
            sbUpdate.Append(SbContValues.Append(")"));
        }

        if (SbHouseHoldColumns.Length > 0)
        {
            SbHouseHoldColumns.Remove(SbHouseHoldColumns.Length - 1, 1);
            SbHouseHoldValues.Remove(SbHouseHoldValues.Length - 1, 1);
            sbUpdate.Append(SbHouseHoldColumns.Append(")"));
            sbUpdate.Append(SbHouseHoldValues.Append(")"));
        }

        if (SbruralResidenceColumns.Length > 0)
        {
            SbruralResidenceColumns.Remove(SbruralResidenceColumns.Length - 1, 1);
            SbruralResidenceValues.Remove(SbruralResidenceValues.Length - 1, 1);
            sbUpdate.Append(SbruralResidenceColumns.Append(")"));
            sbUpdate.Append(SbruralResidenceValues.Append(")"));
        }

        if (SburbanresidenceColumns.Length > 0)
        {
            SburbanresidenceColumns.Remove(SburbanresidenceColumns.Length - 1, 1);
            SburbanresidenceValues.Remove(SburbanresidenceValues.Length - 1, 1);
            sbUpdate.Append(SburbanresidenceColumns.Append(")"));
            sbUpdate.Append(SburbanresidenceValues.Append(")"));
        }

        if (SbpatienthivprevcareenrollmentColumns.Length > 0)
        {
            SbpatienthivprevcareenrollmentColumns.Remove(SbpatienthivprevcareenrollmentColumns.Length - 1, 1);
            SbpatienthivprevcareenrollmentValues.Remove(SbpatienthivprevcareenrollmentValues.Length - 1, 1);
            sbUpdate.Append(SbpatienthivprevcareenrollmentColumns.Append(")"));
            sbUpdate.Append(SbpatienthivprevcareenrollmentValues.Append(")"));
        }

        if (SbpatientguarantorColumns.Length > 0)
        {
            SbpatientguarantorColumns.Remove(SbpatientguarantorColumns.Length - 1, 1);
            SbpatientguarantorValues.Remove(SbpatientguarantorValues.Length - 1, 1);
            sbUpdate.Append(SbpatientguarantorColumns.Append(")"));
            sbUpdate.Append(SbpatientguarantorValues.Append(")"));
        }

        if (SbpatientDepositsColumns.Length > 0)
        {
            SbpatientDepositsColumns.Remove(SbpatientDepositsColumns.Length - 1, 1);
            SbpatientDepositsValues.Remove(SbpatientDepositsValues.Length - 1, 1);
            sbUpdate.Append(SbpatientDepositsColumns.Append(")"));
            sbUpdate.Append(SbpatientDepositsValues.Append(")"));
        }

        if (SbpatientInterviewerColumns.Length > 0)
        {
            SbpatientInterviewerColumns.Remove(SbpatientInterviewerColumns.Length - 1, 1);
            SbpatientInterviewerValues.Remove(SbpatientInterviewerValues.Length - 1, 1);
            sbUpdate.Append(SbpatientInterviewerColumns.Append(")"));
            sbUpdate.Append(SbpatientInterviewerValues.Append(")"));
        }
        if (SbCustColumns.Length > 0)
        {
            SbCustColumns.Remove(SbCustColumns.Length - 1, 1);
            SbCustValues.Remove(SbCustValues.Length - 1, 1);
            sbUpdate.Append(SbCustColumns.Append(")"));
            sbUpdate.Append(SbCustValues.Append(") end "));
        }

        sbUpdate.Append("Select 1[Saved]");
        return sbUpdate;
    }
    private StringBuilder SaveCustomRegistrationData()
    {
        ICustomForm MgrSaveUpdate = (ICustomForm)ObjectFactory.CreateInstance(ObjFactoryParameterBCustom);

        DataTable LnkDTUnique = new DataTable();
        StringBuilder sbUpdate = new StringBuilder();
        DataTable theDTNoMulti = new DataTable();
        DataTable theDTMulti = new DataTable();
        DataTable theDTConMulti = new DataTable();

        theDTNoMulti = ((DataTable)ViewState["NoMulti"]);
        theDTMulti = ((DataTable)ViewState["LnkTable"]);
        theDTConMulti = ((DataTable)ViewState["LnkConTable"]);

        StringBuilder SbInsert = new StringBuilder();
        if (ViewState["NoMulti"] != null)
        {
            LnkDTUnique = theDTNoMulti.DefaultView.ToTable(true, "PDFTableName", "FeatureName").Copy();
        }
        int DOBPrecision = 0;
        if (rbtndobPrecEstimated.Checked == true)
        {
            DOBPrecision = 1;
        }
        else if (rbtndobPrecExact.Checked == true)
        {
            DOBPrecision = 0;
        }
        else
        {
            DOBPrecision = 2;
        }
        ///////////////Added by Naveen///////////////////
        StringBuilder SbmstpatColumns = new StringBuilder();
        StringBuilder SbmstpatValues = new StringBuilder();
        SbmstpatColumns.Append("Insert into [MST_PATIENT](");
        SbmstpatColumns.Append("Status, FirstName, MiddleName, LastName, LocationID, RegistrationDate, Sex, DOB, [ID/PassportNo], DobPrecision, MaritalStatus, VillageName, DistrictName, Province, LocalCouncil, Address, Phone, CountryId,  PosId, SatelliteId, UserID, CreateDate,");
        SbmstpatValues.Append("Values(");
        SbmstpatValues.Append("'0', encryptbykey(key_guid('Key_CTC'),'" + txtfirstName.Text + "'), encryptbykey(key_guid('Key_CTC'),'" + txtmiddleName.Text + "'), encryptbykey(key_guid('Key_CTC'),'" + txtlastName.Text + "')");
        SbmstpatValues.Append(", '" + Session["AppLocationId"] + "', '" + txtRegDate.Value + "', '" + ddgender.SelectedValue + "', '" + TxtDOB.Text + "', '0','" + DOBPrecision + "', '" + ddmaritalStatus.SelectedValue + "', '" + ddvillageName.SelectedValue + "','" + dddistrictName.SelectedValue + "','" + ddProvince.SelectedValue + "',");
        SbmstpatValues.Append("'" + txtlocalCouncil.Text + "',encryptbykey(key_guid('Key_CTC'),'" + txtaddress.Text + "'),encryptbykey(key_guid('Key_CTC'),'" + txtphone.Text + "'),");
        SbmstpatValues.Append("'" + Session["AppCountryId"] + "', '" + Session["AppPosID"] + "', '" + Session["AppSatelliteId"] + "', '" + Session["AppUserId"] + "', getdate(),");

        StringBuilder SbContColumns = new StringBuilder();
        StringBuilder SbContValues = new StringBuilder();
        //SbContColumns.Append("Insert into [DTL_PATIENTCONTACTS](Ptn_pk,Visitid,LocationId,UserID,CreateDate,");
        SbContColumns.Append(" Insert into [DTL_PATIENTCONTACTS](Ptn_pk,Visitid,LocationId,UserID,CreateDate,EmergContactName,EmergContactRelation,EmergContactPhone,EmergContactAddress,NextofKinName,NextofKinRelationship,NextofKinTelNo,NextofAddress,");
        SbContValues.Append("Values(IDENT_CURRENT('mst_Patient'),IDENT_CURRENT('Ord_Visit')," + Session["AppLocationId"] + "," + Session["AppUserId"] + ", GetDate(),'" + txtemergContactName.Text + "'," + ddEmergContactRelation.SelectedValue + ",'" + txtemergContactPhone.Text + "','" + txtemergContactAddress.Text + "','" + txtNOKName.Text + "'," + ddlNOKRelationship.SelectedValue + ",'" + txtNOKPhone.Text + "','" + txtNOKAddress.Text + "',");

        StringBuilder SbHouseHoldColumns = new StringBuilder();
        StringBuilder SbHouseHoldValues = new StringBuilder();
        SbHouseHoldColumns.Append("Insert into [DTL_PATIENTHOUSEHOLDINFO](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SbHouseHoldValues.Append("Values(IDENT_CURRENT('mst_Patient'),IDENT_CURRENT('Ord_Visit')," + Session["AppLocationId"] + "," + Session["AppUserId"] + ", GetDate(),");

        StringBuilder SbruralResidenceColumns = new StringBuilder();
        StringBuilder SbruralResidenceValues = new StringBuilder();
        SbruralResidenceColumns.Append("Insert into [DTL_RURALRESIDENCE](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SbruralResidenceValues.Append("Values(IDENT_CURRENT('mst_Patient'),IDENT_CURRENT('Ord_Visit')," + Session["AppLocationId"] + "," + Session["AppUserId"] + ", GetDate(),");

        StringBuilder SburbanresidenceColumns = new StringBuilder();
        StringBuilder SburbanresidenceValues = new StringBuilder();
        SburbanresidenceColumns.Append("Insert into [DTL_URBANRESIDENCE](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SburbanresidenceValues.Append("Values(IDENT_CURRENT('mst_Patient'),IDENT_CURRENT('Ord_Visit')," + Session["AppLocationId"] + "," + Session["AppUserId"] + ", GetDate(),");

        StringBuilder SbpatienthivprevcareenrollmentColumns = new StringBuilder();
        StringBuilder SbpatienthivprevcareenrollmentValues = new StringBuilder();
        SbpatienthivprevcareenrollmentColumns.Append("Insert into [DTL_PATIENTHIVPREVCAREENROLLMENT](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SbpatienthivprevcareenrollmentValues.Append("Values(IDENT_CURRENT('mst_Patient'),IDENT_CURRENT('Ord_Visit')," + Session["AppLocationId"] + "," + Session["AppUserId"] + ", GetDate(),");

        StringBuilder SbpatientguarantorColumns = new StringBuilder();
        StringBuilder SbpatientguarantorValues = new StringBuilder();
        SbpatientguarantorColumns.Append("Insert into [DTL_PATIENTGUARANTOR](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SbpatientguarantorValues.Append("Values(IDENT_CURRENT('mst_Patient'),IDENT_CURRENT('Ord_Visit')," + Session["AppLocationId"] + "," + Session["AppUserId"] + ", GetDate(),");

        StringBuilder SbpatientDepositsColumns = new StringBuilder();
        StringBuilder SbpatientDepositsValues = new StringBuilder();
        SbpatientDepositsColumns.Append("Insert into [DTL_PATIENTDEPOSITS](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SbpatientDepositsValues.Append("Values(IDENT_CURRENT('mst_Patient'),IDENT_CURRENT('Ord_Visit')," + Session["AppLocationId"] + "," + Session["AppUserId"] + ", GetDate(),");

        StringBuilder SbpatientInterviewerColumns = new StringBuilder();
        StringBuilder SbpatientInterviewerValues = new StringBuilder();
        SbpatientInterviewerColumns.Append("Insert into [DTL_PATIENTINTERVIEWER](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SbpatientInterviewerValues.Append("Values(IDENT_CURRENT('mst_Patient'),IDENT_CURRENT('Ord_Visit')," + Session["AppLocationId"] + "," + Session["AppUserId"] + ", GetDate(),");

        StringBuilder SbCustColumns = new StringBuilder();
        StringBuilder SbCustValues = new StringBuilder();
        string TableName = "DTL_FBCUSTOMFIELD_" + "Patient Registration".Replace(' ', '_');
        SbCustColumns.Append("if exists(select name from sysobjects where name = '" + TableName + "') begin ");
        SbCustColumns.Append("Insert into [" + TableName + "](Ptn_pk,Visit_Pk,LocationId,UserID,CreateDate,");
        SbCustValues.Append("Values(IDENT_CURRENT('mst_Patient'),IDENT_CURRENT('Ord_Visit')," + Session["AppLocationId"] + "," + Session["AppUserId"] + ", GetDate(),");

        /////////////////////////////////////////////////////
        if (SbmstpatColumns.Length > 0)
        {
            SbmstpatColumns.Remove(SbmstpatColumns.Length - 1, 1);
            SbmstpatValues.Remove(SbmstpatValues.Length - 1, 1);
            SbInsert.Append(SbmstpatColumns.Append(")"));
            SbInsert.Append(SbmstpatValues.Append(")"));
            SbmstpatColumns = new StringBuilder();
            SbmstpatValues = new StringBuilder();
            SbmstpatColumns.Append("Insert into ord_Visit(Ptn_Pk,LocationID,VisitDate,VisitType,UserID,CreateDate,dataquality");
            SbmstpatValues.Append("values (IDENT_CURRENT('mst_Patient'),'" + Session["AppLocationId"] + "', '" + txtRegDate.Value + "', 12, '" + Session["AppUserId"] + "', getdate(), 1");
            SbInsert.Append(SbmstpatColumns.Append(")"));
            SbInsert.Append(SbmstpatValues.Append(")"));
        }

        if (SbContColumns.Length > 0)
        {
            SbContColumns.Remove(SbContColumns.Length - 1, 1);
            SbContValues.Remove(SbContValues.Length - 1, 1);
            SbInsert.Append(SbContColumns.Append(")"));
            SbInsert.Append(SbContValues.Append(")"));
        }

        if (SbHouseHoldColumns.Length > 0)
        {
            SbHouseHoldColumns.Remove(SbHouseHoldColumns.Length - 1, 1);
            SbHouseHoldValues.Remove(SbHouseHoldValues.Length - 1, 1);
            SbInsert.Append(SbHouseHoldColumns.Append(")"));
            SbInsert.Append(SbHouseHoldValues.Append(")"));
        }

        if (SbruralResidenceColumns.Length > 0)
        {
            SbruralResidenceColumns.Remove(SbruralResidenceColumns.Length - 1, 1);
            SbruralResidenceValues.Remove(SbruralResidenceValues.Length - 1, 1);
            SbInsert.Append(SbruralResidenceColumns.Append(")"));
            SbInsert.Append(SbruralResidenceValues.Append(")"));
        }

        if (SburbanresidenceColumns.Length > 0)
        {
            SburbanresidenceColumns.Remove(SburbanresidenceColumns.Length - 1, 1);
            SburbanresidenceValues.Remove(SburbanresidenceValues.Length - 1, 1);
            SbInsert.Append(SburbanresidenceColumns.Append(")"));
            SbInsert.Append(SburbanresidenceValues.Append(")"));
        }

        if (SbpatienthivprevcareenrollmentColumns.Length > 0)
        {
            SbpatienthivprevcareenrollmentColumns.Remove(SbpatienthivprevcareenrollmentColumns.Length - 1, 1);
            SbpatienthivprevcareenrollmentValues.Remove(SbpatienthivprevcareenrollmentValues.Length - 1, 1);
            SbInsert.Append(SbpatienthivprevcareenrollmentColumns.Append(")"));
            SbInsert.Append(SbpatienthivprevcareenrollmentValues.Append(")"));
        }

        if (SbpatientguarantorColumns.Length > 0)
        {
            SbpatientguarantorColumns.Remove(SbpatientguarantorColumns.Length - 1, 1);
            SbpatientguarantorValues.Remove(SbpatientguarantorValues.Length - 1, 1);
            SbInsert.Append(SbpatientguarantorColumns.Append(")"));
            SbInsert.Append(SbpatientguarantorValues.Append(")"));
        }

        if (SbpatientDepositsColumns.Length > 0)
        {
            SbpatientDepositsColumns.Remove(SbpatientDepositsColumns.Length - 1, 1);
            SbpatientDepositsValues.Remove(SbpatientDepositsValues.Length - 1, 1);
            SbInsert.Append(SbpatientDepositsColumns.Append(")"));
            SbInsert.Append(SbpatientDepositsValues.Append(")"));
        }

        if (SbpatientInterviewerColumns.Length > 0)
        {
            SbpatientInterviewerColumns.Remove(SbpatientInterviewerColumns.Length - 1, 1);
            SbpatientInterviewerValues.Remove(SbpatientInterviewerValues.Length - 1, 1);
            SbInsert.Append(SbpatientInterviewerColumns.Append(")"));
            SbInsert.Append(SbpatientInterviewerValues.Append(")"));
        }

        if (SbCustColumns.Length > 0)
        {
            SbCustColumns.Remove(SbCustColumns.Length - 1, 1);
            SbCustValues.Remove(SbCustValues.Length - 1, 1);
            SbInsert.Append(SbCustColumns.Append(")"));
            SbInsert.Append(SbCustValues.Append(") end "));
        }

        SbInsert.Append("update mst_patient set IQNumber = 'IQ-'+convert(varchar,Replicate('0',20-len(x.[ptnIdentifier]))) +x.[ptnIdentifier]  from ");
        SbInsert.Append("(select UPPER(substring(convert(varchar(50),decryptbykey(firstname)),1,1))+UPPER(substring(convert(varchar(50),decryptbykey(lastname)),1,1))+");
        SbInsert.Append("convert(varchar,dob,112)+convert(varchar,locationid)+Convert(varchar(10),ptn_pk) [ptnIdentifier] from mst_patient ");
        SbInsert.Append("where ptn_pk = ident_current('mst_patient'))x where ptn_pk= ident_current('mst_patient') ");
        SbInsert.Append("Select ident_current('mst_patient')[ptn_pk], a.IQNumber, b.Visit_ID from mst_patient a inner join Ord_visit b on a.ptn_pk=b.ptn_pk where a.Ptn_Pk=ident_current('mst_patient') and b.visittype=12");

        return SbInsert;
    }

    void SelectedProvinceItemTypeChanged(object sender, EventArgs e)
    {
        if (ddProvince.SelectedValue != string.Empty && int.Parse(ddProvince.SelectedValue) > 0)
        {
            BindFunctions BindManager = new BindFunctions();
            int provinceID = int.Parse(ddProvince.SelectedValue);
            ICommonData oCommonData = (ICommonData)ObjectFactory.CreateInstance("BusinessProcess.Service.BCommonData,BusinessProcess.Service");
            DataTable theDT = (DataTable)oCommonData.getAllDistrict();
            DataView theDV = theDT.DefaultView;
            theDV.RowFilter = "ProvinceID = " + provinceID + "";
            if (theDV != null && theDV.Table.Rows.Count > 0)
            {
                BindManager.BindCombo(dddistrictName, theDV.ToTable(), "Name", "ID");
                theDT.Clear();
            }
        }
    }

    private void Binddropdown()
    {
        try
        {
            BindFunctions BindManager = new BindFunctions();
            IQCareUtils theUtils = new IQCareUtils();
            DataView theDV = new DataView();
            DataTable theDT = new DataTable();

            if ((Session["PatientId"] == null) || (Convert.ToInt32(Session["PatientId"]) == 0))
            {
                theDV = new DataView(theDSXML.Tables["Mst_Decode"]);
                theDV.RowFilter = "CodeID=4";
                if (theDV.Table != null)
                {
                    theDT = (DataTable)theUtils.CreateTableFromDataView(theDV);
                    BindManager.BindCombo(ddgender, theDT, "Name", "ID");
                    theDV.Dispose();
                    theDT.Clear();
                }

                theDV = new DataView(theDSXML.Tables["Mst_Decode"]);
                Session["SystemId"] = ConfigurationManager.AppSettings["SystemId"].ToString();
                theDV.RowFilter = "CodeID=12 and SystemID=" + Session["SystemId"] + " and DeleteFlag=0";
                theDT = (DataTable)theUtils.CreateTableFromDataView(theDV);
                BindManager.BindCombo(ddmaritalStatus, theDT, "Name", "ID");
                theDV.Dispose();
                theDT.Clear();
            }
            else
            {
                theDV = new DataView(theDSXML.Tables["Mst_Decode"]);
                theDV.RowFilter = "CodeID=4";
                if (theDV.Table != null)
                {
                    theDT = (DataTable)theUtils.CreateTableFromDataView(theDV);
                    BindManager.BindCombo(ddgender, theDT, "Name", "ID");
                    theDV.Dispose();
                    theDT.Clear();
                }

                theDV = new DataView(theDSXML.Tables["Mst_Decode"]);
                Session["SystemId"] = ConfigurationManager.AppSettings["SystemId"].ToString();

                theDV.RowFilter = "CodeID=12 and SystemID=" + Session["SystemId"] + "";
                theDT = (DataTable)theUtils.CreateTableFromDataView(theDV);
                BindManager.BindCombo(ddmaritalStatus, theDT, "Name", "ID");
                theDV.Dispose();
                theDT.Clear();

            }

            ICommonData oCommonData = (ICommonData)ObjectFactory.CreateInstance("BusinessProcess.Service.BCommonData,BusinessProcess.Service");
            theDT = (DataTable)oCommonData.getAllCountries();
            if (theDT != null && theDT.Rows.Count > 0)
            {
                BindManager.BindCombo(ddCountry, theDT, "CountryName", "CountryID");
                ddCountry.SelectedValue = Session["AppCountryId"].ToString();
                //ddCountry.Enabled = false;
                theDV.Dispose();
                theDT.Clear();
            }

            theDT = (DataTable)oCommonData.getAllProvince();
            theDV = theDT.DefaultView;
            theDV.RowFilter = "CountryID = " + Session["AppCountryId"].ToString() + "";
            theDT = (DataTable)theUtils.CreateTableFromDataView(theDV);
            if (theDT != null && theDT.Rows.Count > 0)
            {
                BindManager.BindCombo(ddProvince, theDT, "Name", "ID");
                theDV.Dispose();
                theDT.Clear();
            }

            theDT = (DataTable)oCommonData.getAllDistrict();
            theDV = theDT.DefaultView;
            theDV.RowFilter = "SystemID = " + Session["SystemId"].ToString() + "";
            theDT = (DataTable)theUtils.CreateTableFromDataView(theDV);
            if (theDT != null && theDT.Rows.Count > 0)
            {
                BindManager.BindCombo(dddistrictName, theDT, "Name", "ID");
                theDT.Clear();
            }

            theDT = (DataTable)oCommonData.getAllVillages();
            theDV = theDT.DefaultView;
            theDV.RowFilter = "SystemID = " + Session["SystemId"].ToString() + "";
            theDT = (DataTable)theUtils.CreateTableFromDataView(theDV);
            if (theDT != null && theDT.Rows.Count > 0)
            {
                BindManager.BindCombo(ddvillageName, theDT, "Name", "ID");
                theDT.Clear();
            }

            theDV = new DataView(theDSXML.Tables["Mst_RelationshipType"]);
            theDT = (DataTable)theUtils.CreateTableFromDataView(theDV);
            BindManager.BindCombo(ddEmergContactRelation, theDT, "Name", "ID");
            BindManager.BindCombo(ddlNOKRelationship, theDT, "Name", "ID");
            theDV.Dispose();
            theDT.Clear();
        }
        catch (Exception err)
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["MessageText"] = err.Message.ToString();
            IQCareMsgBox.Show("#C1", theBuilder, this);
            return;
        }
        finally
        {

        }
    }

    private DataTable SetControlIDs(Control theControl)
    {
        DataTable TempDT = new DataTable();

        DataColumn Column = new DataColumn("Column");
        Column.DataType = System.Type.GetType("System.String");
        TempDT.Columns.Add(Column);

        DataColumn Control = new DataColumn("FieldID");
        Control.DataType = System.Type.GetType("System.String");
        TempDT.Columns.Add(Control);

        DataColumn Value = new DataColumn("Value");
        Value.DataType = System.Type.GetType("System.String");
        TempDT.Columns.Add(Value);

        DataColumn TableName = new DataColumn("TableName");
        TableName.DataType = System.Type.GetType("System.String");
        TempDT.Columns.Add(TableName);

        DataRow DRTemp;
        DRTemp = TempDT.NewRow();

        foreach (Control x in theControl.Controls)
        {
            if (x.GetType() == typeof(System.Web.UI.WebControls.TextBox))
            {

                DRTemp = TempDT.NewRow();
                string[] str = ((TextBox)x).ID.Split('-');
                if (str[1] != "Phone" && str[1] != "LocalCouncil" && str[1] != "Address" && str[1] != "EmergContactPhone" && str[1] != "EmergContactName" && str[1] != "EmergContactAddress")
                {
                    if (str[1] != string.Empty)
                    {
                        DRTemp["Column"] = str[1];
                        if (((TextBox)x).Enabled == true)
                            DRTemp["Value"] = ((TextBox)x).Text;
                        else
                            DRTemp["Value"] = "";
                        DRTemp["TableName"] = str[2];
                        DRTemp["FieldID"] = str[3];
                        TempDT.Rows.Add(DRTemp);
                    }
                }

            }
            if (x.GetType() == typeof(System.Web.UI.HtmlControls.HtmlInputRadioButton))
            {

                DRTemp = TempDT.NewRow();
                string[] str = ((HtmlInputRadioButton)x).ID.Split('-');
                if (((HtmlInputRadioButton)x).ID == "RADIO1-" + str[1] + "-" + str[2] + "-" + str[3])
                {
                    if (((HtmlInputRadioButton)x).Checked == true)
                    {
                        DRTemp["Column"] = str[1];
                        if (((HtmlInputRadioButton)x).Visible == true)
                            DRTemp["Value"] = "1";
                        else
                            DRTemp["Value"] = "";
                    }
                }
                else if (((HtmlInputRadioButton)x).ID == "RADIO2-" + str[1] + "-" + str[2] + "-" + str[3])
                {
                    if (((HtmlInputRadioButton)x).Checked == true)
                    {
                        DRTemp["Column"] = str[1];
                        if (((HtmlInputRadioButton)x).Visible == true)
                            DRTemp["Value"] = "0";
                        else
                            DRTemp["Value"] = "";
                    }

                }

                DRTemp["TableName"] = str[2];
                DRTemp["FieldID"] = str[3];
                TempDT.Rows.Add(DRTemp);
            }
            if (x.GetType() == typeof(System.Web.UI.WebControls.DropDownList))
            {
                DRTemp = TempDT.NewRow();
                string[] str = ((DropDownList)x).ID.Split('-');
                if (str[1] != "EmergContactRelation" && str[1] != "VillageName" && str[1] != "DistrictName" && str[1] != "Province" && str[1] != "CountryId")
                {
                    DRTemp["Column"] = str[1];

                    if (((DropDownList)x).Enabled == true)
                        DRTemp["Value"] = ((DropDownList)x).SelectedValue;
                    else
                        //DRTemp["Value"] = "0";
                        DRTemp["Value"] = "";
                    DRTemp["TableName"] = str[2];
                    DRTemp["FieldID"] = str[3];
                    TempDT.Rows.Add(DRTemp);
                }
            }

            if (x.GetType() == typeof(System.Web.UI.HtmlControls.HtmlInputCheckBox))
            {
                DRTemp = TempDT.NewRow();
                string[] str = ((HtmlInputCheckBox)x).ID.Split('-');
                DRTemp["Column"] = str[1];
                if (((HtmlInputCheckBox)x).Visible == true)
                {
                    if (((HtmlInputCheckBox)x).Checked == true)
                    {
                        DRTemp["Value"] = 1;
                    }
                    else
                    {
                        DRTemp["Value"] = 0;
                    }
                }
                else
                {
                    DRTemp["Value"] = "";
                }
                DRTemp["TableName"] = str[2];
                DRTemp["FieldID"] = str[3];
                TempDT.Rows.Add(DRTemp);
            }
        }
        return TempDT;
    }

    private Boolean FieldValidation()
    {
        IIQCareSystem IQCareSecurity;
        IQCareSecurity = (IIQCareSystem)ObjectFactory.CreateInstance("BusinessProcess.Security.BIQCareSystem, BusinessProcess.Security");
        DateTime theCurrentDate = (DateTime)IQCareSecurity.SystemDate();
        IQCareUtils theUtils = new IQCareUtils();
        if (txtfirstName.Text.Trim() == "")
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["Control"] = "First Name";
            IQCareMsgBox.Show("BlankTextBox", theBuilder, this);
            txtfirstName.Focus();
            return false;
        }
        else if (txtlastName.Text.Trim() == "")
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["Control"] = "Last Name";
            IQCareMsgBox.Show("BlankTextBox", theBuilder, this);
            txtlastName.Focus();
            return false;
        }
        else if (txtRegDate.Value.Trim() == "")
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["Control"] = "Registration Date";
            IQCareMsgBox.Show("BlankTextBox", theBuilder, this);
            txtlastName.Focus();
            return false;
        }
        DateTime theEnrolDate = Convert.ToDateTime(theUtils.MakeDate(txtRegDate.Value));
        if (theEnrolDate > theCurrentDate)
        {
            IQCareMsgBox.Show("EnrolDate", this);
            return false;
        }
        if (ddgender.SelectedValue.Trim() == "0")
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["Control"] = "Sex";
            IQCareMsgBox.Show("BlankTextBox", theBuilder, this);
            ddgender.Focus();
            return false;
        }
        if (TxtDOB.Text.Trim() == "")
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["Control"] = "DOB";
            IQCareMsgBox.Show("BlankTextBox", theBuilder, this);
            TxtDOB.Focus();
            return false;
        }
        if (txtphone.Text.Trim() == "")
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["Control"] = "Phone Number";
            IQCareMsgBox.Show("BlankTextBox", theBuilder, this);
            txtphone.Focus();
            return false;
        }
        if (txtlocalCouncil.Text.Trim() == "")
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["Control"] = "Place of Residence";
            IQCareMsgBox.Show("BlankTextBox", theBuilder, this);
            txtlocalCouncil.Focus();
            return false;
        }

        DateTime theDOBDate = Convert.ToDateTime(theUtils.MakeDate(TxtDOB.Text));
        if (theDOBDate > theCurrentDate)
        {
            IQCareMsgBox.Show("DOBDate", this);
            TxtDOB.Focus();
            return false;
        }
        if (theDOBDate > theEnrolDate)
        {
            IQCareMsgBox.Show("DOB_EnrolDate", this);
            return false;
        }
        if (Convert.ToInt32(Session["PatientId"]) > 0 && ViewState["ARTStartDate"] != null)
        {
            DateTime theARTRegDate = Convert.ToDateTime(ViewState["ARTStartDate"].ToString());
            if (theEnrolDate > theARTRegDate)
            {
                IQCareMsgBox.Show("ARTRegDate", this);
                return false;
            }
        }

        //PMTCT Business rule
        if (Request.Form[txtageCurrentYears.UniqueID].ToString().Length == 0 || Request.Form[txtageCurrentMonths.UniqueID].ToString().Length == 0)
        {
            CalculateAge_YearMonth(Convert.ToDateTime(TxtDOB.Text.Trim()));
        }
        if (Convert.ToInt32(Session["TechnicalAreaId"]) == 1)
        {
            //Change By Rahmat 06-Feb-2018
            // Male above than 2 yrs
            if ((Convert.ToInt32(txtageCurrentYears.Text.Trim() == "" ? "0" : txtageCurrentYears.Text.Trim()) > 2) && (ddgender.SelectedValue == "16"))
            {
                IQCareMsgBox.Show("PMTCTMaleRegister", this);
                return false;
            }
            // Child above than 2 yrs
            else if ((Convert.ToInt32(txtageCurrentYears.Text.Trim() == "" ? "0" : txtageCurrentYears.Text.Trim()) == 2) && (Convert.ToInt32(txtageCurrentMonths.Text.Trim() == "" ? "0" : txtageCurrentMonths.Text.Trim()) != 0))
            {
                IQCareMsgBox.Show("PMTCTMaleRegister", this);
                return false;
            }
        }

        return true;
    }
    private void CalculateAge_YearMonth(DateTime Dob)
    {
        DateTime Now = DateTime.Now;
        int Years = new DateTime(DateTime.Now.Subtract(Dob).Ticks).Year - 1;
        DateTime PastYearDate = Dob.AddYears(Years);
        int Months = 0;
        for (int i = 1; i <= 12; i++)
        {
            if (PastYearDate.AddMonths(i) == Now)
            {
                Months = i;
                break;
            }
            else if (PastYearDate.AddMonths(i) >= Now)
            {
                Months = i - 1;
                break;
            }
        }
        txtageCurrentYears.Text = Years.ToString();
        txtageCurrentMonths.Text = Months.ToString();
    }

    protected void btncontinue_Click(object sender, EventArgs e)
    {
        try
        {
            if (FieldValidation() == false)
            {
                return;
            }

            IPatientRegistration IPatientFormMgr = (IPatientRegistration)ObjectFactory.CreateInstance(ObjFactoryParameter);
            if (PatientID == 0)
            {
                HashTableParameter();
                Session["htPtnRegParameter"] = htParameters;
                StringBuilder Add = SaveCustomRegistrationData();
                Session["CustomRegistration"] = Add;
                SaveCancel();
            }
            else if (PatientID > 0)
            {
                StringBuilder Edit = UpdateCustomRegistrationData(PatientID, VisitID, LocationID);
                DataSet Update = IPatientFormMgr.Common_GetSaveUpdateforCustomRegistrion(Edit.ToString());
                if (Update.Tables[0].Rows.Count > 0)
                {
                    UpdateCancel();
                }
            }

        }
        catch (Exception)
        {

            throw;
        }

    }

    private void SaveCancel()
    {
        IQCareMsgBox.NotifyAction("This Registration will be redirected to Service. Do you want to close?", "Patient Registration Form", false, this, "window.location.href='./frmAddTechnicalArea.aspx?mod=" + Session["TechnicalAreaId"] + "';\n");
        //string script = "<script language = 'javascript' defer ='defer' id = 'confirm'>\n";
        //script += "var ans;\n";
        //script += "ans=window.confirm('This Registration will be redirected to Service. Do you want to close?');\n";
        //script += "if (ans==true)\n";
        //script += "{\n";
        //script += "window.location.href='./frmAddTechnicalArea.aspx?mod=" + Session["TechnicalAreaId"] + "';\n";
        //script += "}\n";
        //script += "</script>\n";
        //RegisterStartupScript("confirm", script);
    }

    private void UpdateCancel()
    {
        IQCareMsgBox.NotifyAction("'Registration Form Update Successfully. Do you want to close?", "Patient Registration Form", false, this, "window.location.href='./frmAddTechnicalArea.aspx?mod=" + Session["TechnicalAreaId"] + "';\n");
        //string script = "<script language = 'javascript' defer ='defer' id = 'confirm2'>\n";
        //script += "var ans;\n";
        //script += "ans=window.confirm('Registration Form Update Successfully. Do you want to close?');\n";
        //script += "if (ans==true)\n";
        //script += "{\n";
        //// script += "window.location.href='./ClinicalForms/frmPatient_Home.aspx';\n";
        //script += "window.location.href='./frmAddTechnicalArea.aspx?mod=" + Session["TechnicalAreaId"] + "';\n";
        //script += "}\n";
        //script += "</script>\n";
        //RegisterStartupScript("confirm2", script);
    }

    protected void btnCancel_Click(object sender, EventArgs e)
    {
        //VY changed 2014-10-07 to go to facility home when closed
        Response.Redirect("~/frmFacilityHome.aspx");
        /* if (txtIQCareRef.Text == "")
         {
             Response.Redirect("~/frmFindAddPatient.aspx");
         }
         else
             Response.Redirect("frmAddTechnicalArea.aspx");*/
    }

    [Ajax.AjaxMethod(Ajax.HttpSessionStateRequirement.ReadWrite)]
    public string EnableControlAge(string strhidden, string age)
    {
        string strreturn = string.Empty;
        ////try
        ////{
        //string[] ArrCtlId = strhidden.Split(',');
        //DataTable theDT = (DataTable)Session["SessionBusRule"];
        //foreach (DataRow DR in theDT.Rows)
        //{
        //    for (int i = 0; i < ArrCtlId.Length; i++)
        //    {
        //        string[] a = ArrCtlId[i].Split('-');
        //        if (a[3].ToString() == Convert.ToString(DR["FieldId"]) && Convert.ToString(DR["BusRuleId"]) == "16")
        //        {
        //            if ((DR["Value"] != System.DBNull.Value) && (DR["Value1"] != System.DBNull.Value))
        //            {
        //                if (Convert.ToDecimal(age) >= Convert.ToDecimal(DR["Value"]) && Convert.ToDecimal(age) <= Convert.ToDecimal(DR["Value1"]))
        //                {
        //                    strreturn = ArrCtlId[i].ToString();
        //                }

        //            }
        //        }
        //    }

        //}
        ////}
        ////catch
        ////{

        ////}
        ////finally
        ////{
        ////}
        return strreturn;
    }

    [Ajax.AjaxMethod(Ajax.HttpSessionStateRequirement.ReadWrite)]
    protected void btncalculate_DOB_Click(object sender, EventArgs e)
    {
        if (txtageCurrentYears.Text.Trim() == "")
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["Control"] = "Age (Years)";
            IQCareMsgBox.Show("BlankTextBox", theBuilder, this);
            txtfirstName.Focus();
            return;
        }
        if (txtageCurrentMonths.Text != "")
        {
            if ((Convert.ToInt32(txtageCurrentMonths.Text) < 0) || (Convert.ToInt32(txtageCurrentMonths.Text) > 11))
            {
                MsgBuilder theMsg = new MsgBuilder();
                theMsg.DataElements["Control"] = "Age (Month)";
                IQCareMsgBox.Show("AgeMonthRange", theMsg, this);
                return;
            }
        }

        int age = 0;
        int months = 0;
        DateTime currentdate;
        age = Convert.ToInt32(txtageCurrentYears.Text);
        if (txtageCurrentMonths.Text != "")
        {
            currentdate = Convert.ToDateTime(Convert.ToDateTime(txtSysDate.Text).Month + "-01-" + Convert.ToDateTime(txtSysDate.Text).Year);
        }
        else
            currentdate = Convert.ToDateTime("06-15-" + Convert.ToDateTime(txtSysDate.Text).Year);

        DateTime birthdate = currentdate.AddYears(age * -1);
        if (txtageCurrentMonths.Text != "")
        {
            months = Convert.ToInt32(txtageCurrentMonths.Text);
            birthdate = birthdate.AddMonths(months * -1);
        }

        TxtDOB.Text = ((DateTime)birthdate).ToString(Session["AppDateFormat"].ToString());
        if (TxtDOB.Text != "")
        {
            rbtndobPrecEstimated.Checked = true;
        }
    }
}

