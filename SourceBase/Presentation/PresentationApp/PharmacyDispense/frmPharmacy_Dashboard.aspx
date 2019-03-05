<%@ Page Title="" Language="C#" MasterPageFile="~/MasterPage/IQCare.master" AutoEventWireup="true"
    CodeBehind="frmPharmacy_Dashboard.aspx.cs" Inherits="PresentationApp.PharmacyDispense.frmPharmacy_Dashboard" %>

<%@ Register Src="../ClinicalForms/UserControl/UserControl_Loading.ascx" TagName="UserControl_Loading"
    TagPrefix="uc1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="IQCareContentPlaceHolder" runat="server">
    <%--<telerik:RadScriptManager runat="server" ID="RadScriptManager1" />--%>
    <div class="content-wrapper">
        <div class="box-body">
            <div class="row">
                <div class="col-xs-12">
                    <div class="box box-primary box-solid">
                        <div class="box-header">
                            <h3 class="box-title">
                                Pharmacy Dashboard</h3>
                        </div>
                        <!-- /.box-header -->
                        <div class="box-body table-responsive no-padding" style="overflow: hidden; margin-left: 5px;">
                            <%--Main Content Start--%>
                            <div class="row">
                                <br />
                                <div class="col-md-2 col-sm-12 col-xs-12 form-group">
                                    <label class="control-label">
                                        Store</label>
                                </div>
                                <div class="col-md-4 col-sm-12 col-xs-12 form-group">
                                    <asp:DropDownList ID="ddlStore" runat="server" AutoPostBack="True" Width="90%" CssClass="form-control">
                                    </asp:DropDownList>
                                </div>
                                <div class="col-md-2 col-sm-12 col-xs-12 form-group">
                                </div>
                                <div class="col-md-4 col-sm-12 col-xs-12 form-group">
                                </div>
                            </div>
                            <div class="row" align="center">
                                <div class="col-md-12 col-sm-12 col-xs-12 form-group">
                                    <asp:UpdateProgress ID="UpdateProgress1" runat="server">
                                        <ProgressTemplate>
                                            <uc1:UserControl_Loading ID="UserControl_Loading1" runat="server" />
                                        </ProgressTemplate>
                                    </asp:UpdateProgress>
                                </div>
                            </div>
                            <div class="row">
                                <asp:UpdatePanel ID="UpdatePanel1" runat="server">
                                    <ContentTemplate>
                                        <div class="row">
                                            <div class="col-md-12 form-group">
                                                    <br />
                                                    <telerik:radhtmlchart runat="server" id="RadHtmlChart2" 
                                                        skin="Silk">
                                                        <PlotArea>
                                                            <Series>
                                                                <telerik:ColumnSeries Name="Appointments" DataFieldY="NoOfAppointments">
                                                                    <Appearance>
                                                                        <FillStyle BackgroundColor="#ffb128" />
                                                                    </Appearance>
                                                                    <TooltipsAppearance Color="White" />
                                                                </telerik:ColumnSeries>
                                                                <telerik:ColumnSeries Name="Visits" DataFieldY="NoOfVisits" >
                                                                    <Appearance>
                                                                        <FillStyle BackgroundColor="#006caa" />
                                                                    </Appearance>
                                                                    <TooltipsAppearance Color="White" />
                                                                </telerik:ColumnSeries>
                                                            </Series>
                                                            <XAxis DataLabelsField="Day" Color="#aaaaaa">
                                                                <MinorGridLines Visible="false"></MinorGridLines>
                                                                <MajorGridLines Visible="false"></MajorGridLines>
                                                                <LabelsAppearance>
                                                                    <TextStyle Color="#666666" />
                                                                </LabelsAppearance>
                                                            </XAxis>
                                                            <YAxis Color="#aaaaaa">
                                                                <LabelsAppearance>
                                                                    <TextStyle Color="#666666" />
                                                                </LabelsAppearance>
                                                                <MinorGridLines Visible="false"></MinorGridLines>
                                                                <TitleAppearance Text="No. of appointments/visits">
                                                                    <TextStyle Color="#555555" />
                                                                </TitleAppearance>
                                                            </YAxis>
                                                        </PlotArea>
                                                        <Legend>
                                                        </Legend>
                                                        <ChartTitle Text="Patient Appointments vs Visits">
                                                        </ChartTitle>
                                                    </telerik:radhtmlchart>
                                            </div>
                                        </div>
                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="ddlStore" EventName="SelectedIndexChanged" />
                                    </Triggers>
                                </asp:UpdatePanel>
                            </div>
                            <%--Main Content End--%>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div style="padding: 6px">
        <br />
    </div>
</asp:Content>
