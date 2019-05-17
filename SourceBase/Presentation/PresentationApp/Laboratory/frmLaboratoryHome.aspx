<%@ Page Title="" Language="C#" MasterPageFile="~/MasterPage/IQCare.master" AutoEventWireup="true"
    CodeBehind="frmLaboratoryHome.aspx.cs" Inherits="PresentationApp.Laboratory.frmLaboratoryHome" %>

<asp:Content ID="Content1" ContentPlaceHolderID="IQCareContentPlaceHolder" runat="server">
    <style type="text/css">
        .myRowStyle
        {
            cursor:pointer;
        }
    </style>
    <script src="../Incl/quicksearch.js" type="text/javascript" defer="defer"></script>
    <script type="text/javascript">
        $(function () {
            $('.search_textbox').each(function (i) {
                $(this).quicksearch("[id*=gvLabOrders] tr:not(:has(th))", {
                    'testQuery': function (query, txt, row) {
                        return $(row).children(":eq(" + i + ")").text().toLowerCase().indexOf(query[0].toLowerCase()) != -1;
                    }
                });
            });
        });

        function fnGoToURL(url) {
            window.location.href = url;
        }
    </script>
    <div class="content-wrapper">
        <div class="box-body">
            <div class="row">
                <div class="col-xs-12">
                    <div class="box box-primary box-solid">
                        <div class="box-header">
                            <h3 class="box-title">
                                Laboratory</h3>
                        </div>
                        <!-- /.box-header -->
                        <div class="box-body table-responsive no-padding" style="overflow: hidden; margin-left: 5px;">
                            <%--Main Content Start--%>
                            <div class="row box-header">
                                <br />
                                <div class="col-md-12 col-sm-12 col-xs-12 form-group">
                                    <h5 class="box-title">
                                        Patient Lab Orders</h5>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-1 col-sm-12 col-xs-12 form-group">
                                    <label id="lblpurpose" runat="server" class="control-label">
                                        Search for:</label>
                                </div>
                                <div class="col-md-11 col-sm-12 col-xs-12 form-group">
                                    <asp:RadioButtonList ID="rbtlstFindLabOrders" runat="server" AutoPostBack="True"
                                        RepeatDirection="Horizontal" 
                                        onselectedindexchanged="rbtlstFindLabOrders_SelectedIndexChanged">
                                        <asp:ListItem id="rbt_prescriptions" Text="Lab Orders &nbsp; &nbsp;" Selected="True"></asp:ListItem>
                                        <asp:ListItem id="rbt_patients" Text="Patient"></asp:ListItem>
                                    </asp:RadioButtonList>
                                </div>
                            </div>
                            <div class="row" align="center">
                                <div class="col-md-12 col-sm-12 col-xs-12 form-group">
                                    <div class="grid" id="divBills" style="width: 99%;">
                                        <div class="mid-outer">
                                            <div class="mid-inner">
                                                <div class="mid" style="height: 400px; overflow: auto">
                                                    <div id="div-gridview" class="GridView whitebg">
                                                        <asp:GridView ID="gvLabOrders" runat="server" AutoGenerateColumns="False" AllowSorting="true"
                                                            Width="100%" BorderColor="white" PageIndex="1" BorderWidth="1" GridLines="None"
                                                            CssClass="table table-bordered table-hover" CellPadding="0" 
                                                            CellSpacing="0" DataKeyNames="Ptn_pk, VisitID" 
                                                            onselectedindexchanged="gvLabOrders_SelectedIndexChanged" 
                                                            ondatabound="gvLabOrders_DataBound" onrowdatabound="gvLabOrders_RowDataBound">
                                                            <RowStyle CssClass="myRowStyle" />
                                                            <Columns>
                                                                <asp:BoundField HeaderText="PtnPK" DataField="Ptn_pk" Visible="False" />
                                                                <asp:BoundField HeaderText="Patient ID" DataField="PatientID" HeaderStyle-Width="10%" />
                                                                <asp:BoundField HeaderText="Patient Name" DataField="Name" HeaderStyle-Width="30%" />
                                                                <asp:BoundField HeaderText="Age" DataField="Age" HeaderStyle-Width="20%" />
                                                                <asp:BoundField HeaderText="Time Ordered" DataField="TimeOrdered" HeaderStyle-Width="20%" />
                                                                <asp:BoundField HeaderText="Status" DataField="Status" HeaderStyle-Width="20%" />
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
                            <%--Main Content End--%>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</asp:Content>
