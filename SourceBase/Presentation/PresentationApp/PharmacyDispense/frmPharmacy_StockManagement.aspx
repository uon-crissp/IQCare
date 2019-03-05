<%@ Page Title="" Language="C#" MasterPageFile="~/MasterPage/IQCare.master" AutoEventWireup="true"
    CodeBehind="frmPharmacy_StockManagement.aspx.cs" Inherits="PresentationApp.PharmacyDispense.frmPharmacy_StockManagement" %>

<%@ Register Assembly="AjaxControlToolkit" TagPrefix="act" Namespace="AjaxControlToolkit" %>
<%@ Register Src="../ClinicalForms/UserControl/UserControl_Loading.ascx" TagName="UserControl_Loading"
    TagPrefix="uc1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="IQCareContentPlaceHolder" runat="server">
    <%--<asp:ScriptManager ID="scriptManager1" runat="server" EnablePageMethods="true" EnablePartialRendering="true">
    </asp:ScriptManager>--%>
    <script type="text/javascript">
        function RegisterJQuery() {
            $('#txtTransactionDate').datepicker({ autoclose: true });
        }
        //Calling RegisterJQuery when document is ready (Page loaded first time)
        $(document).ready(RegisterJQuery);
        //Calling RegisterJQuery when the page is doing postback (asp.net)
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(RegisterJQuery);
    </script>
    <script type="text/javascript">
        $(function () {
            $(".datePicker").datepicker({
                dateFormat: "dd-M-yy",
                changeMonth: true,
                changeYear: true,
                yearRange: '1900:2090'
            });
        });


        function ace1_itemSelected(source, e) {
            var index = source._selectIndex;
            if (index != -1) {
                var hdCustID = $get('<%= hdCustID.ClientID %>');
                hdCustID.value = e.get_value();
            }
        }

        function DuplicateBatchNo(text, batches, controlID) {
            BatchesArray = batches.split(',');
            if (text != "") {
                if (BatchesArray.indexOf(text.toLowerCase()) > -1) {
                    alert('Batch Number exists.');
                    document.getElementById(controlID).value = "";
                    //this.value = "";
                }
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
                                Stock Management</h3>
                        </div>
                        <!-- /.box-header -->
                        <div class="box-body table-responsive no-padding" style="overflow: hidden; margin-left: 5px;">
                            <%--Main Content Start--%>
                            <div class="row">
                                <br />
                                <div class="col-md-4 form-group">
                                    <label class="control-label required">
                                        Transaction Type:</label>
                                    <asp:DropDownList ID="ddlTransactionType" runat="server" Width="90%" AutoPostBack="True"
                                        OnSelectedIndexChanged="ddlTransactionType_SelectedIndexChanged" CssClass="form-control">
                                        <asp:ListItem Value="0" Text="Select"></asp:ListItem>
                                        <asp:ListItem Value="1" Text="Receive"></asp:ListItem>
                                        <asp:ListItem Value="2" Text="Opening Stock"></asp:ListItem>
                                        <asp:ListItem Value="3" Text="Adjustment"></asp:ListItem>
                                    </asp:DropDownList>
                                </div>
                                <div class="col-md-4 form-group">
                                    <label class="control-label required">
                                        Transaction Date:</label>
                                    <div class="form-group">
                                        <div class="input-group date">
                                            <div class="input-group-addon">
                                                <i class="fa fa-calendar"></i>
                                            </div>
                                            <input type="text" class="form-control pull-left" id="txtTransactionDate" clientidmode="Static"
                                                maxlength="11" runat="server" data-date-format="dd-M-yyyy" style="width: 90%;" />
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-4 form-group">
                                    <label class="control-label">
                                        Order No:</label>
                                    <asp:TextBox ID="txtOrderNumber" runat="server" Width="90%" CssClass="form-control"></asp:TextBox>
                                </div>
                            </div>
                            <div class="row">
                                <div id="tblSourceStore" class="col-md-4 form-group">
                                    <asp:Label ID="lblSourceStore" runat="server" Text="Source Store:" Font-Bold="true"></asp:Label>
                                    <asp:DropDownList ID="ddlSourceStore" runat="server" OnSelectedIndexChanged="ddlSourceStore_SelectedIndexChanged"
                                        AutoPostBack="true" CssClass="form-control" Width="90%">
                                    </asp:DropDownList>
                                </div>
                                <div id="tblDestinationStore" class="col-md-4 form-group" runat="server">
                                    <label class="control-label required">
                                        Destination Store:</label>
                                    <asp:DropDownList ID="ddlDestinationStore" runat="server" Width="90%" CssClass="form-control">
                                    </asp:DropDownList>
                                </div>
                                <div id="tblSupplier" class="col-md-4 form-group" runat="server">
                                    <label class="control-label required">
                                        Supplier:</label>
                                    <asp:DropDownList ID="ddlSupplier" runat="server" Width="90%" OnSelectedIndexChanged="ddlSupplier_SelectedIndexChanged"
                                        AutoPostBack="true" CssClass="form-control">
                                    </asp:DropDownList>
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
                                    <asp:UpdatePanel ID="UpdatePanel2" runat="server">
                                        <ContentTemplate>
                                            <div class="GridView whitebg" style="cursor: pointer; width: 99%" align="center">
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
                                                                <div>
                                                                    <div class="row">
                                                                        <br />
                                                                        <div class="col-md-2 col-sm-12 col-xs-12 form-group">
                                                                            <label class="control-label">
                                                                                Drug Name :</label>
                                                                        </div>
                                                                        <div class="col-md-10 col-sm-12 col-xs-12 form-group">
                                                                            <asp:TextBox ID="txtDrug" runat="server" Width="98%" AutoPostBack="True" OnTextChanged="txtDrug_TextChanged"
                                                                                Enabled="False" CssClass="form-control"></asp:TextBox>
                                                                            <div id="divwidth">
                                                                            </div>
                                                                        </div>
                                                                    </div>
                                                                    <table width="100%">
                                                                        <tr>
                                                                            <td>
                                                                            </td>
                                                                        </tr>
                                                                    </table>
                                                                    <act:AutoCompleteExtender ServiceMethod="SearchDrugs" MinimumPrefixLength="2" CompletionInterval="30"
                                                                        EnableCaching="false" CompletionSetCount="10" TargetControlID="txtDrug" OnClientItemSelected="ace1_itemSelected"
                                                                        ID="AutoCompleteExtender1" runat="server" FirstRowSelected="false" CompletionListElementID="divwidth">
                                                                    </act:AutoCompleteExtender>
                                                                    <hr />
                                                                </div>
                                                                <div class="mid" style="height: 300px; overflow: auto">
                                                                    <div id="div-gridview" class="GridView whitebg">
                                                                        <asp:GridView ID="grdStockMngt" runat="server" AutoGenerateColumns="False" ShowHeaderWhenEmpty="True"
                                                                            Width="100%" BorderWidth="0px" CellPadding="0" CssClass="table table-bordered table-hover"
                                                                            GridLines="None" DataKeyNames="Drug_Pk" OnRowDataBound="grdStockMngt_RowDataBound"
                                                                            OnRowDeleting="grdStockMngt_RowDeleting">
                                                                            <Columns>
                                                                                <asp:TemplateField HeaderText="Drug Name" HeaderStyle-Width="30%" HeaderStyle-Font-Size="11px">
                                                                                    <ItemTemplate>
                                                                                        <asp:Label ID="lblDrugName" runat="server" Text='<%# Bind("DrugName") %>'></asp:Label>
                                                                                    </ItemTemplate>
                                                                                </asp:TemplateField>
                                                                                <asp:TemplateField HeaderText="Unit" HeaderStyle-Width="10%" HeaderStyle-Font-Size="11px">
                                                                                    <ItemTemplate>
                                                                                        <asp:Label ID="lblUnit" runat="server" Text='<%# Bind("Unit") %>'></asp:Label>
                                                                                    </ItemTemplate>
                                                                                </asp:TemplateField>
                                                                                <asp:TemplateField HeaderText="Batch No" HeaderStyle-Width="10%" HeaderStyle-Font-Size="11px">
                                                                                    <ItemTemplate>
                                                                                        <span style="display: <%# ShowLabel() %>">
                                                                                            <asp:Label ID="lblBatchNo" runat="server" Text='<%# Bind("BatchNo") %>'></asp:Label></span>
                                                                                        <span style="display: <%# ShowTextBox() %>">
                                                                                            <asp:TextBox ID="txtBatchNo" runat="server" Text='<%# Bind("BatchNo") %>' CssClass="form-control"></asp:TextBox>
                                                                                            <asp:RequiredFieldValidator ID="BatchNoRequiredFieldValidator" runat="server" ErrorMessage="Required"
                                                                                                Display="Dynamic" ControlToValidate="txtBatchNo" Enabled="false"></asp:RequiredFieldValidator>
                                                                                        </span>
                                                                                    </ItemTemplate>
                                                                                </asp:TemplateField>
                                                                                <asp:TemplateField HeaderText="Expiry Date" HeaderStyle-Width="10%" HeaderStyle-Font-Size="11px">
                                                                                    <ItemTemplate>
                                                                                        <span style="display: <%# ShowLabel() %>">
                                                                                            <asp:Label ID="lblExpiryDate" runat="server" Text='<%# Bind("ExpiryDate") %>'></asp:Label></span>
                                                                                        <span style="display: <%# ShowTextBox() %>">
                                                                                            <asp:TextBox ID="txtExpiryDate" runat="server" Text='<%# Bind("ExpiryDate") %>' CssClass="form-control"
                                                                                                Width="120" onkeyup="DateFormat(this,this.value,event,false,3);"></asp:TextBox>
                                                                                            <act:CalendarExtender ID="cal3" runat="server" TargetControlID="txtExpiryDate" Format="dd-MMM-yyyy">
                                                                                            </act:CalendarExtender>
                                                                                        </span>
                                                                                    </ItemTemplate>
                                                                                </asp:TemplateField>
                                                                                <asp:TemplateField HeaderText="Purchase Unit Price" HeaderStyle-CssClass="hidden"
                                                                                    ItemStyle-CssClass="hidden" HeaderStyle-Width="10%" HeaderStyle-Font-Size="11px">
                                                                                    <ItemTemplate>
                                                                                        <asp:Label ID="lblPurchaseUnitPrice" runat="server" Text='<%# Bind("PurchaseUnitPrice") %>'></asp:Label>
                                                                                    </ItemTemplate>
                                                                                </asp:TemplateField>
                                                                                <asp:TemplateField HeaderText="Purchase Unit" HeaderStyle-CssClass="hidden" ItemStyle-CssClass="hidden"
                                                                                    HeaderStyle-Width="10%" HeaderStyle-Font-Size="11px">
                                                                                    <ItemTemplate>
                                                                                        <asp:Label ID="lblPurchaseUnit" runat="server" Text='<%# Bind("PurchaseUnit") %>'></asp:Label>
                                                                                    </ItemTemplate>
                                                                                </asp:TemplateField>
                                                                                <asp:TemplateField HeaderText="Unit Quantity" HeaderStyle-CssClass="hidden" ItemStyle-CssClass="hidden"
                                                                                    HeaderStyle-Width="10%" HeaderStyle-Font-Size="11px">
                                                                                    <ItemTemplate>
                                                                                        <asp:Label ID="lblQtyPerPurchaseUnit" runat="server" Text='<%# Bind("QtyPerPurchaseUnit") %>'></asp:Label>
                                                                                    </ItemTemplate>
                                                                                </asp:TemplateField>
                                                                                <asp:TemplateField HeaderText="Avail Qty" HeaderStyle-Width="10%" HeaderStyle-Font-Size="11px">
                                                                                    <ItemTemplate>
                                                                                        <asp:Label ID="lblAvailQty" runat="server" Text='<%# Bind("AvailQty") %>'></asp:Label>
                                                                                    </ItemTemplate>
                                                                                </asp:TemplateField>
                                                                                <asp:TemplateField HeaderText="Quantity" HeaderStyle-Width="10%" HeaderStyle-Font-Size="11px">
                                                                                    <ItemTemplate>
                                                                                        <asp:TextBox ID="txtQuantity" CssClass="form-control" runat="server" Text='<%# Bind("Quantity") %>'
                                                                                            onkeypress='return (event.charCode >= 48 && event.charCode <= 57) || event.charCode == 46 || event.charCode == 45'></asp:TextBox>
                                                                                        <asp:RangeValidator ID="qtyRangeValidator" runat="server" ErrorMessage="Error" MinimumValue="1"
                                                                                            MaximumValue="500000000" Enabled="false" ControlToValidate="txtQuantity" Type="Double"
                                                                                            Display="Dynamic"></asp:RangeValidator>
                                                                                        <asp:RequiredFieldValidator ID="qtyRequiredValidator" runat="server" ErrorMessage="Required"
                                                                                            ControlToValidate="txtQuantity" Display="Dynamic"></asp:RequiredFieldValidator>
                                                                                    </ItemTemplate>
                                                                                </asp:TemplateField>
                                                                                <asp:TemplateField HeaderText="Comments" ControlStyle-Width="250px" HeaderStyle-Font-Size="11px">
                                                                                    <ItemTemplate>
                                                                                        <asp:TextBox ID="txtComments" runat="server" Text='<%# Bind("Comments") %>' CssClass="form-control"></asp:TextBox>
                                                                                    </ItemTemplate>
                                                                                </asp:TemplateField>
                                                                                <asp:CommandField ButtonType="Image" DeleteImageUrl="~/Images/del.gif" ShowDeleteButton="true" />
                                                                                <asp:TemplateField HeaderStyle-CssClass="hide" ItemStyle-CssClass="hide">
                                                                                    <ItemTemplate>
                                                                                        <asp:Label ID="lblBatchID" runat="server" Text='<%# Bind("BatchID") %>'></asp:Label>
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
                                        </ContentTemplate>
                                        <Triggers>
                                            <%--<asp:AsyncPostBackTrigger ControlID="ddlSourceStore" EventName="SelectedIndexChanged" />
                                    <asp:AsyncPostBackTrigger ControlID="ddlSupplier" EventName="SelectedIndexChanged" />--%>
                                            <%--<asp:PostBackTrigger ControlID="txtDrug" />--%>
                                        </Triggers>
                                    </asp:UpdatePanel>
                                </div>
                            </div>
                            <div class="row" align="center">
                                <div class="col-md-12 col-sm-12 col-xs-12 form-group">
                                    <asp:Button ID="btnSubmit" runat="server" Text="Submit" CssClass="btn btn-primary"
                                        Height="30px" Width="15%" OnClick="btnSubmit_Click" />
                                    <label class="glyphicon glyphicon-log-in" style="margin-left: -5%; margin-right: 5%;
                                        vertical-align: sub; color: #fff;">
                                    </label>
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
