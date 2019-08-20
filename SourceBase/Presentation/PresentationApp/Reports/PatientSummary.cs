namespace PresentationApp.Reports
{
    using System;
    using System.ComponentModel;
    using System.Drawing;
    using Telerik.Reporting;
    using Telerik.Reporting.Drawing;
    using Interface.Security;
    using Application.Presentation;

    /// <summary>
    /// Summary description for PatientSummary.
    /// </summary>
    public partial class PatientSummary : Telerik.Reporting.Report
    {
        public PatientSummary()
        {
            //
            // Required for telerik Reporting designer support
            //
            InitializeComponent();

            //
            // TODO: Add any constructor code after InitializeComponent call
            //
            IIQCareSystem appManager = (IIQCareSystem)ObjectFactory.CreateInstance("BusinessProcess.Security.BIQCareSystem, BusinessProcess.Security");
            string sconstring = appManager.GetEMRConnectionString().ToLower().Replace("initial catalog = iqcare", "initial catalog = iqtools");

            VLs.ConnectionString = sconstring;
            ARTInfo.ConnectionString = sconstring;
            CD4.ConnectionString = sconstring;
            ClinicalNotes.ConnectionString = sconstring;
            PatientDetails.ConnectionString = sconstring;

            pbLogo.Value = "logo.png";
        }
    }
}