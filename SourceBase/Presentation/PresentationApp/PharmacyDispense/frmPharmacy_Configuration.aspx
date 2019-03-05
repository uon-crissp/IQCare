<%@ Page Title="" Language="C#" MasterPageFile="~/MasterPage/IQCare.master" AutoEventWireup="true"
    CodeBehind="frmPharmacy_Configuration.aspx.cs" Inherits="PresentationApp.PharmacyDispense.frmPharmacy_Configuration" %>

<asp:Content ID="Content1" ContentPlaceHolderID="IQCareContentPlaceHolder" runat="server">
    <div class="box-body">
        <div class="row">
            <div class="col-xs-12">
                <div class="box box-primary box-solid">
                    <div class="box-header">
                        <h3 class="box-title">
                            Pharmacy Configuration</h3>
                    </div>
                    <div class="box-body table-responsive no-padding" style="overflow: hidden; margin-left: 5px;">
                        <div class="row">
                        <br /><br />
                            <div class="col-md-4">
                                <a href="../AdminForms/frmAdmin_DrugList.aspx">
                                    <button type="button" class="btn btn-default btn-lg btn-block">
                                        Drug List</button></a><br />
                                <br />
                            </div>
                            <div class="col-md-4">
                                <a href="../AdminForms/frmAdmin_Drug.aspx">
                                    <button type="button" class="btn btn-default btn-lg btn-block">
                                        Add Drug</button></a><br />
                                <br />
                            </div>
                            <div class="col-md-4">
                                <a href="../AdminForms/frmAdmin_DrugStores.aspx">
                                    <button type="button" class="btn btn-default btn-lg btn-block">
                                        Stores</button></a><br />
                                <br />
                            </div>
                            <div class="col-md-4">
                                <a href="../AdminForms/frmAdmin_DrugSuppliers.aspx">
                                    <button type="button" class="btn btn-default btn-lg btn-block">
                                        Suppliers</button></a><br />
                                <br />
                            </div>
                            <div class="col-md-4">
                                <a href="../AdminForms/frmAdmin_RegimenCodes.aspx">
                                    <button type="button" class="btn btn-default btn-lg btn-block">
                                        Regimen Codes</button></a><br />
                                <br />
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</asp:Content>
