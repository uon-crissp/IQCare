<%@ Page Language="C#" MasterPageFile="~/MasterPage/IQCare.master" AutoEventWireup="True"
    Inherits="frmAdmin_Drug" Title="Untitled Page" CodeBehind="frmAdmin_Drug.aspx.cs" %>

<%@ MasterType VirtualPath="~/MasterPage/IQCare.master" %>
<asp:Content ID="Content1" ContentPlaceHolderID="IQCareContentPlaceHolder" runat="Server">
    <div class="box-body">
        <div class="row">
            <div class="col-xs-12">
                <div class="box box-primary box-solid">
                    <div class="box-header">
                        <h3 class="box-title">
                            <asp:Label ID="lblH2" runat="server"></asp:Label>
                        </h3>
                    </div>
                    <!-- /.box-header -->
                    <div class="box-body table-responsive no-padding" style="overflow: hidden; margin-left: 5px;">
                        <br />
                        <div class="row">
                            <div class="col-md-4 form-group">
                                <label class="control-label">
                                    Drug type :</label>
                                <asp:DropDownList ID="ddlDrugType" runat="server" AutoPostBack="True" Width="99%"
                                    CssClass="form-control">
                                </asp:DropDownList>
                            </div>
                            <div class="col-md-8 form-group">
                                <label class="control-label">
                                    Drug name :</label>
                                <asp:TextBox ID="txtDrugName" runat="server" Width="99%" CssClass="form-control"></asp:TextBox>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-md-4 form-group">
                                <label class="control-label">
                                    Drug abbreviation :</label>
                                <asp:TextBox ID="txtDrugAbbre" runat="server" Width="99%" CssClass="form-control"></asp:TextBox>
                            </div>
                            <div class="col-md-4 form-group">
                                <label class="control-label">
                                    purchase Unit:</label>
                                <asp:DropDownList ID="ddlPurchaseUnit" runat="server" AutoPostBack="True" Width="99%"
                                    CssClass="form-control">
                                </asp:DropDownList>
                            </div>
                            <div class="col-md-4 form-group">
                                <label class="control-label">
                                    Quantity per Purchase Unit:</label>
                                <asp:TextBox ID="txtPurchaseUnitQty" runat="server" Width="99%" CssClass="form-control"></asp:TextBox>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-md-4 form-group">
                                <label class="control-label">
                                    Dispensing Unit:</label>
                                <asp:DropDownList ID="ddlDispensingUnit" runat="server" AutoPostBack="True" Width="99%"
                                    CssClass="form-control">
                                </asp:DropDownList>
                            </div>
                            <div class="col-md-4 form-group">
                                <label class="control-label">
                                    Is Syrup?:</label>
                                <asp:DropDownList ID="ddlIsSyrup" runat="server" Width="99%" CssClass="form-control">
                                    <asp:ListItem Value="0">No</asp:ListItem>
                                    <asp:ListItem Value="1">Yes</asp:ListItem>
                                </asp:DropDownList>
                            </div>
                            <div class="col-md-4 form-group">
                                <label class="control-label">
                                    Status :</label>
                                <asp:DropDownList ID="ddStatus" runat="server" Width="99%" CssClass="form-control">
                                    <asp:ListItem Value="0">Active</asp:ListItem>
                                    <asp:ListItem Value="1">InActive</asp:ListItem>
                                </asp:DropDownList>
                            </div>
                        </div>
                        <div class="row" align="center">
                            <div class="col-md-12 col-sm-12 col-xs-12 form-group">
                                <asp:Button ID="btnSave" runat="server" Text="Save" OnClick="btnSave_Click" CssClass="btn btn-primary"
                                    Height="30px" Width="8%" Style="text-align: left;" />
                                <label class="glyphicon glyphicon-floppy-disk" style="margin-left: -3%; margin-right: 2%;
                                    vertical-align: sub; color: #fff;">
                                </label>
                                <asp:Button ID="btnCancel" runat="server" Text="Close" OnClick="btnCancel_Click"
                                    CssClass="btn btn-primary" Height="30px" Width="8%" Style="text-align: left;" />
                                <label class="glyphicon glyphicon-remove" style="margin-left: -3%; margin-right: 2%;
                                    vertical-align: sub; color: #fff;">
                                </label>
                                <asp:Button ID="btn" runat="server" Text="OK" OnClick="btn_Click" CssClass="btn btn-primary"
                                    Height="30px" Width="8%" Style="text-align: left;" />
                                <label class="glyphicon glyphicon-ok" style="margin-left: -3%; margin-right: 2%;
                                    vertical-align: sub; color: #fff;">
                                </label>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</asp:Content>
