using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data;
using Interface.Laboratory;
using Application.Presentation;

namespace PresentationApp.Laboratory
{
    public partial class frmLaboratoryHome : System.Web.UI.Page
    {
        ILabFunctions labManager;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                labManager = (Interface.Laboratory.ILabFunctions)ObjectFactory.CreateInstance("BusinessProcess.Laboratory.BLabFunctions, BusinessProcess.Laboratory");
                DataSet dt = labManager.GetPendingLabOrders();

                gvLabOrders.DataSource = dt.Tables[0];
                gvLabOrders.DataBind();
            }
        }

        protected void gvLabOrders_SelectedIndexChanged(object sender, EventArgs e)
        {
            Session["PatientId"] = int.Parse(gvLabOrders.SelectedDataKey.Values["Ptn_pk"].ToString());
            Session["PatientVisitID"] = int.Parse(gvLabOrders.SelectedDataKey.Values["VisitID"].ToString());
            Response.Redirect("frm_Laboratory.aspx");
        }

        protected void gvLabOrders_DataBound(object sender, EventArgs e)
        {
            if (gvLabOrders.Rows.Count > 4)
            {
                GridViewRow row = new GridViewRow(0, 0, DataControlRowType.Header, DataControlRowState.Normal);
                for (int i = 1; i < gvLabOrders.Columns.Count; i++)
                {
                    TableHeaderCell cell = new TableHeaderCell();
                    TextBox txtSearch = new TextBox();
                    txtSearch.Attributes["placeholder"] = gvLabOrders.Columns[i].HeaderText;
                    txtSearch.CssClass = "search_textbox";
                    //txtSearch.Width = gvLabOrders.Columns[i].HeaderStyle.Width;
                    cell.Controls.Add(txtSearch);
                    row.Controls.Add(cell);
                }

                gvLabOrders.HeaderRow.Parent.Controls.AddAt(1, row);
            }
        }

        protected void gvLabOrders_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType == DataControlRowType.DataRow)
            {
                e.Row.Attributes["onclick"] = Page.ClientScript.GetPostBackClientHyperlink(gvLabOrders, "Select$" + e.Row.RowIndex);
            }
        }

        protected void rbtlstFindLabOrders_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (rbtlstFindLabOrders.SelectedValue == "Patient")
            {
                string theUrl;
                theUrl = string.Format("../frmFindAddCustom.aspx?srvNm={0}&mod={1}", "Laboratory", "300");
                Response.Redirect(theUrl, false);
            }
        }
    }
}