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
    /// Summary description for PatientRegistrationForm.
    /// </summary>
    public partial class PatientRegistrationForm : Telerik.Reporting.Report
    {
        public PatientRegistrationForm()
        {
            //
            // Required for telerik Reporting designer support
            //
            InitializeComponent();

            //
            // TODO: Add any constructor code after InitializeComponent call
            //
             IIQCareSystem appManager = (IIQCareSystem)ObjectFactory.CreateInstance("BusinessProcess.Security.BIQCareSystem, BusinessProcess.Security");
             PatientInfo.ConnectionString = appManager.GetEMRConnectionString();
             pbLogo.Value = "logo.png";
        }
    }
}