<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="ucCCCMenu.ascx.cs" Inherits="PresentationApp.ClinicalForms.UserControl.ucCCCMenu" %>
<div class="row" style="border: 1px solid #3C8DBC;">
    <table width="100%">
        <tr>
            <td>
                <h4>
                    Create New form:</h4>
                <table style="padding: 10px" width="100%">
                    <tr>
                        <td bgcolor="#3C8DBC" style="padding: 5px">
                            <font color='white'>NURSING</font>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 5px">
                            <li><a href="../HIVCE/ClinicalEncounter.aspx?add=0">Triage</a></li>
                        </td>
                    </tr>
                    <tr>
                        <td bgcolor="#3C8DBC" style="padding: 5px;">
                            <font color='white'>CLINICAL REVIEW</font>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 5px">
                            <li><asp:LinkButton ID="lnkClinicalEncounter" runat="server" 
                                    onclick="lnkClinicalEncounter_Click">Clinical Encounter</asp:LinkButton></li>
                        </td>
                    </tr>
                    <tr>
                        <td bgcolor="#3C8DBC" style="padding: 5px">
                            <font color='white'>PSYCHOSOCIAL SUPPORT</font>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 5px">
                            <li><a href="../HIVCE/ARTReadinessAssessment.aspx?add=0">ART Readiness Assessment</a><br />
                            </li>
                            <li><a href="../HIVCE/TreatmentPreparation.aspx?add=0">Treatment Preparation</a><br />
                            </li>
                            <li><a href="../HIVCE/AlcoholDepressionScreening.aspx?add=0">Alcohol, GBV and Depression
                                Screening</a><br />
                            </li>
                            <li><a href="../HIVCE/MoriskyAdherence.aspx?add=0">Morisky Adherence Screening</a><br />
                            </li>
                            <li><a href="../Adherence/AdherenceBarriers.aspx?add=0">Adherence Barriers</a><br />
                            </li>
                            <li><a href="../Adherence/EnhanceAdherence.aspx?add=0">Enhanced Adherence Counseling</a><br />
                            </li>
                            <li><a href="../HIVCE/Transition.aspx?add=0">Transition to Adolescent Services</a><br />
                            </li>
                        </td>
                    </tr>
                    <tr>
                        <td bgcolor="#3C8DBC" style="padding: 5px">
                            <font color='white'>NUTRITION</font>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 5px">
                            <li>
                                <asp:LinkButton ID="lnkNutrition" runat="server" OnClick="lnkNutrition_Click">Nutrition Assessment and Intervention</asp:LinkButton></li>
                        </td>
                    </tr>
                    <tr>
                        <td bgcolor="#3C8DBC" style="padding: 5px">
                            <font color='white'>SPECIALIZED CARE</font>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 5px">
                            <li>
                                <asp:LinkButton ID="lnkAdvancedCare" runat="server" 
                                    onclick="lnkAdvancedCare_Click">Advanced Care Review</asp:LinkButton></li>
                            <li>
                                <asp:LinkButton ID="lnkPyschiatric" runat="server" 
                                    onclick="lnkPyschiatric_Click">Psychiatric Care Review</asp:LinkButton></li>
                            <li>
                                <asp:LinkButton ID="lnkPhysiotheraphy" runat="server" 
                                    onclick="lnkPhysiotheraphy_Click">Physiotheraphy</asp:LinkButton></li>
                        </td>
                    </tr>
                    <tr>
                        <td bgcolor="#3C8DBC" style="padding: 5px">
                            <font color='white'>LABORATORY</font>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 5px">
                            <li><a href="../Laboratory/frm_Laboratory.aspx">Order Lab Tests</a></li>
                            <li><a href="javascript:openLabHistory();">View Lab Results</a></li>
                        </td>
                    </tr>
                    <tr>
                        <td bgcolor="#3C8DBC" style="padding: 5px">
                            <font color='white'>PHARMACY</font>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 5px">
                            <li><a href="../PharmacyDispense/frmPharmacyDispense_PatientOrder.aspx">Prescribe Drugs</a>
                                <br />
                            </li>
                            <li><a href="javascript:openDrugHistory();">View Drug History</a></li>
                        </td>
                    </tr>
                    <tr>
                        <td bgcolor="#3C8DBC" style="padding: 5px">
                            <font color='white'>TARGETED STRATEGIES</font>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 5px">
                            <li><asp:LinkButton ID="lnkOTZ" runat="server" onclick="lnkOTZ_Click">OTZ</asp:LinkButton>
                            </li>
                        </td>
                    </tr>
                    <tr>
                        <td bgcolor="#3C8DBC" style="padding: 5px">
                            <font color='white'>RETENTION</font>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 5px">
                            <li>
                                <asp:LinkButton ID="lnkDefaulterTracing" runat="server" 
                                    onclick="lnkDefaulterTracing_Click">Defaulter Tracing</asp:LinkButton></li>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</div>
