using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data;
using Application.Common;
using Application.Presentation;
using AjaxControlToolkit;
using Interface.SCM;
using System.Text;

namespace PresentationApp.PharmacyDispense
{
    public partial class frmPharmacy_StockManagement : LogPage
    {
        BindFunctions theBindManager = new BindFunctions();
        IDrug stockMgtManager;
        DataSet dsOpenStock;
        static string tranactionType;
        static string sourceType;
        StringBuilder batches = new StringBuilder();
        DataSet XMLDS;

        protected void Page_Load(object sender, EventArgs e)
        {
            stockMgtManager = (IDrug)ObjectFactory.CreateInstance("BusinessProcess.SCM.BDrug, BusinessProcess.SCM");
            (Master.FindControl("pnlExtruder") as Panel).Visible = false;
            (Master.FindControl("level2Navigation") as Control).Visible = true;
            //(Master.FindControl("levelTwoNavigationUserControl1").FindControl("lblformname") as Label).Text = "Stock Management";
            (Master.FindControl("levelTwoNavigationUserControl1").FindControl("patientLevelMenu") as Menu).Visible = false;
            (Master.FindControl("levelTwoNavigationUserControl1").FindControl("PharmacyDispensingMenu") as Menu).Visible = true;
            (Master.FindControl("levelTwoNavigationUserControl1").FindControl("UserControl_Alerts1") as UserControl).Visible = false;
            (Master.FindControl("levelTwoNavigationUserControl1").FindControl("PanelPatiInfo") as Panel).Visible = false;
            //(Master.FindControl("facilityBanner") as Control).Visible = false;
            //(Master.FindControl("patientBanner") as Control).Visible = false;
            //(Master.FindControl("username1") as Control).Visible = false;
            //(Master.FindControl("currentdate1") as Control).Visible = false;
            //(Master.FindControl("facilityName") as Control).Visible = false;
            //(Master.FindControl("imageFlipLevel2") as Control).Visible = false;
            if (!IsPostBack)
            {
                BindCombo();

                addAttributes();
            }

            //ScriptManager.RegisterStartupScript(this, this.GetType(), "showHide", "showHideTransactionType('" + ddlTransactionType.ClientID + "');", true);
            //ScriptManager.RegisterStartupScript(this, this.GetType(), "showHidesupplier", "showHideSupplierStore('" + ddlSourceStore.ClientID + "');", true);
            userRights();
        }

        private void userRights()
        {
            /***************** Check For User Rights ****************/
            AuthenticationManager Authentiaction = new AuthenticationManager();
            //btnPrint.Enabled = Authentiaction.HasFunctionRight(ApplicationAccess.AdultPharmacy, FunctionAccess.Print, (DataTable)Session["UserRight"]);


            if (Convert.ToInt32(Session["PatientVisitId"]) == 0)
            {
                btnSubmit.Enabled = Authentiaction.HasFunctionRight(ApplicationAccess.StockManagement, FunctionAccess.Add, (DataTable)Session["UserRight"]);

            }
            else if (Convert.ToInt32(Session["PatientVisitId"]) != 0)
            {
                if (Authentiaction.HasFunctionRight(ApplicationAccess.StockManagement, FunctionAccess.View, (DataTable)Session["UserRight"]) == false)
                {
                    if (Convert.ToInt32(Session["TechnicalAreaId"]) != 206)
                    {
                        string theUrl = "";
                        theUrl = string.Format("{0}", "../ClinicalForms/frmPatient_History.aspx");
                        Response.Redirect(theUrl);
                    }
                }

                btnSubmit.Enabled = Authentiaction.HasFunctionRight(ApplicationAccess.StockManagement, FunctionAccess.Update, (DataTable)Session["UserRight"]);

            }
        }

        private void addAttributes()
        {
            //ddlTransactionType.Attributes.Add("OnChange", "showHideTransactionType('" + ddlTransactionType.ClientID + "');");
            //ddlSourceStore.Attributes.Add("OnChange", "showHideSupplierStore('" + ddlSourceStore.ClientID + "');");
        }

        private void BindCombo()
        {
            try
            {
                XMLDS = new DataSet();
                XMLDS.ReadXml(MapPath("..\\XMLFiles\\AllMasters.con"));

                DataView theDV = new DataView(XMLDS.Tables["Mst_Store"]);
                theDV.RowFilter = "(DeleteFlag =0 or DeleteFlag is null)";
                theDV.Sort = "Name ASC";
                DataTable theStoreDT = theDV.ToTable();

                Session["theStoreDT"] = theStoreDT;

                theBindManager.BindCombo(ddlDestinationStore, theStoreDT, "Name", "Id");                
                theBindManager.BindCombo(ddlSourceStore, theStoreDT, "Name", "Id");
                DataView theDVSup = new DataView(XMLDS.Tables["Mst_Supplier"]);
                theDVSup.RowFilter = "(DeleteFlag =0 or DeleteFlag is null)";
                theDVSup.Sort = "SupplierName ASC";
                DataTable theSupDT = theDVSup.ToTable();
                theBindManager.BindCombo(ddlSupplier, theSupDT, "SupplierName", "Id");
            }
            catch (Exception err)
            {
                MsgBuilder theBuilder = new MsgBuilder();
                theBuilder.DataElements["MessageText"] = err.Message.ToString();
                IQCareMsgBox.Show("#C1", theBuilder, this);
            }

        }

        [System.Web.Script.Services.ScriptMethod()]
        [System.Web.Services.WebMethod]
        public static List<string> SearchDrugs(string prefixText, int count)
        {
            DataTable theDT = (DataTable)HttpContext.Current.Session["theStocks"];
            List<string> Drugsdetail = new List<string>();
            if(theDT!=null && theDT.Rows.Count>0)
            {
                DataTable distinctTable = theDT.AsEnumerable()
                       .GroupBy(x => x.Field<string>("drugname"))
                       .Select(g => g.First()).CopyToDataTable();
                var drugs = from DataRow tmp in distinctTable.AsEnumerable()
                            where tmp["DrugName"].ToString().ToLower().Contains(prefixText.ToLower())
                            select tmp; // new { drugName = tmp["DrugName"].ToString(), drugID = tmp["Drug_pk"].ToString() };

                foreach (DataRow c in drugs)
                {
                    if (tranactionType == "Opening Stock")
                    {
                        Drugsdetail.Add(AutoCompleteExtender.CreateAutoCompleteItem(c["drugname"].ToString(), c["drug_pk"].ToString()));
                    }
                    else if (sourceType == "Supplier")
                    {
                        Drugsdetail.Add(AutoCompleteExtender.CreateAutoCompleteItem(c["drugname"].ToString(), c["drug_pk"].ToString()));
                    }
                    else
                    {
                        StringBuilder test = new StringBuilder();
                        test.Append(c["drugname"].ToString());
                        test.Append("  -  ");
                        test.Append(c["BatchNo"].ToString());
                        test.Append("  -  ");
                        test.Append(c["AvailQty"].ToString().PadRight(20));
                        test.Append("  -  ");
                        test.Append(c["ExpiryDate"].ToString());
                        Drugsdetail.Add(AutoCompleteExtender.CreateAutoCompleteItem(test.ToString(), c["drug_pk"].ToString() + "," + c["BatchNo"].ToString()));
                        //Drugsdetail.Add(AutoCompleteExtender.CreateAutoCompleteItem(c["drugname"].ToString() + "  -------  " + c["BatchNo"].ToString() + "  -------  " + c["AvailQty"].ToString() + "  -------  " + c["ExpiryDate"].ToString(), c["drug_pk"].ToString() + "," + c["BatchNo"].ToString()));
                        //Drugsdetail.Add(AutoCompleteExtender.CreateAutoCompleteItem(c["drugname"].ToString() , c["drug_pk"].ToString() + "," + c["BatchNo"].ToString()));
                    }
                }
            }
            

            return Drugsdetail;
        }

        protected void ddlSourceStore_SelectedIndexChanged(object sender, EventArgs e)
        {
            try
            {
                if (Convert.ToInt32(ddlSourceStore.SelectedValue) != 0)
                {
                    if (ddlTransactionType.SelectedItem.Text == "Opening Stock")
                    {
                        Session["theStocks"] = GetItems_OpeningStock();
                        HideColumnsPO(0);
                        txtDrug.Enabled = true;

                        tblDestinationStore.Visible = false;
                        tblSupplier.Visible = false;
                        lblSourceStore.Text = "Store:";
                    }
                    else
                    {
                        if (ddlSourceStore.SelectedItem.Text != "Supplier")
                        {                           
                            Session["theStocks"] = GetItems(Convert.ToInt32(ddlSourceStore.SelectedValue),0);
                            sourceType = "";
                            HideColumnsPO(0);
                            txtDrug.Enabled = true;

                            tblDestinationStore.Visible = true;
                            tblSupplier.Visible = false;
                            lblSourceStore.Text = "Source Store:";
                            theBindManager.BindCombo(ddlDestinationStore, (DataTable)Session["theStoreDT"], "Name", "Id");

                            if (ddlTransactionType.SelectedItem.Text == "Adjustment")
                            {
                                tblDestinationStore.Visible = false;
                                tblSupplier.Visible = false;
                                lblSourceStore.Text = "Store:";
                            }
                        }
                        else if (ddlSourceStore.SelectedItem.Text == "Supplier" && ddlSourceStore.SelectedValue == "7777")
                        {
                            sourceType = "Supplier";
                            HideColumnsPO(1);

                            tblDestinationStore.Visible = true;
                            tblSupplier.Visible = true;
                            lblSourceStore.Text = "Source Store:";
                        }
                    }
                }
                else
                {
                    //txtItemName.Text = "";
                    grdStockMngt.Columns.Clear();
                    grdStockMngt.DataSource = null;
                }

            }
            catch (Exception err)
            {
                MsgBuilder theBuilder = new MsgBuilder();
                theBuilder.DataElements["MessageText"] = err.Message.ToString();
                IQCareMsgBox.Show("#C1", theBuilder, this);
                //IQCareWindowMsgBox.ShowWindowConfirm("#C1", theBuilder, this);
            }
        }

        private DataTable GetItems(int StoreId, int SupplierFlag)//If Supplier then SupplerFlag=1 else 0
        {
            ISCMReport objOpenStock = (ISCMReport)ObjectFactory.CreateInstance("BusinessProcess.SCM.BSCMReport,BusinessProcess.SCM");
            return objOpenStock.GetStocksPerStore(StoreId, SupplierFlag);
        }

        private DataTable GetItems_OpeningStock()
        {
            //IMasterList objOpenStock = (IMasterList)ObjectFactory.CreateInstance("BusinessProcess.SCM.BMasterList,BusinessProcess.SCM");
            IPurchase objOpenStock = (IPurchase)ObjectFactory.CreateInstance("BusinessProcess.SCM.BPurchase,BusinessProcess.SCM");
            dsOpenStock = objOpenStock.GetOpenStockWeb(Convert.ToInt32(ddlSourceStore.SelectedValue.ToString()));

            DataView theDV = new DataView(dsOpenStock.Tables[0]);
            theDV.RowFilter = "StoreID='" + Convert.ToInt32(ddlSourceStore.SelectedValue.ToString()) + "'";

            DataTable batcheDT = dsOpenStock.Tables[1];
            if (batcheDT.Rows.Count > 0)
            {
                for (int i = 0; i < batcheDT.Rows.Count; i++)
                {
                    batches.Append(batcheDT.Rows[i]["Name"].ToString().ToLower());
                    batches.Append(",");
                }
                ViewState["batches"] = batches;
            }

            DataView theDVOS = new DataView(dsOpenStock.Tables[2]);
            theDVOS.RowFilter = "StoreID='" + Convert.ToInt32(ddlSourceStore.SelectedValue.ToString()) + "'";
            ViewState["ExistingOpeningStocks"] = theDVOS.ToTable();

            return theDV.ToTable();
        }


        protected void grdStockMngt_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType == DataControlRowType.DataRow)
            {
                //string item = e.Row.Cells[0].Text;
                
                //TextBox txtQuantity = (TextBox)e.Row.FindControl("txtQuantity");
                //txtQuantity.Attributes.Add("onkeyup", "chkNumeric('" + txtQuantity.ClientID + "')");

                DataRowView row = (e.Row.DataItem as DataRowView);
                foreach (ImageButton button in e.Row.Cells[7].Controls.OfType<ImageButton>())
                {
                    if (button.CommandName == "Delete")
                    {
                        button.Attributes["onclick"] = "if(!confirm('Do you want to delete " + row["DrugName"].ToString() + "?')) { return false; };";
                    }
                }
                if (sourceType != "Supplier")
                {
                    foreach (TextBox txt in e.Row.Cells[2].Controls.OfType<TextBox>())
                    {
                        TextBox txtBatchNo = (TextBox)e.Row.FindControl("txtBatchNo");

                        txt.Attributes["onBlur"] = "DuplicateBatchNo(this.value,'" + ViewState["batches"] + "','" + txtBatchNo.ClientID + "');";

                    }
                    RangeValidator rng = e.Row.FindControl("qtyRangeValidator") as RangeValidator;
                    if (rng != null)
                    {
                        if (ddlTransactionType.SelectedItem.Text == "Receive")
                        {
                            rng.MaximumValue = row["AvailQty"].ToString();
                            rng.Enabled = true;
                        }
                    }
                    RequiredFieldValidator batchNoRequired = e.Row.FindControl("BatchNoRequiredFieldValidator") as RequiredFieldValidator;
                    if (batchNoRequired != null)
                    {
                        batchNoRequired.Enabled = true;
                    }  
                }
            }

            if ((ddlTransactionType.SelectedItem.Text == "Opening Stock") )
            {
                e.Row.Cells[4].Visible = false;
                e.Row.Cells[6].Visible = false;

                RequiredFieldValidator batchNoRequired = e.Row.FindControl("BatchNoRequiredFieldValidator") as RequiredFieldValidator;
                if (batchNoRequired != null)
                {
                    batchNoRequired.Enabled = true;
                }  
            }

            
        }
        private Boolean FieldValidation()
        {
            DateTime Test;
            
            if (ddlTransactionType.SelectedValue == "0")
            {
                MsgBuilder theBuilder = new MsgBuilder();
                EventArgs e = new EventArgs();
                theBuilder.DataElements["Control"] = "Transaction Type";
                IQCareMsgBox.Show("BlankDropDown", theBuilder, this);
                ddlTransactionType.Focus();
                return false;
            }
            else if (txtTransactionDate.Value == "")
            {
                MsgBuilder theBuilder = new MsgBuilder();
                EventArgs e = new EventArgs();
                theBuilder.DataElements["Control"] = "Transaction Date";
                IQCareMsgBox.Show("BlankTextBox", theBuilder, this);
                txtTransactionDate.Focus();
                return false;
            }
            if (!DateTime.TryParseExact(txtTransactionDate.Value, "dd-MMM-yyyy", null, System.Globalization.DateTimeStyles.AllowWhiteSpaces, out Test))            
            {
                MsgBuilder theBuilder = new MsgBuilder();
                theBuilder.DataElements["Control"] = "Transaction Date";
                IQCareMsgBox.Show("WrongDateFormat", theBuilder, this);                
                txtTransactionDate.Focus();
                return false;
            }
            else if (Convert.ToDateTime(Application["AppCurrentDate"].ToString()) < Convert.ToDateTime(txtTransactionDate.Value))
            {
                MsgBuilder theBuilder = new MsgBuilder();
                theBuilder.DataElements["MessageText"] = "Transaction Date cannot be greater than today's date.";
                IQCareMsgBox.Show("#C1", theBuilder, this); 
                txtTransactionDate.Focus();
                return false;
            }
            else if (ddlSourceStore.SelectedValue == "0")
            {
                MsgBuilder theBuilder = new MsgBuilder();
                EventArgs e = new EventArgs();
                theBuilder.DataElements["Control"] = "Source Store";
                IQCareMsgBox.Show("BlankDropDown", theBuilder, this);
                ddlSourceStore.Focus();
                return false;
            }
            else if (ddlDestinationStore.SelectedValue == "0" && ddlTransactionType.SelectedItem.Text == "Receive")
            {
                MsgBuilder theBuilder = new MsgBuilder();
                EventArgs e = new EventArgs();
                theBuilder.DataElements["Control"] = "Destination Store";
                IQCareMsgBox.Show("BlankDropDown", theBuilder, this);
                ddlDestinationStore.Focus();
                return false;
            }
            IQCareMsgBox.HideMessage(this);
            return true;
        }
        protected string ShowTextBox()
        {
            if (ddlTransactionType.SelectedItem.Text == "Opening Stock")
            {
                return "";
            }
            else if (sourceType == "Supplier")
            {
                return "";
            }
            return "none";
        }
        protected string ShowLabel()
        {
            if (ddlTransactionType.SelectedItem.Text == "Opening Stock")
            {
                return "none";
            }
            else if (sourceType == "Supplier")
            {
                return "none";
            }
            return "";
        }
        protected void txtDrug_TextChanged(object sender, EventArgs e)
        {
            try
            {
                DataView theDV = new DataView((DataTable)Session["theStocks"]);

                if (hdCustID.Value != "")
                {
                    if (ddlTransactionType.SelectedItem.Text == "Opening Stock")
                    {
                        string[] details = hdCustID.Value.Split(',');
                        theDV.RowFilter = "Drug_Pk = " + details[0].ToString();
                    }
                    else
                    {
                        string[] details = hdCustID.Value.Split(',');
                        if ((ddlTransactionType.SelectedItem.Text == "Receive") && (ddlSourceStore.SelectedItem.Text == "Supplier"))
                        {
                            theDV.RowFilter = "Drug_Pk = " + details[0].ToString();
                        }
                        else
                        {
                            theDV.RowFilter = "Drug_Pk = " + details[0].ToString() + " and BatchNo = '" + details[1].ToString() + "'";
                        }
                    }

                    if (theDV.ToTable().Rows.Count > 0)
                        PopulateGrid(theDV.ToTable().Rows[0]);
                }
            }
            catch (Exception ex)
            {
                MsgBuilder theBuilder = new MsgBuilder();
                theBuilder.DataElements["MessageText"] = ex.Message.ToString();
                IQCareMsgBox.Show("#C1", theBuilder, this);
            }
            finally
            {


                txtDrug.Text = "";
            }
        }

        private void HideColumnsPO(int SupplierFlag)
        {
            if (SupplierFlag == 1)
            {
                //Hide columns
                grdStockMngt.Columns[1].HeaderStyle.CssClass = "hidden"; //Unit
                grdStockMngt.Columns[1].ItemStyle.CssClass = "hidden";
                //grdStockMngt.Columns[2].HeaderStyle.CssClass = "hidden"; //Batch No
                //grdStockMngt.Columns[2].ItemStyle.CssClass = "hidden";
                //grdStockMngt.Columns[3].HeaderStyle.CssClass = "hidden"; //Expiry date
                //grdStockMngt.Columns[3].ItemStyle.CssClass = "hidden";
                grdStockMngt.Columns[7].HeaderStyle.CssClass = "hidden"; //Avaiable Qty
                grdStockMngt.Columns[7].ItemStyle.CssClass = "hidden";

                grdStockMngt.Columns[5].HeaderStyle.CssClass = ""; //Purchase Unit
                grdStockMngt.Columns[5].ItemStyle.CssClass = "";
                grdStockMngt.Columns[6].HeaderStyle.CssClass = ""; //Qty Purcahse Unit 
                grdStockMngt.Columns[6].ItemStyle.CssClass = "";

            }
            else 
            { 
                //show columns
                grdStockMngt.Columns[1].HeaderStyle.CssClass = ""; //Unit
                grdStockMngt.Columns[1].ItemStyle.CssClass = "";
                grdStockMngt.Columns[2].HeaderStyle.CssClass = ""; //Batch No
                grdStockMngt.Columns[2].ItemStyle.CssClass = "";
                //grdStockMngt.Columns[3].HeaderStyle.CssClass = ""; //Expiry date
                //grdStockMngt.Columns[3].ItemStyle.CssClass = "";
                grdStockMngt.Columns[7].HeaderStyle.CssClass = ""; //Avaiable Qty
                grdStockMngt.Columns[7].ItemStyle.CssClass = "";

                grdStockMngt.Columns[5].HeaderStyle.CssClass = "hidden"; //Purchase Unit
                grdStockMngt.Columns[5].ItemStyle.CssClass = "hidden";
                grdStockMngt.Columns[6].HeaderStyle.CssClass = "hidden"; //Qty Purcahse Unit 
                grdStockMngt.Columns[6].ItemStyle.CssClass = "hidden";
                
            }
            

        }
        private void PopulateGrid(DataRow SelectedDrug)
        {
            DataTable dt = new DataTable();
            dt.Columns.Add(new DataColumn("Drug_pk", typeof(int)));
            dt.Columns.Add(new DataColumn("DrugName", typeof(string)));
            dt.Columns.Add(new DataColumn("BatchNo", typeof(string)));
            dt.Columns.Add(new DataColumn("ExpiryDate", typeof(string)));
            dt.Columns.Add(new DataColumn("Unit", typeof(string)));
            dt.Columns.Add(new DataColumn("AvailQty", typeof(int)));
            dt.Columns.Add(new DataColumn("Quantity", typeof(string)));
            dt.Columns.Add(new DataColumn("Comments", typeof(string)));
            dt.Columns.Add(new DataColumn("BatchID", typeof(int)));
            dt.Columns.Add(new DataColumn("PurchaseUnitPrice", typeof(double)));
            dt.Columns.Add(new DataColumn("QtyPerPurchaseUnit", typeof(int)));
            dt.Columns.Add(new DataColumn("PurchaseUnit", typeof(string)));
            DataRow dr;
            
            //Add existing data to data table
            foreach (GridViewRow gvRow in grdStockMngt.Rows)
            {
                int DrugID = Convert.ToInt32(grdStockMngt.DataKeys[gvRow.RowIndex].Value);
                Label lblDrugName = (Label)gvRow.FindControl("lblDrugName");
                Label lblUnit = (Label)gvRow.FindControl("lblUnit");
                Label lblBatchNo = (Label)gvRow.FindControl("lblBatchNo");
                Label lblExpiryDate = (Label)gvRow.FindControl("lblExpiryDate");
                TextBox txtBatchNo = (TextBox)gvRow.FindControl("txtBatchNo");
                TextBox txtExpiryDate = (TextBox)gvRow.FindControl("txtExpiryDate");
                Label lblAvailQty = (Label)gvRow.FindControl("lblAvailQty");
                TextBox txtQty = (TextBox)gvRow.FindControl("txtQuantity");
                TextBox txtComments = (TextBox)gvRow.FindControl("txtComments");
                Label lblBatchID = (Label)gvRow.FindControl("lblBatchID");
                Label lblPurchaseUnitPrice = (Label)gvRow.FindControl("lblPurchaseUnitPrice");
                Label lblQtyPerPurchaseUnit = (Label)gvRow.FindControl("lblQtyPerPurchaseUnit");
                Label lblPurchaseUnit = (Label)gvRow.FindControl("lblPurchaseUnit");

                dr = dt.NewRow();
                dr["Drug_pk"] = DrugID;
                dr["DrugName"] = lblDrugName.Text;
                dr["Unit"] = lblUnit.Text;

                if (ddlTransactionType.SelectedItem.Text == "Opening Stock")
                {
                    dr["BatchNo"] = txtBatchNo.Text;
                    dr["ExpiryDate"] = txtExpiryDate.Text;
                }
                else
                {
                    dr["BatchNo"] = lblBatchNo.Text;
                    dr["ExpiryDate"] = lblExpiryDate.Text;
                }
                dr["AvailQty"] = lblAvailQty.Text;
                dr["Quantity"] = txtQty.Text;
                dr["Comments"] = txtComments.Text;
                dr["BatchID"] = lblBatchID.Text;
                dr["PurchaseUnitPrice"] = lblPurchaseUnitPrice.Text;
                dr["QtyPerPurchaseUnit"] = lblQtyPerPurchaseUnit.Text;
                dr["PurchaseUnit"] = lblPurchaseUnit.Text;
                dt.Rows.Add(dr);
            }

            //Add the new data to datatable
            int OpeningStockExists = 0;
            if (ddlTransactionType.SelectedItem.Text == "Opening Stock")
            {
                DataView theDV = new DataView((DataTable)ViewState["ExistingOpeningStocks"]);
                theDV.RowFilter = "ItemID = " + SelectedDrug["Drug_pk"].ToString();

                if (theDV.ToTable().Rows.Count > 0)
                {
                    OpeningStockExists = 1;
                }
            }

            if (OpeningStockExists == 0)
            {
                DataRow[] result;
                if (ddlTransactionType.SelectedItem.Text == "Opening Stock")
                {
                    result = dt.Select("Drug_pk = " + SelectedDrug["Drug_pk"].ToString());
                }
                else
                {
                    if (ddlTransactionType.SelectedItem.Text == "Receive" && ddlSourceStore.SelectedItem.Text == "Supplier" && Convert.ToInt32(ddlSupplier.SelectedValue) > 0)
                    {
                        result = dt.Select("Drug_pk = " + SelectedDrug["Drug_pk"].ToString());
                    }
                    else
                        result = dt.Select("Drug_pk = " + SelectedDrug["Drug_pk"].ToString() + " and BatchID = " + SelectedDrug["BatchID"].ToString());
                }

                if (result.Length == 0)
                {
                    dr = dt.NewRow();
                    dr["Drug_pk"] = SelectedDrug["Drug_pk"].ToString();
                    dr["DrugName"] = SelectedDrug["DrugName"].ToString();
                    dr["BatchNo"] = SelectedDrug["BatchNo"].ToString();
                    dr["ExpiryDate"] = SelectedDrug["ExpiryDate"].ToString();
                    dr["Unit"] = SelectedDrug["Unit"].ToString();
                    dr["AvailQty"] = SelectedDrug["AvailQty"].ToString();
                    dr["BatchID"] = SelectedDrug["BatchID"].ToString();
                    dr["PurchaseUnitPrice"] = SelectedDrug["PurchaseUnitPrice"].ToString();
                    dr["QtyPerPurchaseUnit"] = SelectedDrug["QtyPerPurchaseUnit"].ToString();
                    dr["PurchaseUnit"] = SelectedDrug["PurchaseUnit"].ToString();
                    dt.Rows.Add(dr);
                }
                else
                {
                    ScriptManager.RegisterStartupScript(this, this.GetType(), "DuplicateRecord", "NotifyMessage('Record already added to grid.');", true);
                    //Page.ClientScript.RegisterStartupScript(this.GetType(), "DuplicateRecord", "alert('Record already added.');", true);
                }
            }
            else
            {
                ScriptManager.RegisterStartupScript(this, this.GetType(), "OpeningStockExist", "NotifyMessage('Opening stock for " + SelectedDrug["DrugName"].ToString() + " exists.');", true);
            }
            

            //Populate grid
            ViewState["dt"] = dt;
            populateGrid();
        }

        protected void grdStockMngt_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
            int index = Convert.ToInt32(e.RowIndex);
            DataTable dt = ViewState["dt"] as DataTable;
            dt.Rows[index].Delete();
            ViewState["dt"] = dt;

            populateGrid();
        }

        protected void populateGrid()
        {
            grdStockMngt.DataSource = ViewState["dt"] as DataTable;
            grdStockMngt.DataBind();
        }

        protected void SaveData()
        {
            if (FieldValidation())
            {
                IPurchase objMasterlist = (IPurchase)ObjectFactory.CreateInstance("BusinessProcess.SCM.BPurchase,BusinessProcess.SCM");
                int iTransactionType = 0;

                //Transaction Type
                if (ddlTransactionType.SelectedItem.Text == "Opening Stock")
                {
                    iTransactionType = 1;
                }
                else if (ddlTransactionType.SelectedItem.Text == "Receive" && ddlSourceStore.SelectedItem.Text == "Supplier")
                {
                    iTransactionType = 2;
                }
                else if (ddlTransactionType.SelectedItem.Text == "Receive" && ddlSourceStore.SelectedItem.Text != "Supplier")
                {
                    iTransactionType = 3;
                }
                else if (ddlTransactionType.SelectedItem.Text == "Receive" && ddlSourceStore.SelectedItem.Text != "Supplier")
                {
                    iTransactionType = 4;
                }
                else if (ddlTransactionType.SelectedItem.Text == "Adjustment")
                {
                    iTransactionType = 5;
                }

                DateTime TransactionDate = Convert.ToDateTime(txtTransactionDate.Value);
                string orderNo = txtOrderNumber.Text;
                int sourcestore = Convert.ToInt16(ddlSourceStore.SelectedItem.Value);
                int destinationstore = Convert.ToInt16(ddlDestinationStore.SelectedItem.Value);
                int supplier = Convert.ToInt16(ddlSupplier.SelectedItem.Value);

                foreach (GridViewRow gvRow in grdStockMngt.Rows)
                {
                    Label lblDrugName = (Label)gvRow.FindControl("lblDrugName");
                    Label lblUnit = (Label)gvRow.FindControl("lblUnit");
                    Label lblBatchID = (Label)gvRow.FindControl("lblBatchID");
                    TextBox txtBatchNo = (TextBox)gvRow.FindControl("txtBatchNo");
                    Label lblExpiryDate = (Label)gvRow.FindControl("lblExpiryDate");
                    Label lblAvailQty = (Label)gvRow.FindControl("lblAvailQty");
                    TextBox txtQty = (TextBox)gvRow.FindControl("txtQuantity");
                    TextBox txtExpiryDate = (TextBox)gvRow.FindControl("txtExpiryDate");
                    Label lblPurchaseUnitPrice = (Label)gvRow.FindControl("lblPurchaseUnitPrice");
                    Label lblQtyPerPurchaseUnit = (Label)gvRow.FindControl("lblQtyPerPurchaseUnit");
                    TextBox txtComments = (TextBox)gvRow.FindControl("txtComments");
                    int DrugID = Convert.ToInt32(grdStockMngt.DataKeys[gvRow.RowIndex].Value);

                    if (iTransactionType == 1) //Set Opening Stock
                    {
                        objMasterlist.SaveStockTransaction(DrugID, TransactionDate, iTransactionType, sourcestore, 0, 0, Convert.ToInt32(txtQty.Text), txtBatchNo.Text, Convert.ToDateTime(txtExpiryDate.Text), 0, 1);
                    }
                    else if (iTransactionType == 2) //Receive from Supplier
                    {
                        int iQtyPerPurchaseUnit = Convert.ToInt32(lblQtyPerPurchaseUnit.Text);
                        objMasterlist.SaveStockTransaction(DrugID, TransactionDate, iTransactionType, destinationstore, sourcestore, supplier, Convert.ToInt32(txtQty.Text) * iQtyPerPurchaseUnit, txtBatchNo.Text, Convert.ToDateTime(txtExpiryDate.Text), 0, 1);
                    }
                    else if (iTransactionType == 3) //Receive from Bulk Store
                    {
                        objMasterlist.SaveStockTransaction(DrugID, TransactionDate, iTransactionType, destinationstore, sourcestore, 0, Convert.ToInt32(txtQty.Text), txtBatchNo.Text, Convert.ToDateTime(txtExpiryDate.Text), 0, 1);
                    }
                    else if (iTransactionType == 4) //Inter Dispensing Store Transfer
                    {
                        objMasterlist.SaveStockTransaction(DrugID, TransactionDate, iTransactionType, destinationstore, sourcestore, 0, Convert.ToInt32(txtQty.Text), txtBatchNo.Text, Convert.ToDateTime(txtExpiryDate.Text), 0, 1);
                    }
                    else if (iTransactionType == 5) //Adjust stock
                    {
                        objMasterlist.SaveStockTransaction(DrugID, TransactionDate, iTransactionType, sourcestore, 0, 0, Convert.ToInt32(txtQty.Text), txtBatchNo.Text, Convert.ToDateTime(txtExpiryDate.Text), 0, 1);
                    }
                }

                IQCareMsgBox.NotifyAction("Saved successfully.", "Stock Management", false, this, "");
            clearFields();
            }
        }

        protected void btnSubmit_Click(object sender, EventArgs e)
        {
            try
            {
                SaveData();
            }
            catch (Exception ex)
            {
            }
        }

        protected void clearFields()
        {
            grdStockMngt.DataSource = "";
            grdStockMngt.DataBind();
            ddlTransactionType.SelectedValue = "0";
            ddlSourceStore.SelectedValue = "0";
            ddlDestinationStore.SelectedValue = "0";
            txtTransactionDate.Value = "";
            txtOrderNumber.Text = "";
        }

        private DataTable CreateOrderMasterTable()
        {
            DataTable dtOrdermaster = new DataTable();
            dtOrdermaster.Columns.Add("IsPO", typeof(int));
            dtOrdermaster.Columns.Add("POID", typeof(int));
            dtOrdermaster.Columns.Add("OrderDate", typeof(string));
            dtOrdermaster.Columns.Add("SupplierID", typeof(int));
            dtOrdermaster.Columns.Add("SrcStore", typeof(int));
            dtOrdermaster.Columns.Add("DestStore", typeof(int));
            dtOrdermaster.Columns.Add("UserID", typeof(int));
            dtOrdermaster.Columns.Add("PreparedBy", typeof(int));
            dtOrdermaster.Columns.Add("AthorizedBy", typeof(int));
            dtOrdermaster.Columns.Add("LocationID", typeof(int));
            dtOrdermaster.Columns.Add("IsRejectedStatus", typeof(int));
            return dtOrdermaster;
        }
        private DataTable CreateOrderItemTable()
        {
            DataTable dtOrderItem = new DataTable();
            dtOrderItem.Columns.Add("ItemID", typeof(int));
            dtOrderItem.Columns.Add("ItemName", typeof(String));
            dtOrderItem.Columns.Add("PurchaseUnit", typeof(int));
            dtOrderItem.Columns.Add("Quantity", typeof(int));
            dtOrderItem.Columns.Add("priceperunit", typeof(decimal));
            dtOrderItem.Columns.Add("totPrice", typeof(int));
            dtOrderItem.Columns.Add("BatchID", typeof(int));
            dtOrderItem.Columns.Add("AvaliableQty", typeof(int));
            dtOrderItem.Columns.Add("ExpiryDate", typeof(string));
            dtOrderItem.Columns.Add("UnitQuantity", typeof(int));
            //dtOrderItem.Columns.Add("Delete", typeof(String));
            // dtOrderItem.Columns.Add("IsFunded", typeof(int));
            return dtOrderItem;
        }

        private DataTable CreateGRNMasterTable()
        {

            DataTable dtGRNmaster = new DataTable();
            dtGRNmaster.Columns.Add("POID", typeof(int));
            dtGRNmaster.Columns.Add("GRNId", typeof(int));
            dtGRNmaster.Columns.Add("LocationID", typeof(int));
            dtGRNmaster.Columns.Add("OrderDate", typeof(string));
            dtGRNmaster.Columns.Add("SupplierID", typeof(int));
            dtGRNmaster.Columns.Add("SourceStoreID", typeof(int));
            dtGRNmaster.Columns.Add("DestinStoreID", typeof(int));
            dtGRNmaster.Columns.Add("UserID", typeof(int));
            dtGRNmaster.Columns.Add("RecievedDate", typeof(string));
            dtGRNmaster.Columns.Add("OrderNo", typeof(String));
            dtGRNmaster.Columns.Add("Freight", typeof(decimal));
            dtGRNmaster.Columns.Add("Tax", typeof(decimal));
            return dtGRNmaster;
        }

        private DataTable CreateGRNItemTable()
        {
            DataTable dtGRNItem = new DataTable();
            dtGRNItem.Columns.Add("AutoID", typeof(int));
            dtGRNItem.Columns.Add("GRNId", typeof(int));
            dtGRNItem.Columns.Add("ItemID", typeof(int));
            dtGRNItem.Columns.Add("BatchID", typeof(int));
            dtGRNItem.Columns.Add("BatchName", typeof(String));
            dtGRNItem.Columns.Add("RecievedQuantity", typeof(int));
            dtGRNItem.Columns.Add("QtyPerPurchaseUnit", typeof(int));
            dtGRNItem.Columns.Add("FreeRecievedQuantity", typeof(int));
            dtGRNItem.Columns.Add("ItemPurchasePrice", typeof(decimal));
            dtGRNItem.Columns.Add("TotPurchasePrice", typeof(decimal));
            dtGRNItem.Columns.Add("MasterPurchaseprice", typeof(decimal));
            dtGRNItem.Columns.Add("Margin", typeof(decimal));
            dtGRNItem.Columns.Add("SellingPrice", typeof(decimal));
            dtGRNItem.Columns.Add("SellingPricePerDispense", typeof(decimal));
            dtGRNItem.Columns.Add("ExpiryDate", typeof(string));
            dtGRNItem.Columns.Add("UserID", typeof(int));
            dtGRNItem.Columns.Add("POId", typeof(int));
            dtGRNItem.Columns.Add("SourceStoreID", typeof(int));
            dtGRNItem.Columns.Add("DestinStoreID", typeof(int));
            dtGRNItem.Columns.Add("Comments", typeof(string));
            if (GblIQCare.ModePurchaseOrder == 2)
            {
                dtGRNItem.Columns.Add("ISTItemID", typeof(String));
            }
            return dtGRNItem;
        }

        private DataTable CreateAdjustStockTable()
        {
            DataTable dtAdjStock = new DataTable();
            dtAdjStock.Columns.Add("ItemID", typeof(int));
            dtAdjStock.Columns.Add("BatchID", typeof(int));
            dtAdjStock.Columns.Add("ExpiryDate", typeof(string));
            dtAdjStock.Columns.Add("StoreID", typeof(int));
            dtAdjStock.Columns.Add("AdjQty", typeof(int));
            dtAdjStock.Columns.Add("Comments", typeof(string));
            return dtAdjStock;
        }

        private DataTable CreateOpeningStockTable()
        {
            DataTable dtOS = new DataTable();
            dtOS.Columns.Add("ItemID", typeof(int));
            dtOS.Columns.Add("BatchNo", typeof(string));
            dtOS.Columns.Add("ExpiryDate", typeof(string));
            dtOS.Columns.Add("StoreID", typeof(int));
            dtOS.Columns.Add("Quantity", typeof(int));
            dtOS.Columns.Add("Comments", typeof(string));
            return dtOS;
        }

        protected void ddlTransactionType_SelectedIndexChanged(object sender, EventArgs e)
        {
            tranactionType = ddlTransactionType.SelectedItem.Text;
            grdStockMngt.DataSource = "";
            grdStockMngt.DataBind();
            XMLDS = new DataSet();
            XMLDS.ReadXml(MapPath("..\\XMLFiles\\AllMasters.con"));
            DataView theDV = new DataView(XMLDS.Tables["Mst_Store"]);
            theDV.RowFilter = "(DeleteFlag =0 or DeleteFlag is null)";
            theDV.Sort = "Name ASC";
            DataTable theStoreDT = theDV.ToTable();
            if (tranactionType == "Receive")
            {               
                DataRow dr = theStoreDT.NewRow();
                dr["Id"] = 7777;
                dr["Name"] = "Supplier";
                theStoreDT.Rows.Add(dr);
                theBindManager.BindCombo(ddlSourceStore, theStoreDT, "Name", "Id");

                tblDestinationStore.Visible = true;
                tblSupplier.Visible = false;
                lblSourceStore.Text = "Source Store:";
            }
            else
            {
                ddlSourceStore.DataSource = "";
                ddlSourceStore.DataBind();
                theBindManager.BindCombo(ddlSourceStore, theStoreDT, "Name", "Id");

                tblDestinationStore.Visible = false;
                tblSupplier.Visible = false;
                lblSourceStore.Text = "Store:";
            }

            ddlSourceStore.SelectedIndex = 0;
        }

        protected void grnDetails()
        {
            IPurchase objPODetails = (IPurchase)ObjectFactory.CreateInstance("BusinessProcess.SCM.BPurchase,BusinessProcess.SCM");
            DataTable theDTPODetails = objPODetails.GetPurchaseOrderDetailsForGRN(Convert.ToInt32(Session["AppUserID"].ToString()), Convert.ToInt32(ddlDestinationStore.SelectedValue), Convert.ToInt32(Session["AppLocationId"].ToString()));
        }

        protected void ddlSupplier_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (ddlSourceStore.SelectedItem.Text == "Supplier" && Convert.ToInt32(ddlSupplier.SelectedValue) > 0)
            {
                //IPurchase objSup = (IPurchase)ObjectFactory.CreateInstance("BusinessProcess.SCM.BPurchase,BusinessProcess.SCM");
                //IQCareUtils theUtils = new IQCareUtils();
                //DataTable theDT = objSup.GetStoreSourceDestination(Convert.ToInt32(ddlSupplier.SelectedValue));
                //ddlDestinationStore.Items.Clear();
                //theBindManager.BindCombo(ddlDestinationStore, theDT, "Name", "Id");
                //ddlDestinationStore.SelectedIndex = (ddlDestinationStore.Items.Count-1);
                Session["theStocks"] = GetItems(Convert.ToInt32(ddlSupplier.SelectedValue), 1);
                txtDrug.Enabled = true;
            }
        }
    }
}