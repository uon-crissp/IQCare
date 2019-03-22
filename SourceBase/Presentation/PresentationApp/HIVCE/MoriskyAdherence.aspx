<%@ Page Title="" Language="C#" MasterPageFile="~/MasterPage/IQCare.master" AutoEventWireup="true"
    CodeBehind="MoriskyAdherence.aspx.cs" Inherits="PresentationApp.HIVCE.MoriskyAdherence" %>

<asp:Content ID="Content1" ContentPlaceHolderID="IQCareContentPlaceHolder" runat="server">
    <script src="<%=ResolveUrl("Scripts/ucManagementx.js") %>?n=<%=string.Format("{0:yyyyMMddhhmmss}",DateTime.Now)%>"
        type="text/javascript"></script>
    <div class="content-wrapper">
        <!-- Main content -->
        <%--<section class="content">--%>
        <!-- Default box -->
        <div>
            <div class="box-body">
                <div class="row">
                    <div class="col-xs-12">
                        <div class="box box-primary box-solid">
                            <div class="box-header with-border">
                                <h3 class="box-title">
                                    Alcohol Depression Screening</h3>
                                <!-- /.box-tools -->
                            </div>
                            <!-- /.box-header -->
                            <div class="box-body">
                                <!-- / sub box level 2 -->
                                <div class="box box-default box-solid">
                                    <!-- /.box-header -->
                                    <div class="box-body">
                                        <div class="row">
                                            <div class="col-md-12 col-sm-12 col-xs-12 form-group">
                                                <table class="table" style="padding-left: 10px; margin-bottom: 0px;">
                                                    <tr>
                                                        <td colspan="2" style="border-top: 0px; padding: 2px;">
                                                            <div class="box box-default box-solid" style="margin-bottom: 5px;">
                                                                <div class="box-header">
                                                                    <h5 class="box-title">
                                                                        Morisky Medication Adherence Scale (MMAS-4)</h5>
                                                                    <!-- /.box-tools -->
                                                                </div>
                                                                <!-- /.box-header -->
                                                            </div>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td style="border-top: 0px; width: 90%">
                                                            1. Do you forget to take any of your medicine since the last visit?
                                                        </td>
                                                        <td style="border-top: 0px; width: 10%">
                                                            <input id="chkForgotMed" name="switch-size" type="checkbox" checked data-size="small"
                                                                data-on-text="Yes" data-off-text="No">
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td style="border-top: 0px; width: 90%">
                                                            2. Are you careless at times about taking your medicine?
                                                        </td>
                                                        <td style="border-top: 0px; width: 10%">
                                                            <input id="chkCarelessMed" name="switch-size" type="checkbox" checked data-size="small"
                                                                data-on-text="Yes" data-off-text="No">
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td style="border-top: 0px; width: 90%">
                                                            3. Sometimes if you feel worse when you take the medicine, do you stop taking it?
                                                        </td>
                                                        <td style="border-top: 0px; width: 10%">
                                                            <input id="chkWorseTakingMed" name="switch-size" type="checkbox" checked data-size="small"
                                                                data-on-text="Yes" data-off-text="No">
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td style="border-top: 0px; width: 90%">
                                                            4. When you feel better do you sometimes stop taking your medicine?
                                                        </td>
                                                        <td style="border-top: 0px; width: 10%">
                                                            <input id="chkFeelBetterMed" name="switch-size" type="checkbox" checked data-size="small"
                                                                data-on-text="Yes" data-off-text="No">
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td colspan="2" style="border-top: 0px;">
                                                            <div class="row">
                                                                <div class="col-md-6 col-sm-12 col-xs-12 form-group">
                                                                    (MMAS-4) Score =
                                                                    <input id="txtMMAS4Score" type="text" disabled="disabled" class="form-control" value="0"
                                                                        style="width: 30%; display: inline;">
                                                                    / 4
                                                                </div>
                                                                <div class="col-md-6 col-sm-12 col-xs-12 form-group">
                                                                    Adherence Rating:
                                                                    <input type="text" id="txtMMAS4Rating" disabled="disabled" value="Good" class="form-control"
                                                                        style="width: 55%; display: inline;">
                                                                </div>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                </table>
                                                <div id="divOtherQesAdherence">
                                                    <table class="table" style="padding-left: 10px;">
                                                        <tr>
                                                            <td style="border-top: 0px; width: 90%">
                                                                5. Did you take your medicine yesterday?
                                                            </td>
                                                            <td style="border-top: 0px; width: 10%">
                                                                <input id="chkYesterdayMed" name="switch-size" type="checkbox" checked data-size="small"
                                                                    data-on-text="Yes" data-off-text="No">
                                                            </td>
                                                        </tr>
                                                        <tr>
                                                            <td style="border-top: 0px; width: 90%">
                                                                6. When you feel like your symptoms are under control, do you sometimes stop taking
                                                                your medicine?
                                                            </td>
                                                            <td style="border-top: 0px; width: 10%">
                                                                <input id="chkSymptomUnderControl" name="switch-size" type="checkbox" checked data-size="small"
                                                                    data-on-text="Yes" data-off-text="No">
                                                            </td>
                                                        </tr>
                                                        <tr>
                                                            <td style="border-top: 0px; width: 90%">
                                                                7. Taking medication every day is a real inconvenience for some people. Do you ever
                                                                feel under pressure about sticking to your treatment plan?
                                                            </td>
                                                            <td style="border-top: 0px; width: 10%">
                                                                <input id="chkStickingTreatmentPlan" name="switch-size" type="checkbox" checked data-size="small"
                                                                    data-on-text="Yes" data-off-text="No">
                                                            </td>
                                                        </tr>
                                                        <tr>
                                                            <td colspan="2" style="border-top: 0px; width: 90%">
                                                                8. How often do you have difficulty remembering to take all your medications?
                                                            </td>
                                                        </tr>
                                                        <tr>
                                                            <td style="border-top: 0px; width: 10%">
                                                                <div class="row">
                                                                    <div class="col-md-1 col-sm-12 col-xs-12 form-group">
                                                                    </div>
                                                                    <div class="col-md-10 col-sm-12 col-xs-12 form-group">
                                                                        <div id="divMrgRM">
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </td>
                                                        </tr>
                                                        <tr>
                                                            <td colspan="2" style="border-top: 0px;">
                                                                <div class="row">
                                                                    <div class="col-md-4 col-sm-12 col-xs-12 form-group">
                                                                        (MMAS-8) Score =
                                                                        <input id="txtMMAS8Score" type="text" disabled="disabled" class="form-control" value="0"
                                                                            style="width: 30%; display: inline;">
                                                                        / 8
                                                                    </div>
                                                                    <div class="col-md-4 col-sm-12 col-xs-12 form-group">
                                                                        Adherence Rating:
                                                                        <input type="text" id="txtMMAS8Rating" disabled="disabled" value="None" class="form-control"
                                                                            style="width: 55%; display: inline;">
                                                                    </div>
                                                                    <div class="col-md-4 col-sm-12 col-xs-12 form-group">
                                                                        <input type="text" id="txtMMAS8Suggestion" disabled="disabled" value="None" class="form-control"
                                                                            style="width: 55%; display: inline;">
                                                                    </div>
                                                                </div>
                                                            </td>
                                                        </tr>
                                                    </table>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <!-- /.box sub box level 2 -->
                                </div>
                                <!-- /.box-body -->
                            </div>
                            <!-- / sub box level 1 -->
                            <!-- /.box-body -->
                            <div class="box-footer" align="center">
                                <input type="hidden" runat="server" id="hidId" clientidmode="Static" />
                                <input type="hidden" runat="server" id="hidDOB" clientidmode="Static" value="0" />
                                <button type="button" class="btn btn-primary" onclick="SaveData();">
                                    Save<span class="glyphicon glyphicon-floppy-disk" style="padding-left: 5px;"></span></button>
                                <button type="button" class="btn btn-primary" onclick="ResetData();">
                                    Reset<span class="glyphicon glyphicon-remove-circle" style="padding-left: 5px;"></span></button>
                            </div>
                        </div>
                        <!-- /.box -->
                    </div>
                </div>
            </div>
            <!-- /.box-body -->
        </div>
        <!-- /.box -->
        <%-- </section>--%>
        <!-- /.content -->
    </div>
</asp:Content>
