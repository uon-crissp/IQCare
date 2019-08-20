<%@ Page Title="" Language="C#" MasterPageFile="~/MasterPage/IQCare.master" AutoEventWireup="true"
    CodeBehind="frmPatientSummary.aspx.cs" Inherits="PresentationApp.Reports.frmPatientSummary" %>

<%@ Register Assembly="Telerik.ReportViewer.WebForms, Version=8.1.14.618, Culture=neutral, PublicKeyToken=a9d7983dfcc261be"
    Namespace="Telerik.ReportViewer.WebForms" TagPrefix="telerik" %>
<asp:Content ID="Content1" ContentPlaceHolderID="IQCareContentPlaceHolder" runat="server">
    <table width="100%">
        <tr>
            <td align="center">
                <telerik:reportviewer runat="server" id="reportViewer1" width="100%" height="900px" ViewMode="PrintPreview"></telerik:reportviewer>
            </td>
        </tr>
    </table>
</asp:Content>
