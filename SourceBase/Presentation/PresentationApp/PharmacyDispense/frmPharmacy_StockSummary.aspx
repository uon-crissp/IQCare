<%@ Page Title="" Language="C#" MasterPageFile="~/MasterPage/IQCare.master" AutoEventWireup="true"
    CodeBehind="frmPharmacy_StockSummary.aspx.cs" Inherits="PresentationApp.PharmacyDispense.frmPharmacy_StockSummary"
    EnableEventValidation="false" %>

<%@ Register Assembly="AjaxControlToolkit" TagPrefix="act" Namespace="AjaxControlToolkit" %>
<%@ Register Src="../ClinicalForms/UserControl/UserControl_Loading.ascx" TagName="UserControl_Loading"
    TagPrefix="uc1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="IQCareContentPlaceHolder" runat="server">
    <%--<asp:ScriptManager ID="mst" runat="server" EnablePageMethods="true" EnablePartialRendering="true">
    </asp:ScriptManager>--%>
    <script type="text/javascript">
        function RegisterJQuery() {
            $('#dtFrom').datepicker({ autoclose: true });
            $('#dtTo').datepicker({ autoclose: true });
        }
        //Calling RegisterJQuery when document is ready (Page loaded first time)
        $(document).ready(RegisterJQuery);
        //Calling RegisterJQuery when the page is doing postback (asp.net)
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(RegisterJQuery);
    </script>
    <script type="text/javascript">
        function ace1_itemSelected(source, e) {
            var index = source._selectIndex;
            if (index != -1) {
                var hdCustID = $get('<%= hdCustID.ClientID %>');
                hdCustID.value = e.get_value();
            }
        }
    </script>
    <asp:HiddenField ID="hdCustID" runat="server" />
    <div class="content-wrapper">
        <div class="box-body">
            <div class="row">
                <div class="col-xs-12">
                    <div class="box box-primary box-solid">
                        <div class="box-header">
                            <h3 class="box-title">
                                Stock Summary</h3>
                        </div>
                        <!-- /.box-header -->
                        <div class="box-body table-responsive no-padding" style="overflow: hidden; margin-left: 5px;">
                            <%--Main Content Start--%>
                            <div class="row">
                                <br />
                                <div class="col-md-1 col-sm-12 col-xs-12 form-group">
                                    <label class="control-label required">
                                        Store:</label>
                                </div>
                                <div class="col-md-3 col-sm-12 col-xs-12 form-group">
                                    <asp:DropDownList ID="ddlStore" runat="server" Width="98%" AutoPostBack="True" OnSelectedIndexChanged="ddlStore_SelectedIndexChanged"
                                        CssClass="form-control">
                                    </asp:DropDownList>
                                </div>
                                <div class="col-md-1 col-sm-12 col-xs-12 form-group">
                                    <label class="control-label">
                                        Items:</label>
                                </div>
                                <div class="col-md-7 col-sm-12 col-xs-12 form-group">
                                    <asp:TextBox ID="txtSearch" runat="server" Width="98%" CssClass="form-control"></asp:TextBox>
                                    <div id="divwidth">
                                    </div>
                                    <act:AutoCompleteExtender runat="server" ServiceMethod="SearchBorrower" MinimumPrefixLength="2"
                                        CompletionInterval="20" EnableCaching="false" CompletionSetCount="10" TargetControlID="txtSearch"
                                        ID="AutoCompleteSearchBorrower" FirstRowSelected="true" CompletionListElementID="divwidth"
                                        OnClientItemSelected="ace1_itemSelected" UseContextKey="True">
                                    </act:AutoCompleteExtender>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-1 col-sm-12 col-xs-12 form-group">
                                    <label class="control-label">
                                        From:</label>
                                </div>
                                <div class="col-md-3 col-sm-12 col-xs-12 form-group">
                                    <div class="form-group">
                                        <div class="input-group date">
                                            <div class="input-group-addon">
                                                <i class="fa fa-calendar"></i>
                                            </div>
                                            <input type="text" class="form-control pull-left" id="dtFrom" clientidmode="Static"
                                                maxlength="11" runat="server" data-date-format="dd-M-yyyy" style="width: 120px;" />
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-1 col-sm-12 col-xs-12 form-group">
                                    <label class="control-label">
                                        To:</label>
                                </div>
                                <div class="col-md-3 col-sm-12 col-xs-12 form-group">
                                    <div class="form-group">
                                        <div class="input-group date">
                                            <div class="input-group-addon">
                                                <i class="fa fa-calendar"></i>
                                            </div>
                                            <input type="text" class="form-control pull-left" id="dtTo" clientidmode="Static"
                                                maxlength="11" runat="server" data-date-format="dd-M-yyyy" style="width: 120px;" />
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-4 col-sm-12 col-xs-12 form-group" align="center">
                                    <asp:Button ID="btnSubmit" runat="server" Text="Submit" CssClass="btn btn-primary"
                                        Height="30px" Width="25%" Style="text-align: left;" OnClick="Button4_Click" />
                                    <label class="glyphicon glyphicon-log-in" style="margin-left: -6%; margin-right: 3%;
                                        vertical-align: sub; color: #fff;">
                                    </label>
                                    <asp:Button ID="btnExportToExcel" runat="server" Text="Export to Excel" CssClass="btn btn-primary"
                                        Height="30px" Width="35%" Style="text-align: left;" OnClick="btnExportToExcel_Click" />
                                    <label class="glyphicon glyphicon-export" style="margin-left: -4.8%; margin-right: 1%;
                                        vertical-align: sub; color: #fff;">
                                    </label>
                                </div>
                            </div>
                            <div class="row" align="center">
                                <div class="col-md-12 col-sm-12 col-xs-12 form-group">
                                    <asp:UpdateProgress ID="UpdateProgress2" runat="server">
                                        <ProgressTemplate>
                                            <uc1:UserControl_Loading ID="UserControl_Loading1" runat="server" />
                                        </ProgressTemplate>
                                    </asp:UpdateProgress>
                                </div>
                            </div>
                            <div class="row" align="center">
                                <div class="col-md-12 col-sm-12 col-xs-12 form-group">
                                    <div class="GridView whitebg" style="cursor: pointer; width: 99.5%">
                                        <div class="grid">
                                            <div class="rounded">
                                                <div class="top-outer">
                                                    <div class="top-inner">
                                                        <div class="top">
                                                            <h2 class="center">
                                                                Items</h2>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="mid-outer">
                                                    <div class="mid-inner">
                                                        <div class="mid" style="height: 300px; overflow: auto">
                                                            <div id="div-gridview" class="GridView whitebg">
                                                                <asp:GridView ID="grdStockSummary" runat="server" AutoGenerateColumns="False" ShowHeaderWhenEmpty="True"
                                                                    Width="100%" BorderWidth="0px" CellPadding="0" CssClass="table table-bordered table-hover"
                                                                    GridLines="None" OnRowCommand="grdStockSummary_RowCommand" DataKeyNames="ItemId">
                                                                    <HeaderStyle CssClass="FreezeHeader" />
                                                                    <Columns>
                                                                        <asp:BoundField ItemStyle-Width="26.5%" HeaderText="Drug Name" DataField="ItemName" />
                                                                        <asp:BoundField ItemStyle-Width="4.5%" HeaderText="Unit" DataField="DispensingUnit" />
                                                                        <asp:BoundField ItemStyle-Width="11%" HeaderText="Opening Stock" DataField="OpeningStock" />
                                                                        <asp:BoundField ItemStyle-Width="9%" HeaderText="Received Qty" DataField="QtyRecieved" />
                                                                        <asp:BoundField ItemStyle-Width="12%" HeaderText="Interstore Issue" DataField="InterStoreIssueQty" />
                                                                        <asp:BoundField ItemStyle-Width="10%" HeaderText="Quantity Disp" DataField="QtyDispensed" />
                                                                        <asp:BoundField ItemStyle-Width="10%" HeaderText="Adjusted Qty" DataField="AdjustmentQuantity" />
                                                                        <asp:BoundField ItemStyle-Width="9%" HeaderText="Closing Qty" DataField="ClosingQty" />
                                                                        <asp:TemplateField ItemStyle-Width="7%" HeaderText="Bin Card">
                                                                            <ItemTemplate>
                                                                                <asp:ImageButton ID="ImageButton1" runat="server" ImageUrl="~/Images/bincard.jpg"
                                                                                    CommandArgument="<%# Container.DataItemIndex %>"></asp:ImageButton>
                                                                            </ItemTemplate>
                                                                        </asp:TemplateField>
                                                                    </Columns>
                                                                </asp:GridView>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="bottom-outer">
                                                    <div class="bottom-inner">
                                                        <div class="bottom">
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <%--Main Content End--%>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</asp:Content>
