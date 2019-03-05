
using System;
using System.Data;
using System.Configuration;
using System.Collections;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;
using Interface.Administration;
using Application.Common;
using Application.Presentation;
using Interface.SCM;

/////////////////////////////////////////////////////////////////////
// Code Written By   : Pankaj Kumar
// Code Modified By  : Sanjay Rana
// Written Date      : 25th July 2006
// Modification Date : 24th Nov 2006
// Description       : Drug Master
//
/// /////////////////////////////////////////////////////////////////

public partial class frmAdmin_Drug : LogPage
{
    Decimal MaxDose, MinDose;
    DataSet theMasterDS = new DataSet();
    DataTable theGenericTable = new DataTable();

    private Boolean FieldValidation()
    {
        MsgBuilder theBuilder = new MsgBuilder();

        if (ddlDrugType.SelectedValue == "0")
        {
            theBuilder.DataElements["Control"] = "Drug Type";
            EventArgs e = new EventArgs();
            IQCareMsgBox.Show("BlankTextBox", theBuilder, this);
            ddlDrugType.Focus();
            return false;
        }

        if (txtDrugName.Text == "")
        {
            theBuilder.DataElements["Control"] = "Trade Name";
            EventArgs e = new EventArgs();
            IQCareMsgBox.Show("BlankTextBox", theBuilder, this);
            return false;
        }

        return true;
    }

    private void clear_fields()
    {
        /********* Clear all form fields *********/
        txtDrugName.Text = "";
        txtPurchaseUnitQty.Text = "";
        ddlDrugType.ClearSelection();
        ddlDispensingUnit.ClearSelection();
        ddlPurchaseUnit.ClearSelection();
        txtDrugName.Focus();
    }

    private void Init_Page()
    {
        DataTable dt = new DataTable();

        if (Page.IsPostBack != true)
        {
            GetMasters();
            FillDropDowns();

            if (Request.QueryString["name"] == "Add")
            {
                lblH2.Text = "Add Drug";
                Session["ExistDrugId"] = 0;
            }

            else if (Request.QueryString["name"] == "Edit")
            {
                IDrugMst DrugManager;
                BindFunctions BindManager = new BindFunctions();
                lblH2.Text = "Edit Drug";
                int drug_pk = Convert.ToInt32(Request.QueryString["DrugId"]);
                Session["ExistDrugId"] = drug_pk;

                DrugManager = (IDrugMst)ObjectFactory.CreateInstance("BusinessProcess.Administration.BDrugMst, BusinessProcess.Administration");
                DataSet theDS = DrugManager.GetDrug(drug_pk);
                dt = theDS.Tables[0];

                ddlDrugType.SelectedValue = dt.Rows[0]["DrugTypeId"].ToString();
                txtDrugName.Text = dt.Rows[0]["DrugName"].ToString();
                txtDrugAbbre.Text = dt.Rows[0]["GenericAbbrevation"].ToString();
                ddlPurchaseUnit.SelectedValue = dt.Rows[0]["PurchaseUnit"].ToString();
                txtPurchaseUnitQty.Text = dt.Rows[0]["QtyPerPurchaseUnit"].ToString();
                ddlDispensingUnit.SelectedValue = dt.Rows[0]["DispensingUnit"].ToString();
                ddlIsSyrup.SelectedValue = dt.Rows[0]["Syrup"].ToString();
                ddStatus.Text = dt.Rows[0]["Status"].ToString();
            }
        }
    }

    protected void FillDropDowns()
    {
        try
        {
            BindFunctions BindManager = new BindFunctions();
            IMasterList objItemCommonlist = (IMasterList)ObjectFactory.CreateInstance("BusinessProcess.SCM.BMasterList,BusinessProcess.SCM");
            DataSet theDS = objItemCommonlist.GetItemDetails(Convert.ToInt32(0));
            DataSet DTItemlist = objItemCommonlist.GetDrugType(0);

            BindManager.BindCombo(ddlDrugType, DTItemlist.Tables[1], "DrugTypeName", "drugTypeID");
            BindManager.BindCombo(ddlPurchaseUnit, theDS.Tables[3].Copy(), "Name", "Id");
            BindManager.BindCombo(ddlDispensingUnit, theDS.Tables[3].Copy(), "Name", "Id");
        }
        catch (Exception err)
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["MessageText"] = err.Message.ToString();
            IQCareMsgBox.Show("#C1", theBuilder, this);
            return;
        }
    }

    private void GetMasters()
    {
        IDrugMst DrugManager;
        try
        {
            DataSet theDSXML = new DataSet();
            theDSXML.ReadXml(MapPath("..\\XMLFiles\\DrugMasters.con"));
            if (theDSXML.Tables["Mst_DrugType"] != null)//10Mar08 -- put conditios
            {
                DataView theDrugTypeView = new DataView(theDSXML.Tables["Mst_DrugType"].Copy());
                theDrugTypeView.Sort = "DrugTypeName asc";
                theMasterDS.Tables.Add(theDrugTypeView.ToTable()); // table 0

                DrugManager = (IDrugMst)ObjectFactory.CreateInstance("BusinessProcess.Administration.BDrugMst, BusinessProcess.Administration");
                DataSet theDS = new DataSet();
                theDS = (DataSet)DrugManager.GetAllDropDowns();//pr_Admin_GetDrugDropDowns_Constella //all GenID,GenName,GenAbbr,DrugTypeID,DelFlag

                DataView theDV;
                DataTable theDT;
                // incase of add OR Active 
                if ((Request.QueryString["Status"] == null)||(Request.QueryString["Status"].ToString() == "Active"))
                {
                    theDV = new DataView(theDS.Tables[0]); 
                    theDV.RowFilter = "DeleteFlag=0";
                    theDT = theDV.Table;
                    theMasterDS.Tables.Add(theDT.Copy());//get only active generics  // table 1
                }
                else if (Request.QueryString["Status"].ToString() == "InActive")
                     theMasterDS.Tables.Add(theDS.Tables[0].Copy()); // get list of all generics // table 1
                
                theMasterDS.Tables.Add(theDSXML.Tables["Mst_Strength"].Copy()); // table 2
                theMasterDS.Tables.Add(theDSXML.Tables["Mst_Frequency"].Copy()); // table 3
                theMasterDS.Tables.Add(theDSXML.Tables["Mst_DrugSchedule"].Copy()); // table 4
            }
        }
        catch (Exception err)
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["MessageText"] = err.Message.ToString();
            IQCareMsgBox.Show("#C1", theBuilder, this);

        }
        finally
        {
            DrugManager = null;
        }
    }

    protected void Page_Init(object Sender, EventArgs e)
    {
        if (Session["AppLocation"] == null || Session.Count == 0 || Session["AppUserID"].ToString() == "")
        {
            IQCareMsgBox.Show("SessionExpired", this);
            Response.Redirect("~/frmlogin.aspx", true);
        }

        Init_Page();
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["AppLocation"] == null || Session.Count == 0 || Session["AppUserID"].ToString() == "")
        {
            IQCareMsgBox.Show("SessionExpired", this);
            Response.Redirect("~/frmlogin.aspx",true);
        }

        AuthenticationManager Authentication = new AuthenticationManager();
        if (Authentication.HasFunctionRight(22, FunctionAccess.Update, (DataTable)Session["UserRight"]) == false)
        {
            btnSave.Enabled = false;
        }
    }

    protected void btnSave_Click(object sender, EventArgs e)
    {
        if (FieldValidation() == false)
        {
            return;
        }

        int DrugId = 0;
        int ExistDrugId = Convert.ToInt32(Session["ExistDrugId"]);
        DataTable theExistGeneric = new DataTable();
        DataTable theStrengthDT = new DataTable();
        DataTable theFrequencyDT = new DataTable();
        DataTable theScheduleDT = new DataTable();
        try
        {
            IDrugMst DrugManager = (IDrugMst)ObjectFactory.CreateInstance("BusinessProcess.Administration.BDrugMst, BusinessProcess.Administration");
            int theDrugTypeID = Convert.ToInt32(ddlDrugType.SelectedValue);

            if (Request.QueryString["name"] == "Add")
            {
                DrugId = (int)DrugManager.SaveUpdateDrugDetails(0, txtDrugName.Text, txtDrugAbbre.Text, Convert.ToInt32(ddlPurchaseUnit.SelectedValue), Convert.ToInt32(txtPurchaseUnitQty.Text), 
                    Convert.ToInt32(ddlDispensingUnit.SelectedItem.Value), Convert.ToInt32(ddlIsSyrup.SelectedValue), Convert.ToInt32(ddStatus.SelectedItem.Value), Convert.ToInt32(ddlDrugType.SelectedItem.Value), 1);
            }
            else if (Request.QueryString["name"] == "Edit")
            {
                theExistGeneric = (DataTable)ViewState["SelGeneric"];
                ExistDrugId = Convert.ToInt32(Request.QueryString["DrugId"]);
                DrugId = (int)DrugManager.SaveUpdateDrugDetails(ExistDrugId, txtDrugName.Text, txtDrugAbbre.Text, Convert.ToInt32(ddlPurchaseUnit.SelectedValue), Convert.ToInt32(txtPurchaseUnitQty.Text),
                    Convert.ToInt32(ddlDispensingUnit.SelectedItem.Value), Convert.ToInt32(ddlIsSyrup.SelectedValue), Convert.ToInt32(ddStatus.SelectedItem.Value), Convert.ToInt32(ddlDrugType.SelectedItem.Value), 1);
            }
            
            btn_Click(sender, e); 
        }
        catch (Exception err)
        {
            MsgBuilder theBuilder = new MsgBuilder();
            theBuilder.DataElements["MessageText"] = err.Message.ToString();
            IQCareMsgBox.Show("#C1",theBuilder, this);
            return;
        }
     }
    
    protected void btnCancel_Click(object sender, EventArgs e)
    {
        string url = "frmAdmin_Druglist.aspx";
        Response.Redirect(url);
    }

    protected void btn_Click(object sender, EventArgs e)
    {
        string url = "frmAdmin_Druglist.aspx";
        Response.Redirect(url);
    }
}
